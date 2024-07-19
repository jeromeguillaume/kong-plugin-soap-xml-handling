local libsaxon = {}

local ffi = require "ffi"

ffi.cdef [[
  void *createSaxonProcessorKong          ();
  void *createXslt30ProcessorKong         (const void *saxonProcessor_void);
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

local saxonClib = nil

----------------------------------
-- Initialize the Saxon Library
--   Load the Shared Object (.so)
----------------------------------
function libsaxon.initializeSaxon()
  local kongLibSaxonName = "libsaxon-4-kong.so"
  local err
  local loaded
  loaded, saxonClib = pcall(ffi.load, kongLibSaxonName)
  if not loaded then
    err = "Unable to load the shared object '" .. kongLibSaxonName .. "'"
    kong.log.err(err)
    saxonClib = nil
  end
  return err
end

----------------------------------
-- Get Error Message from Context
----------------------------------
function libsaxon.getErrorMessage(context)
  local errorMessage  
  if saxonClib then
    local errorMessage_ptr = saxonClib.getErrMessage (context)
    if errorMessage_ptr ~= ffi.NULL then
      errorMessage = ffi.string(errorMessage_ptr)
      saxonClib.free(ffi.cast("char*", errorMessage_ptr))
      
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
function libsaxon.deleteContext(context)
  if saxonClib and context ~= ffi.NULL then
    saxonClib.deleteContext (context)
  end
end

--------------------------
-- Create Saxon processor
--------------------------
function libsaxon.createSaxonProcessorKong()
  local saxonProcessor
  local err = "Unable to initialize the Saxon Processor"

  -- If the Saxon library is initialized
  if saxonClib then
    -- Initialize the Saxon Processor
    saxonProcessor = saxonClib.createSaxonProcessorKong ()
    if saxonProcessor ~= ffi.NULL then
      err = nil
    end
  end
  return saxonProcessor, err
end

-----------------------------
-- Create XSLT 3.0 processor
-----------------------------
function libsaxon.createXslt30ProcessorKong(saxonProcessor)
  local xslt30Processor
  local err = "Unable to initialize the XSLT 3.0 Processor"
  if saxonClib and saxonProcessor ~= ffi.NULL then
    -- Initialize the XSLT 3.0 Processor
    xslt30Processor = saxonClib.createXslt30ProcessorKong (saxonProcessor)
    if xslt30Processor ~= ffi.NULL then
      err = nil
    end
  end
  return xslt30Processor, err
end

----------------------
-- Compile Stylesheet
----------------------
function libsaxon.compileStylesheet(saxonProcessor, xslt30Processor, XSLT)
  local context
  local err
  if saxonClib and saxonProcessor ~= ffi.NULL and xslt30Processor ~= ffi.NULL then
    context = saxonClib.compileStylesheet (saxonProcessor, xslt30Processor, XSLT)
  end
  if context == ffi.NULL then
    err = "Unable to compile XSLT"
  else
    err = libsaxon.getErrorMessage(context)
  end
  return context, err
end

--------------------------------------------------------------------------
-- Transform the XML document with XSLT Stylesheet by invoking a template
--------------------------------------------------------------------------
function libsaxon.stylesheetInvokeTemplate (saxonProcessor, context, templateName, paramName, XMLtoTransform)
  local err
  local xml_transformed
  local xml_ptr
  if saxonClib and saxonProcessor ~= ffi.NULL and context ~= ffi.NULL then
    xml_ptr = saxonClib.stylesheetInvokeTemplateKong (saxonProcessor, context, templateName, paramName, XMLtoTransform)
  end

  if xml_ptr ~= ffi.NULL then
    xml_transformed = ffi.string(xml_ptr)
    saxonClib.free(ffi.cast("char*", xml_ptr))
  elseif context ~= ffi.NULL then
    err = libsaxon.getErrorMessage(context)
  else
    err = "Unable to invoke XLST transformation with a template"
  end
  
  return xml_transformed, err
end

---------------------------------------------------
-- Transform the XML document with XSLT Stylesheet
---------------------------------------------------
function libsaxon.stylesheetTransformXml(saxonProcessor, context, XMLtoTransform)
  local err
  local xml_transformed
  local xml_ptr
  
  if saxonClib and saxonProcessor ~= ffi.NULL and context ~= ffi.NULL then
    xml_ptr = saxonClib.stylesheetTransformXmlKong (saxonProcessor, context, XMLtoTransform)
  end
  
  if xml_ptr ~= ffi.NULL then
    xml_transformed = ffi.string(xml_ptr)
    saxonClib.free(ffi.cast("char*", xml_ptr))
  elseif context ~= ffi.NULL then
    err = libsaxon.getErrorMessage(context)
  else
    err = "Unable to invoke XLST transformation"
  end
  return xml_transformed, err
end

return libsaxon