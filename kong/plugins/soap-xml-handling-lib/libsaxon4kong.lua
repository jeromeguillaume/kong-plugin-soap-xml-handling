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
  const char* stylesheetTransformXmlKong  ( const void *saxonProcessor_void,
                                            const void *context_void,
                                            const char *xml_string);
  const char *getErrMessage               ( const void *context_void );
  void deleteContext                      ( const void *context_void );
  void free(void*);
]]

local saxon4KongLib = nil

libsaxon4kong.libName = "libsaxon-4-kong.so" 

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
  local errorMessage
  
  if saxon4KongLib then
    local rc, errorMessage_ptr = pcall(saxon4KongLib.getErrMessage, context)
    -- If there is an error on pcall
    if not rc then
      errorMessage = "getErrMessage: " .. errorMessage_ptr
    elseif errorMessage_ptr ~= ffi.NULL then
      errorMessage = ffi.string(errorMessage_ptr)
      saxon4KongLib.free(ffi.cast("char*", errorMessage_ptr))
      
      -- If the last character is a 'New line' (or \n) character => remove it
      if errorMessage:sub(#errorMessage, #errorMessage) == '\n' then
        errorMessage = errorMessage:sub(1, -2)  
      end
      
    end
  end
  return errorMessage
end

------------------
-- Delete Context
------------------
function libsaxon4kong.deleteContext(context)
  if saxon4KongLib and context ~= ffi.NULL then
    local rc, errMsg = pcall(saxon4KongLib.deleteContext, context)
    -- If there is an error on pcall
    if not rc then
      kong.log.err("Error on deleteContext: " .. errMsg)
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
function libsaxon4kong.stylesheetTransformXml(saxonProcessor, context, XMLtoTransform)
  local err
  local xml_transformed
  local xml_ptr
  local rc = true
  
  if saxon4KongLib and saxonProcessor ~= ffi.NULL and context ~= ffi.NULL then
    rc, xml_ptr = pcall (saxon4KongLib.stylesheetTransformXmlKong, saxonProcessor, context, XMLtoTransform)
  end
  
  -- If there is an error on pcall
  if not rc then
    err = "stylesheetTransformXml: " .. xml_ptr
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