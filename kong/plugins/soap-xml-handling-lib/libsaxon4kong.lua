local libsaxon4kong = {}

local ffi = require "ffi"

ffi.cdef [[
  void *createSaxonProcessorKong          ();
  void *createXslt30ProcessorKong         ( const void *saxonProcessor_void,
                                            char **errMessage);
  void *compileStylesheet                 ( const void *saxonProcessor_void, 
                                            const void *xslt30Processor_void,
                                            const char *stylesheet_string);
  const char *stylesheetInvokeTemplateKong( const void *saxonProcessor_void,
                                            const void *context_void,
                                            const char *template_name,
                                            const char *param_name,
                                            const char *param_value);
  void *addParameter                      ( const void *saxonProcessor_void,
                                            const void *context_void,
                                            const char *key,
                                            const char *value);
  const char* stylesheetTransformXmlKong  ( const void *saxonProcessor_void,
                                            const void *context_void,
                                            const char *xml_string);
  const char *getErrMessage               ( const void *context_void );
  int  getFaultCode                       ( const void *context_void );
  void deleteContext                      ( const void *context_void );
  void free(void*);
  
]]

local saxon4KongLib = nil
local splitn = require("kong.tools.string").splitn

libsaxon4kong.libName = "libsaxon-4-kong.so"
libsaxon4kong.symbolNotFound = "Internal error. A symbol is not found in the Shared Object library"

-----------------------------------
-- Load the Saxon for Kong library
-----------------------------------
function libsaxon4kong.loadSaxonforKongLibrary()
  local kongLibSaxonName = libsaxon4kong.libName
  local err
  local loaded
  loaded, saxon4KongLib = pcall(ffi.load, kongLibSaxonName)
  if not loaded then
    err = "Unable to load the shared object '" .. kongLibSaxonName .. "'"
    saxon4KongLib = nil
  end
  return err
end

-----------------------------------------------------------
-- Check if the Saxon for Kong library is correctly loaded
-----------------------------------------------------------
function libsaxon4kong.isSaxonforKongLoaded()
  local err
  if not saxon4KongLib then
    err = "Unable to load the XSLT library shared object or its dependency. Please check 'LD_LIBRARY_PATH' env variable and the presence of libraries"
  end
  return err
end

--------------------------
-- Create Saxon processor
--------------------------
function libsaxon4kong.createSaxonProcessorKong()
  local saxonProcessor = ffi.NULL
  local err = "Unable to create the Saxon Processor"
  local rc = true

  -- If the Saxon library is initialized
  if saxon4KongLib then
    if not pcall(function() return saxon4KongLib.createSaxonProcessorKong end) then
      err = "'createSaxonProcessorKong' symbol doesn't exist in " .. libsaxon4kong.libName
      -- If symbol is not found
      if err then
        kong.log.err(err)
        err = libsaxon4kong.symbolNotFound
        return nil, err
      end
    end
    -- Initialize the Saxon Processor
    rc, saxonProcessor = pcall(saxon4KongLib.createSaxonProcessorKong)
    -- If there is an error on pcall
    if not rc then
      err = "createSaxonProcessorKong: " .. saxonProcessor
      saxonProcessor = ffi.NULL
    elseif saxonProcessor ~= ffi.NULL then
      err = nil
    end
  end
  return saxonProcessor, err
end

-----------------------------
-- Create XSLT 3.0 processor
-----------------------------
function libsaxon4kong.createXslt30ProcessorKong(saxonProcessor)
  local xslt30Processor = ffi.NULL
  local err = "Unable to create the Saxon XSLT 3.0 Processor"
  local rc = true

  if saxon4KongLib and saxonProcessor ~= ffi.NULL then

    if not pcall(function() return saxon4KongLib.createXslt30ProcessorKong end) then
      err = "'createXslt30ProcessorKong' symbol doesn't exist in " .. libsaxon4kong.libName
      -- If symbol is not found
      if err then
        kong.log.err(err)
        err = libsaxon4kong.symbolNotFound
        return nil, err
      end
    end

    local errorMessage_ptr = ffi.new ("char *[1]")
    -- Initialize the XSLT 3.0 Processor
    rc, xslt30Processor = pcall(saxon4KongLib.createXslt30ProcessorKong, saxonProcessor, errorMessage_ptr)
    -- If there is an error on pcall
    if not rc then
      err = "createXslt30ProcessorKong: " .. xslt30Processor
      xslt30Processor = ffi.NULL
    elseif errorMessage_ptr[0] ~= ffi.NULL then
      err = ffi.string(ffi.cast("char *", errorMessage_ptr[0]))
    else
      err = nil
    end
    -- Free memory
    saxon4KongLib.free(ffi.cast("char*", errorMessage_ptr[0]))
  end

  return xslt30Processor, err
