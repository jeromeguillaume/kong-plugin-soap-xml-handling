local libxml2ex = {}

require("kong.plugins.soap-xml-handling-lib.libxml2ex.xmlschemas")
require("kong.plugins.soap-xml-handling-lib.libxml2ex.tree")
require("kong.plugins.soap-xml-handling-lib.libxml2ex.xmlerror")
require("kong.plugins.soap-xml-handling-lib.libxml2ex.xmlwriter")
require("xmlua.libxml2.xmlerror")

local lrucache      = require("resty.lrucache")
local libxml2       = require("xmlua.libxml2")
local resty_sha256  = require("resty.sha256")
local resty_str     = require("resty.string")
local http          = require("socket.http")
local https         = require("ssl.https")
local ffi           = require("ffi")

-- load xml2 library
local loaded, xml2 = pcall(ffi.load, "xml2")
if not loaded then
  if _G.jit.os == "Windows" then
    xml2 = ffi.load("libxml2-2.dll")
  else
    xml2 = ffi.load("libxml2.so.2")
  end
end

libxml2ex.xmlSoapSleepAsync       = 0.075 -- Duration sleep (in second) of the Prefetech/Queue to download Asynchronously XSD content
libxml2ex.externalEntityCacheTTL  = 3600  -- default value for the context of the XSD Validation Prefetch
libxml2ex.externalEntityTimeout   = 1     -- default value for the context of the XSD Validation Prefetch
libxml2ex.sizeOfLRUCache          = 2000  -- Size of size of LRU Cache (1 entry per XSD URL/External Entity)
libxml2ex.queueNamePrefix         = "soap-xml-handling"
libxml2ex.stream_listen_err       = "The 'stream_listen' is enabled but it's partially incompatible for downloading External entities defined in WSDL/XSD. Recommendation => disable 'stream_listen'"

-- Initialize the defaultLoader to nil.
local defaultLoader = nil

-- Initialize the LRU cache of External Entities
local lruCacheEntities, err = lrucache.new (libxml2ex.sizeOfLRUCache)
if not lruCacheEntities then
  kong.log.err("Failed to create the LRU Cache of External Entities: " .. (err or "unknown"))
else
  kong.log.debug("Successfully created the LRU cache of External Entities, capacity=" .. lruCacheEntities:capacity())
end

-- Function to hash a given key using SHA256 and return it as a hexadecimal string
function libxml2ex.hash_key(key)
  local sha256 = resty_sha256:new()
  sha256:update(key)
  return resty_str.to_hex(sha256:final())
end

-- Function to download Synchronously entities from a given URL
local function syncDownloadEntities(url)

  local response_body, response_code, response_headers

  -- If Kong 'stream_listen' is enabled the 'kong.ctx.shared' is not properly set
  if #kong.configuration.stream_listeners > 0 then
    http.TIMEOUT  = libxml2ex.externalEntityTimeout
    https.TIMEOUT = libxml2ex.externalEntityTimeout
  else
    http.TIMEOUT  = kong.ctx.shared.xmlSoapExternalEntity.timeout
    https.TIMEOUT = kong.ctx.shared.xmlSoapExternalEntity.timeout
  end
  
  local i, _ = string.find(url, "https://")
  kong.log.debug("syncDownloadEntities url: " .. url .. " timeout (sec): " .. http.TIMEOUT)

  -- https:// request
  if i == 1 then
    response_body, response_code, response_headers = https.request(url)
  -- http:// request
  else
    response_body, response_code, response_headers = http.request(url)
  end

  if response_code ~= 200 then
    kong.log.err("Error while retrieving entities - error: ", response_code)
    return nil, response_code
  end

  if response_body == nil then
    kong.log.err("Error while retrieving entities response body is nul")
    return nil, response_code, "Error while retrieving entities response body is nul"
  end
 
  return response_body

end

