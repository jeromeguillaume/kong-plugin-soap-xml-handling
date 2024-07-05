local libsaxon = {}

local ffi = require "ffi"

ffi.cdef [[
  void *createSaxonProcessorKong ();
  void *compileStylesheet(const void * saxonProcessor_void, const char *stylesheet_string);
  const char *stylesheetInvokeTemplateKong( const void *saxonProcessor_void,
                                            const void* context_void,
                                            const char* template_name,
                                            const char* param_name,
                                            const char* param_value);
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
  end
  return err
end

--------------------------
-- Create Saxon processor
--------------------------
function libsaxon.createSaxonProcessorKong()
  local saxonProcessor
  local err

  -- If the Saxon library is initialized
  if saxonClib then
    -- Initialize the Saxon Processor
    saxonProcessor = saxonClib.createSaxonProcessorKong ()
    if not saxonProcessor then
      err = "Unable to initialize the Saxon Processor"
    end
  end
  return saxonProcessor, err
end

--------------------------
-- Compile Stylesheet
--------------------------
function libsaxon.compileStylesheet(saxonProcessor, XSD)
  local err
  local context
  context = saxonClib.compileStylesheet (saxonProcessor, XSD)
  if not context then
    err = "Unable to compile Stylsheet"
  end
  return context, err
end

------------------------------
-- Stylesheet invoke template
------------------------------
function libsaxon.stylesheetInvokeTemplate (saxonProcessor, context, templateName, paramName, XMLtoTransform)
  local err
  local xml_transformed

  local xml_ptr = saxonClib.stylesheetInvokeTemplateKong (saxonProcessor, context, templateName, paramName, XMLtoTransform)
  
  if xml_ptr then
    xml_transformed = ffi.string(xml_ptr)
    saxonClib.free(ffi.cast("char*", xml_ptr))
  else
    err = "Unable to Invoke Stylesheet template"
  end
  
  return xml_transformed, err
end

return libsaxon