end

----------------------------------
-- Get Error Message from Context
----------------------------------
function libsaxon4kong.getErrorMessage(context)
  local err
  
  if saxon4KongLib then
    -- Check if symbol exists
    if not pcall(function() return saxon4KongLib.getErrMessage end) then
      err = "'getErrMessage' symbol doesn't exist in " .. libsaxon4kong.libName
      -- If symbol is not found
      if err then
        kong.log.err(err)
        err = libsaxon4kong.symbolNotFound
        return err
      end
    end

    local rc, errorMessage_ptr = pcall(saxon4KongLib.getErrMessage, context)
    -- If there is an error on pcall
    if not rc then
      err = "getErrMessage: " .. errorMessage_ptr
    elseif errorMessage_ptr ~= ffi.NULL then
      err = ffi.string(errorMessage_ptr)
      saxon4KongLib.free(ffi.cast("char*", errorMessage_ptr))
      
      -- Workaround a SaxonC issue (https://saxonica.plan.io/issues/6894) 
      --     => SaxonApiException adds multiple times the same error
      -- If the 'splitn' function is defined
      if splitn then        
        local errArray = splitn(err, '\n')
        local err2
        -- Only take the 2 first parts of Err msg (separated by a return carriage)
        for k, v in pairs(errArray) do
          -- Trim leading and trailing spaces
          v = v:match("^%s*(.-)%s*$")
          if  k == 2 and v and #v > 0 then
            err2 = err2 .. ". "  .. v
            break
          elseif k == 1 then
            err2 = v
          end
        end
        if err2 then
          err = err2
        end      
      -- Else the 'splitn' function is not defined (for fomer Kong releases)
      else
        err = string.gsub(err, ".\n", ". ")
        err = string.gsub(err, "\n", ". ")
      end
    end    
  end
  return err
end

-------------------------------
-- Get Fault Code from Context
-------------------------------
function libsaxon4kong.getFaultCode(context)
  local err
  local faultCode = 0
  local rc
  
  if saxon4KongLib then
    -- Check if symbol exists
    if not pcall(function() return saxon4KongLib.getFaultCode end) then
      err = "'getFaultCode' symbol doesn't exist in " .. libsaxon4kong.libName
      -- If symbol is not found
      if err then
        kong.log.err(err)
        err = libsaxon4kong.symbolNotFound
        return faultCode, err
      end
    end

    rc, faultCode = pcall(saxon4KongLib.getFaultCode, context)
    -- If there is an error on pcall
    if not rc then
      err = "getFaultCode: " .. faultCode
    end
  end
  return faultCode, err
end

------------------
-- Delete Context
------------------
function libsaxon4kong.deleteContext(context)
  local err

  if saxon4KongLib and context ~= ffi.NULL then

    -- Check if symbol exists
    if not pcall(function() return saxon4KongLib.deleteContext end) then
      err = "'deleteContext' symbol doesn't exist in " .. libsaxon4kong.libName
      -- If symbol is not found
      if err then
        kong.log.err(err)
        err = libsaxon4kong.symbolNotFound
        return nil, err
      end
    end

    local rc, err = pcall(saxon4KongLib.deleteContext, context)
    -- If there is an error on pcall
    if not rc then
      kong.log.err("Error on deleteContext: " .. err)
    end
  end
end

----------------------
-- Compile Stylesheet
----------------------
function libsaxon4kong.compileStylesheet(saxonProcessor, xslt30Processor, XSLT)
  local context = ffi.NULL
  local err
  local rc = true

  if saxon4KongLib and saxonProcessor ~= ffi.NULL and xslt30Processor ~= ffi.NULL then
    
    -- Check if symbol exists
    if not pcall(function() return saxon4KongLib.compileStylesheet end) then
      err = "'compileStylesheet' symbol doesn't exist in " .. libsaxon4kong.libName
      -- If symbol is not found
      if err then
        kong.log.err(err)
        err = libsaxon4kong.symbolNotFound
        return nil, err
      end
    end

    -- call the 'compileStylesheet'
    rc, context = pcall(saxon4KongLib.compileStylesheet, saxonProcessor, xslt30Processor, XSLT)
  end
  
  -- If there is an error on pcall
  if not rc then
    err = "compileStylesheet: " .. context
    context = ffi.NULL
  elseif context ~= ffi.NULL then
    err = libsaxon4kong.getErrorMessage(context)
  else
    err = "Unable to compile XSLT"
  end
  return context, err
end

--------------------------------------------------------------------------
-- Transform the XML document with XSLT Stylesheet by invoking a template
--------------------------------------------------------------------------
function libsaxon4kong.stylesheetInvokeTemplate (saxonProcessor, context, templateName, paramName, XMLtoTransform)
  local err
  local xml_transformed = nil
  local xml_ptr = ffi.NULL
  local rc = true
  
  if saxon4KongLib and saxonProcessor ~= ffi.NULL and context ~= ffi.NULL then
    
    -- Check if symbol exists
    if not pcall(function() return saxon4KongLib.stylesheetInvokeTemplateKong end) then
      err = "'stylesheetInvokeTemplateKong' symbol doesn't exist in " .. libsaxon4kong.libName
      -- If symbol is not found
      if err then
        kong.log.err(err)
        err = libsaxon4kong.symbolNotFound
        return nil, err
      end
    end

    -- call the 'stylesheetInvokeTemplateKong'
    rc, xml_ptr = pcall(saxon4KongLib.stylesheetInvokeTemplateKong, saxonProcessor, context, templateName, paramName, XMLtoTransform)
  end
  
  -- If there is an error on pcall
  if not rc then
    err = "stylesheetInvokeTemplate: " .. xml_ptr
    xml_ptr = nil
  elseif xml_ptr ~= ffi.NULL then
    xml_transformed = ffi.string(xml_ptr)
    saxon4KongLib.free(ffi.cast("char*", xml_ptr))
  elseif context ~= ffi.NULL then
    err = libsaxon4kong.getErrorMessage(context)
  else
    err = "Unable to invoke XLST transformation with a template"
  end
  
  return xml_transformed, err
end

---------------------------------------------------
-- Transform the XML document with XSLT Stylesheet
---------------------------------------------------
function libsaxon4kong.stylesheetTransformXml(saxonProcessor, context, XMLtoTransform, params)
  local err
  local xml_transformed
  local xml_ptr
  local rc = true

  if saxon4KongLib and saxonProcessor ~= ffi.NULL and context ~= ffi.NULL then
    -- Check if symbol exists
    if not pcall(function() return saxon4KongLib.addParameter end) then
      err = "'addParameter' symbol doesn't exist in " .. libsaxon4kong.libName
    end

    -- Check if symbol exists
    if not err and not pcall(function() return saxon4KongLib.stylesheetTransformXmlKong end) then
      err = "'stylesheetTransformXmlKong' symbol doesn't exist in " .. libsaxon4kong.libName
    end

    -- If some symbols are not found
    if err then
      kong.log.err(err)
      err = libsaxon4kong.symbolNotFound
      return nil, err
    end
  end

  if saxon4KongLib and saxonProcessor ~= ffi.NULL and context ~= ffi.NULL then
    -- Inject stylesheet/template parameters
    if next(params) then
      for k, v in pairs(params) do
        
        rc = pcall (saxon4KongLib.addParameter, saxonProcessor, context, k, v)
        -- If there is an error on pcall
        if not rc then
          err = "addParameter: unknown failure, check formatting"
        elseif context ~= ffi.NULL then
          err = libsaxon4kong.getErrorMessage(context)
        else
          err = "Unable to add parameter to stylesheet renderer"
        end
        
        -- If there is an error: stop the loop
        if not rc or err then
          break
        end
      end
    end    
  end

  if saxon4KongLib and saxonProcessor ~= ffi.NULL and context ~= ffi.NULL and rc and not err then
    rc, xml_ptr = pcall (saxon4KongLib.stylesheetTransformXmlKong, saxonProcessor, context, XMLtoTransform)
  end
  
  -- If there is an error on pcall
  if not rc then
    if not err then
      err = "stylesheetTransformXml: " .. (xml_ptr or 'nil')
    else
      -- there is an error on 'addParameter' call
    end
    xml_ptr = nil
  elseif xml_ptr ~= ffi.NULL then
    xml_transformed = ffi.string(xml_ptr)
    saxon4KongLib.free(ffi.cast("char*", xml_ptr))
  elseif context ~= ffi.NULL then
    err = libsaxon4kong.getErrorMessage(context)
  else
    err = "Unable to invoke XLST transformation"
  end
  
  return xml_transformed, err
end

return libsaxon4kong