-- Callback function called by 'kong.tools.queue' to download Asynchronously entities from URLs
local asyncDownloadEntities_callback = function(_, url_entries)
  
  local http = require "resty.http"
  local httpc = http.new()
  local rc = true
  local errRc = nil
  local cache_entity
  local url_cache_key

  -- Loop over all URLs
  for k, url in pairs (url_entries) do
    url_cache_key = libxml2ex.hash_key(url)  -- Calculate a cache key based on the URL using the hash_key function
    cache_entity = lruCacheEntities:get(url_cache_key)
    
    -- If the URL is found in the LRU cache of Entities
    if cache_entity then
      kong.log.debug("asyncDownloadEntities_callback - url[".. k .. "]: '" .. url .. "'")
      httpc:set_timeout(cache_entity.timeout * 1000)
      local res, err = httpc:request_uri(url, {
        method = 'GET',
        ssl_verify = false,
      })
      -- If there is no response (bad hostname for instance)
      if not res then
        rc = false
        errRc = "url '".. url .. "' err: " .. err
        cache_entity.body           = nil
        cache_entity.httpStatus     = 0
        cache_entity.timeDownloaded = ngx.time ()
      -- Else there is an Http response
      else
        cache_entity.httpStatus     = res.status
        cache_entity.timeDownloaded = ngx.time ()
        if res.status == 200 then
          cache_entity.body         = res.body
        else
          cache_entity.body         = nil
          rc = false
          errRc = "url '".. url .. "' err: " .. res.status
        end
      end
      
      -- Update the Entry in the LRU cache
      kong.log.debug("asyncDownloadEntities_callback: UPDATE cache url=" .. url .. " httpStatus=" .. cache_entity.httpStatus .. " ttl=" .. cache_entity.cacheTTL .. " timeout=" .. cache_entity.timeout)
      lruCacheEntities:set(url_cache_key, cache_entity, nil)
    else
      rc = false
      errRc = "Unable to find url '" .. url .. "' in the LRU cache of Entities"
      kong.log.debug("asyncDownloadEntities_callback - url[".. k .. "]: '" .. url .. "' " .. errRc)
    end
  end
  
  -- *** Always return true *** 
  -- Otherwise, in case of 404 error (for instance), the Queue tries the download again and again but the Queue
  -- receives the same Error (i.e. 404). Finally, the Queue goes on the next URL once the timeout (1s) is reached
  -- return rc, errRc
  return true
end

