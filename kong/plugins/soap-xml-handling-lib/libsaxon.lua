local libsaxon = {}

local ffi = require "ffi"

ffi.cdef [[
  void* compile_stylesheet(const char* stylesheet_string);
  const char* stylesheet_transform_xml(const void* context_void,
                                       const char* input_string);
  const char* stylesheet_invoke_template(const void* context_void,
                                         const char* template_name,
                                         const char* param_name,
                                         const char* param_value);
  void delete_stylesheet(const void* context_void);
  void free(void*);
]]

-- load libsaxon-hec library
local loaded, saxon = pcall(ffi.load, "libsaxon-hec-12.4.2")
if not loaded then
  if _G.jit.os == "Windows" then
    saxon = ffi.load("libsaxon-hec-12.4.2.dll")
  else
    saxon = ffi.load("libsaxon-hec-12.4.2.so")
  end
end

function libsaxon.compile_stylesheet(xslt)
  kong.log.notice("** libsaxon.compile_stylesheet")
  -- Set the custom XML entity loader as the new external entity loader.
  return saxon.compile_stylesheet(xslt)
end

return libsaxon