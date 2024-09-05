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
    err = "Unable to find or load '" .. libsaxon4kong.libName .. "' and the dependency of the Saxon shared object. Please check 'LD_LIBRARY_PATH' env variable and the presence of both libraries"
  end
  return err
end

--------------------------
-- Create Saxon processor
--------------------------
function libsaxon4kong.createSaxonProcessorKong()
  local saxonProcessor
  local err = "Unable to create the Saxon Processor"

  -- If the Saxon library is initialized
  if saxon4KongLib then
    -- Initialize the Saxon Processor
    saxonProcessor = saxon4KongLib.createSaxonProcessorKong ()
    if saxonProcessor ~= ffi.NULL then
      err = nil
    end
  end
  return saxonProcessor, err
end

-----------------------------
-- Create XSLT 3.0 processor
-----------------------------
function libsaxon4kong.createXslt30ProcessorKong(saxonProcessor)
  local xslt30Processor
  local err = "Unable to create the Saxon XSLT 3.0 Processor"
  
  if saxon4KongLib and saxonProcessor ~= ffi.NULL then
    local errorMessage_ptr = ffi.new ("char *[1]")
    -- Initialize the XSLT 3.0 Processor
    xslt30Processor = saxon4KongLib.createXslt30ProcessorKong (saxonProcessor, errorMessage_ptr)
    if errorMessage_ptr[0] ~= ffi.NULL then
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
    local errorMessage_ptr = saxon4KongLib.getErrMessage (context)
    if errorMessage_ptr ~= ffi.NULL then
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
    saxon4KongLib.deleteContext (context)
  end
end

----------------------
-- Compile Stylesheet
----------------------
function libsaxon4kong.compileStylesheet(saxonProcessor, xslt30Processor, XSLT)
  local context
  local err
  if saxon4KongLib and saxonProcessor ~= ffi.NULL and xslt30Processor ~= ffi.NULL then
    context = saxon4KongLib.compileStylesheet (saxonProcessor, xslt30Processor, XSLT)
  end
  err = "Unable to compile XSLT"
  if saxonProcessor == ffi.NULL then
    err = err .. ". The Saxon Processor is not initialized"
  elseif xslt30Processor == ffi.NULL then
    err = err .. ". The Saxon XSLT 3.0 Processor is not created"
  elseif context == ffi.NULL then
    err = "The 'context' is null"
  else
    err = libsaxon4kong.getErrorMessage(context)
  end
  return context, err
end

--------------------------------------------------------------------------
-- Transform the XML document with XSLT Stylesheet by invoking a template
--------------------------------------------------------------------------
function libsaxon4kong.stylesheetInvokeTemplate (saxonProcessor, context, templateName, paramName, XMLtoTransform)
  local err
  local xml_transformed
  local xml_ptr
  if saxon4KongLib and saxonProcessor ~= ffi.NULL and context ~= ffi.NULL then
    xml_ptr = saxon4KongLib.stylesheetInvokeTemplateKong (saxonProcessor, context, templateName, paramName, XMLtoTransform)
  end

  if xml_ptr ~= ffi.NULL then
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
  
  if saxon4KongLib and saxonProcessor ~= ffi.NULL and context ~= ffi.NULL then
    xml_ptr = saxon4KongLib.stylesheetTransformXmlKong (saxonProcessor, context, XMLtoTransform)
  end
  
  if xml_ptr ~= ffi.NULL then
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