-- Custom XML entity loader function.
function libxml2ex.xmlMyExternalEntityLoader(URL, ID, ctxt)
  local ret = nil
  local entity_url = ffi.string(URL)
  local response_body
  local err = nil
  local cache_entity = nil
  local cacheTTL
  local timeout
  local async
  local xsdApiSchemaInclude
  local xsdSoapSchemaInclude
  local streamListen = false
  local url_cache_key = libxml2ex.hash_key(entity_url)  -- Calculate a cache key based on the URL using the hash_key function
  
  -- If Kong 'stream_listen' is enabled the 'kong.ctx.shared' is not properly set
  if #kong.configuration.stream_listeners > 0 then
    err = libxml2ex.stream_listen_err ..
          ". Therefore the synchronous download is forced with default values, CacheTTL=" ..libxml2ex.externalEntityCacheTTL..
          ", timeout=" .. libxml2ex.externalEntityTimeout
    kong.log.err(err)
    streamListen = true
  end
  
  -- If 'stream_listen' is not enabled
  --   AND
  -- If this function is called in the context of an end-user Request (nginx 'access' phase)
  if streamListen == false and kong.ctx.shared.xmlSoapExternalEntity then
    cacheTTL             = kong.ctx.shared.xmlSoapExternalEntity.cacheTTL
    timeout              = kong.ctx.shared.xmlSoapExternalEntity.timeout
    async                = kong.ctx.shared.xmlSoapExternalEntity.async
    xsdApiSchemaInclude  = kong.ctx.shared.xmlSoapExternalEntity.xsdApiSchemaInclude
    xsdSoapSchemaInclude = kong.ctx.shared.xmlSoapExternalEntity.xsdSoapSchemaInclude
  -- Else this function is called in the context of the nginx 'configure' phase, which is not related to an end-user Request
  --   so there is no 'kong.ctx.shared'
  else
    cacheTTL             = libxml2ex.externalEntityCacheTTL
    timeout              = libxml2ex.externalEntityTimeout
    if streamListen then
      async              = false
    else
      async              = true
    end
    xsdApiSchemaInclude  = nil
    xsdSoapSchemaInclude = nil
  end

  -- if the SOAP XSD content is included in the plugin configuration
  if xsdSoapSchemaInclude then
    for k,v in pairs(xsdSoapSchemaInclude) do
      if k == entity_url then
        response_body = v
        break
      end
    end
  end

  -- if the API XSD content is included in the plugin configuration
  if xsdApiSchemaInclude then
    for k,v in pairs(xsdApiSchemaInclude) do
      if k == entity_url then
        response_body = v
        break
      end
    end
  end

  -- If the XSD content is found in the plugin configuration
  if response_body then
    kong.log.debug("xmlMyExternalEntityLoader: found the XSD content of '" .. entity_url .. "' in the plugin configuration")
  
  -- If we download Asynchronously the External Entity
  elseif async then
    
    kong.log.debug("REQUIRE an entry in the LRU cache url=" .. entity_url)
    cache_entity = lruCacheEntities:get(url_cache_key)

    local queue_conf  =
    {
      name = libxml2ex.queueNamePrefix .. "-download-xsd", -- name of the queue (required)
      log_tag = libxml2ex.queueNamePrefix,               -- tag string to identify plugin or application area in logs
      max_batch_size = 1,                               -- maximum number of entries in one batch (default 1)
      max_coalescing_delay = 0,                          -- maximum number of seconds after first entry before a batch is sent
      max_entries = 10000,                               -- maximum number of entries on the queue (default 10000)
      max_bytes = nil,                                   -- maximum number of bytes on the queue (default nil)
      initial_retry_delay = libxml2ex.xmlSoapSleepAsync, -- initial delay when retrying a failed batch, doubled for each subsequent retry
      max_retry_time = timeout,                          -- maximum number of seconds before a failed batch is dropped
      max_retry_delay = timeout,                         -- maximum delay between send attempts, caps exponential retry
      concurrency_limit = 1                              -- specify the number of delivery timers (`-1` means no limit at all, and each entry would create an individual timer for sending)
    }
    
    -- If the Entry is not in LRU Cache of Entities
    if not cache_entity then

      err = "The entity is not in the LRU cache, so download it asynchronously"
      kong.log.debug(err)
      if lruCacheEntities:count() == lruCacheEntities:capacity () then
        -- DON'T change this 'warning' message as the LRU caching is going to evict the leastest used
        kong.log.warn("The LRU Cache of Entities reached its capacity=" .. lruCacheEntities:capacity () ..". " ..
                      "The least recently used item is going to be evicted. So increase LRU Cache for avoiding this message")          
      end
      
      -- Add a new entry in the Entities LRU cache
      kong.log.debug("ADD a new entry in LRU cache and DOWNLOAD it => url=" .. entity_url .. " ttl=" .. cacheTTL .." timeout=" .. timeout)
      cache_entity = { 
        url            = entity_url,
        timeout        = timeout,
        cacheTTL       = cacheTTL,
        body           = nil,
        httpStatus     = 0,
        timeDownloaded = 4102444800 -- 1/1/2100
      }
      lruCacheEntities:set(url_cache_key, cache_entity, nil)

      -- Download Asynchronously the new entity from a given URL
      local rcAsync, errAsync = kong.xmlSoapAsync.entityLoader.downloadExtEntitiesQueue.enqueue(
                                     queue_conf, 
                                     asyncDownloadEntities_callback, 
                                     nil, 
                                     entity_url)
      if errAsync then
        kong.log.err("downloadExtEntitiesQueue: " .. errAsync)
        err = err .. ". " .. errAsync
      end

      return nil
    
    -- Else If the Entry has to be refreshed OR
    --     (If the status is not 200 and the last download happened after 'timeout + libxml2ex.xmlSoapSleepAsync' seconds)
    elseif ngx.time () > cache_entity.timeDownloaded + cacheTTL or
           (cache_entity.httpStatus ~= 200 and 
            ngx.time () > cache_entity.timeDownloaded + timeout + libxml2ex.xmlSoapSleepAsync) then
      -- Update the timeout and TTL of 'cache_entity' regarding a potential change in the plugin configuration
      cache_entity.timeout  = timeout
      cache_entity.cacheTTL = cacheTTL 
      lruCacheEntities:set(url_cache_key, cache_entity, nil)

      kong.log.debug("UPDATE an existing entry in LRU cache and download it => url=" .. entity_url .. " ttl=" .. cacheTTL .." timeout=" .. timeout)
      -- Update Asynchronously the existing entity from a given URL
      local rcAsync, errAsync = kong.xmlSoapAsync.entityLoader.downloadExtEntitiesQueue.enqueue(
                                     queue_conf, 
                                     asyncDownloadEntities_callback, 
                                     nil, 
                                     entity_url)
      if errAsync then
        kong.log.err("xmlMyExternalEntityLoader: " .. errAsync)
        err = err .. ". " .. errAsync
      end
      
      response_body = cache_entity.body
    else
      kong.log.debug("GOT the entity in the LRU cache url=" .. entity_url .. " httpStatus=" .. cache_entity.httpStatus .. " ttl=" .. cacheTTL .." timeout=" .. timeout)
      response_body = cache_entity.body
    end
    kong.log.debug(string.format("Current LRU cache %d/%d capacity", lruCacheEntities:count(), lruCacheEntities:capacity()))

  -- Else we download Synchronously the External Entity
  else
    
    -- Retrieve the response_body from cache, with a TTL (in seconds), using the 'syncDownloadEntities' function.
    response_body, err = kong.cache:get(url_cache_key, { ttl = cacheTTL }, syncDownloadEntities, entity_url)
    if err then
      kong.log.err("Error while retrieving entities from cache, error: '", err .. "'")
      return nil
    end

  end

  -- Create a new XML string input stream using the retrieved response_body.
  ret = xml2.xmlNewStringInputStream(ctxt, response_body);
  if ret ~= ffi.NULL then
    -- No need to do a 'return ffi.gc(ret, xml2.xmlFreeInputStream)'
    -- it's probably done by 'xmlSchemaParse' in charge of calling this function and freeing 'ret'
    -- If the 'return ffi.gc(ret, xml2.xmlFreeInputStream)' is called => it raises an "[alert] 1#0: worker process **** exited on signal 11" when Nginx stops
    return ret
  end

  -- If the ret is still ffi.NULL and there is a defaultLoader, call the defaultLoader function.
  if defaultLoader ~= ffi.NULL then
    ret = defaultLoader(URL, ID, ctxt);
  end

  return ret
