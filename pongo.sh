#------------------------------------------------------------------------------
# Rebuild the pongo image
#   required if the 'KONG_IMAGE' has been rebuilt w/o changing its tag version
#------------------------------------------------------------------------------
# pongo clean
# KONG_IMAGE=jeromeguillaume/kong-soap-xml:3.12.0.2-1.4.3-12.9 pongo build --force

#-------------------------------------------------------------------------------
# Execute the tests with the Kong standard image
#   it works only with libxml + libxslt but it doesn't work with the Saxon tests
#-------------------------------------------------------------------------------
# KONG_IMAGE=kong/kong-gateway pongo run --lpath=$PWD/spec/common

#-------------------------------------------------------------
# Execute the tests with the customized Kong image with Saxon
#-------------------------------------------------------------
# For avoiding the following error message (since v3.8) "attempt to index field 'lru' (a nil value)"
# Comment out as follows the code lines of 'clear_cache_on_file_end' in /Users/[userName]/.kong-pongo/kong-versions/3.10.0.0/kong/spec/internal/db.lua
#   then
#   --  G.kong.cache.mlcache.lru.free_queue = nil
#   --  G.kong.cache.mlcache.lru.cache_queue = nil
#   --  _G.kong.cache.mlcache.lru = nil
#   --  collectgarbage()
pongo up

# Run pongo tests by using the code of plugins stored locally
#KONG_IMAGE=jeromeguillaume/kong-soap-xml:3.12.0.2-1.4.3-12.9 pongo run --lpath=$PWD/spec/common --helper=./spec/busted-ci-helper.lua

# Run pongo tests by using the code of plugins included in the Docker image
KONG_IMAGE=jeromeguillaume/kong-soap-xml:3.12.0.2-1.4.3-12.9 pongo run --helper=./spec/busted-ci-helper.lua