end

-- Function to set the custom XML entity loader as the external entity loader.
function libxml2ex.initializeExternalEntityLoader()
  -- Get the current default external entity loader.
  defaultLoader = xml2.xmlGetExternalEntityLoader();
  -- Set the custom XML entity loader as the new external entity loader.
  xml2.xmlSetExternalEntityLoader(libxml2ex.xmlMyExternalEntityLoader);
end

-- Create an XML Schemas parse context for that memory buffer expected to contain an XML Schemas file.
-- buffer:	a pointer to a char array containing the schemas
-- size:	the size of the array
-- Returns:	the parser context or NULL in case of error
function libxml2ex.xmlSchemaNewMemParserCtxt (xsd_schema)
    
    local xsd_context = xml2.xmlSchemaNewMemParserCtxt(xsd_schema, #xsd_schema)
    
    if xsd_context == ffi.NULL then
        kong.log.err("xmlSchemaNewMemParserCtxt returns null")
        return nil
    end
    
    return ffi.gc(xsd_context, xml2.xmlSchemaFreeParserCtxt)
end

-- Parse a schema definition resource and build an internal XML Schema structure which can be used to validate instances.
-- ctxt:	a schema validation context
-- Returns:	the internal XML Schema structure built from the resource or NULL in case of error
function libxml2ex.xmlSchemaParse (xsd_context, verbose) 
    kong.ctx.shared.xmlSoapErrMessage = nil

    xml2.xmlSetStructuredErrorFunc(xsd_context, kong.xmlSoapLibxmlErrorHandler)
    local xsd_schema_doc = xml2.xmlSchemaParse(xsd_context)
    
    if xsd_schema_doc == ffi.NULL then
      return nil, kong.ctx.shared.xmlSoapErrMessage
    end

    return ffi.gc(xsd_schema_doc, xml2.xmlSchemaFree), kong.ctx.shared.xmlSoapErrMessage
end
-- Avoid 'nginx: lua atpanic: Lua VM crashed, reason: bad callback' => disable the JIT
jit.off(libxml2ex.xmlSchemaParse)

-- Create an XML Schemas validation context based on the given schema.
-- schema:	a precompiled XML Schemas
-- Returns:	the validation context or NULL in case of error
function libxml2ex.xmlSchemaNewValidCtxt (xsd_schema_doc)
    local validation_context = xml2.xmlSchemaNewValidCtxt(xsd_schema_doc)
    
    if validation_context == ffi.NULL then
      kong.log.err("xmlSchemaNewValidCtxt returns null")
      return nil
    end

    return ffi.gc(validation_context, xml2.xmlSchemaFreeValidCtxt)
end

-- Parse an XML in-memory document and build a tree.
-- buffer:	a pointer to a char array
-- size:	the size of the array
-- URL:	the base URL to use for the document
-- encoding:	the document encoding, or NULL
-- options:	a combination of xmlParserOption
-- Returns:	the resulting document tree
function libxml2ex.xmlReadMemory (xml_document, base_url_document, document_encoding, options, verbose)
  kong.ctx.shared.xmlSoapErrMessage = nil
  
  xml2.xmlSetStructuredErrorFunc(nil, kong.xmlSoapLibxmlErrorHandler)
  local xml_doc = xml2.xmlReadMemory (xml_document, #xml_document, base_url_document, document_encoding, options)
  
  if xml_doc == ffi.NULL then
    -- It returns null in case of issue on SOAP/XML posted by the consumer
    -- We don't consider it as an Error
    kong.log.debug("xmlReadMemory returns null")
    return nil, kong.ctx.shared.xmlSoapErrMessage
  end

  return ffi.gc(xml_doc, xml2.xmlFreeDoc), kong.ctx.shared.xmlSoapErrMessage
end
-- Avoid 'nginx: lua atpanic: Lua VM crashed, reason: bad callback' => disable the JIT
jit.off(libxml2ex.xmlReadMemory)

-- Validate a document tree in memory.
-- ctxt:	a schema validation context
-- doc:	a parsed document tree
-- Returns:	0 if the document is schemas valid, a positive error code number otherwise and -1 in case of internal or API error.
function libxml2ex.xmlSchemaValidateDoc (validation_context, xml_doc, verbose)
  kong.ctx.shared.xmlSoapErrMessage = nil

  xml2.xmlSchemaSetValidStructuredErrors(validation_context, kong.xmlSoapLibxmlErrorHandler, nil)
  local is_valid = xml2.xmlSchemaValidateDoc (validation_context, xml_doc)

  return tonumber(is_valid), kong.ctx.shared.xmlSoapErrMessage
end
-- Avoid 'nginx: lua atpanic: Lua VM crashed, reason: bad callback' => disable the JIT
jit.off(libxml2ex.xmlSchemaValidateDoc)


-- Validate a branch of a tree, starting with the given @elem.
-- ctxt:	a schema validation context
-- elem:	an element node
-- Returns:	0 if the element and its subtree is valid, a positive error code number otherwise and -1 in case of an internal or API error.
function libxml2ex.xmlSchemaValidateOneElement(validation_context, xmlNodePtr, verbose)  
  kong.ctx.shared.xmlSoapErrMessage = nil

  xml2.xmlSchemaSetValidStructuredErrors(validation_context, kong.xmlSoapLibxmlErrorHandler, nil)
  local is_valid = xml2.xmlSchemaValidateOneElement (validation_context, xmlNodePtr)
  return tonumber(is_valid), kong.ctx.shared.xmlSoapErrMessage
end
-- Avoid 'nginx: lua atpanic: Lua VM crashed, reason: bad callback' => disable the JIT
jit.off(libxml2ex.xmlSchemaValidateOneElement)

-- Format the Error Message
function libxml2ex.formatErrMsg(xmlError)

  local errMessage = ""
  
  if xmlError.ctxt == ffi.NULL then
    kong.log.err("*** xmlError.ctxt is null***")
    return errMessage
  end

  local xmlErrorMsg = ffi.string(xmlError.message)
  -- If the last character is Return Line
  if xmlErrorMsg:sub(-1) == '\n' then
    -- Remove the Return Line
    xmlErrorMsg = xmlErrorMsg:sub(1, -2)
  end

  -- If there is a node information
  if xmlError.node ~= ffi.NULL then
    local ptrNode = ffi.cast("xmlNode *", xmlError.node)
    errMessage = "Error Node: " .. ffi.string(ptrNode.name) .. ", "
  end

  errMessage =  errMessage .. 
                "Error code: "  .. tonumber(xmlError.code) ..
                ", Line: "      .. tonumber(xmlError.line) ..
                ", Message: "   .. xmlErrorMsg

  return errMessage
end

-- Get the last parsing error registered
-- ctx:	an XML parser context
-- Returns:	NULL if no error occurred or a pointer to the error
-- **** DON'T USE THIS FUNCTION: it returns a global variable Error
function libxml2ex.xmlGetLastError ()
  local errMessage = ""
  local xmlError = xml2.xmlGetLastError()
  if xmlError ~= ffi.NULL then
    errMessage = libxml2ex.formatErrMsg(xmlError)
    xml2.xmlResetLastError()
  else
    xmlError = nil
  end
  return errMessage, xmlError
end

-- Dump an XML node, recursive behaviour,children are printed too. 
-- Note that @format = 1 provide node indenting only if xmlIndentTreeOutput = 1 or xmlKeepBlanksDefault(0) was called.
-- Since this is using xmlBuffer structures it is limited to 2GB and somehow deprecated, use xmlNodeDumpOutput() instead.
-- buf:	the XML buffer output
-- doc:	the document
-- cur:	the current node
-- level:	the imbrication level for indenting
-- format:	is formatting allowed
-- Returns:	the number of bytes written to the buffer or -1 in case of error
function libxml2ex.xmlNodeDump	(xmlDocPtr, xmlNodePtr, level, format)
  local xmlBuffer = xml2.xmlBufferCreate();
  local errDump = -1
  local xmlDump = ""

  if xmlBuffer ~= ffi.NULL then
    local rc = xml2.xmlNodeDump(xmlBuffer, xmlDocPtr, xmlNodePtr, level, format)
    -- if we succeeded dumping XML
    if tonumber(rc) ~= -1 then
      xmlDump = ffi.string(xmlBuffer.content)
      -- No error
      errDump = 0
    else
      kong.log.err("Error calling 'xmlNodeDump'")
    end
    -- free Buffer
    xml2.xmlBufferFree(xmlBuffer)
  else
    kong.log.err("Error calling 'xmlBufferCreate'")
  end
  return xmlDump, errDump
end

local function xmlOutputBufferCreate(buffer)
  return ffi.gc(xml2.xmlOutputBufferCreateBuffer(buffer, nil), xml2.xmlOutputBufferClose)
end

-- Dumps the canonized image of given XML document into memory. For details see "Canonical XML" (http://www.w3.org/TR/xml-c14n) or "Exclusive XML Canonicalization" (http://www.w3.org/TR/xml-exc-c14n)
-- doc:	the XML document for canonization
-- nodes:	the nodes set to be included in the canonized image or NULL if all document nodes should be included
-- mode:	the c14n mode (see @xmlC14NMode)
-- inclusive_ns_prefixes:	the list of inclusive namespace prefixes ended with a NULL or NULL if there is no inclusive namespaces (only for exclusive canonicalization, ignored otherwise)
-- with_comments:	include comments in the result (!=0) or not (==0)
-- doc_txt_ptr:	the memory pointer for allocated canonical XML text; the caller of this functions is responsible for calling xmlFree() to free allocated memory
-- Returns:	the number of bytes written on success or a negative value on fail
function libxml2ex.xmlC14NDocSaveTo (xmlDocPtr, xmlNodeSet)
  local errDump = -1
  local xmlDump = ""
  
  local xmlBuffer = xml2.xmlBufferCreate();
  
  if xmlBuffer ~= ffi.NULL then
    
    local output_buffer = xmlOutputBufferCreate(xmlBuffer)
    if output_buffer ~= ffi.NULL then
      local rc = xml2.xmlC14NDocSaveTo(xmlDocPtr, xmlNodeSet, 0, nil, 1, output_buffer)
      if tonumber(rc) ~= -1 then
        xmlDump = libxml2.xmlBufferGetContent(xmlBuffer)
        errDump = 0
      else
        kong.log.err("Error calling 'xmlC14NDocSaveTo'")
      end
    else
      kong.log.err("Error calling 'xmlOutputBufferCreate'")
    end
    -- free Buffer
    xml2.xmlBufferFree(xmlBuffer)
    -- The 'output_buffer' is freed by a ffi.gc configured in 'xmlOutputBufferCreate' function
  else
    kong.log.err("Error calling 'xmlBufferCreate'")
  end
  return xmlDump, errDump
end

-- Search and get the value of an attribute associated to a node This does the entity substitution. This function looks in DTD attribute declaration for #FIXED or default declaration values unless DTD use has been turned off. This function is similar to xmlGetProp except it will accept only an attribute in no namespace.
-- node:	the node
-- name:	the attribute name
-- Returns:	the attribute value or NULL if not found. It's up to the caller to free the memory with xmlFree().
function libxml2ex.xmlGetNoNsProp	(node, name)
  local attribute = xml2.xmlGetNoNsProp (node, name)

  return attribute
end

return libxml2ex