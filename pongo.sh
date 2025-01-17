#------------------------------------------------------------------------------
# Rebuild the pongo image
#   required if the 'KONG_IMAGE' has been rebuilt w/o changing its tag version
#------------------------------------------------------------------------------
# pongo clean
# KONG_IMAGE=jeromeguillaume/kong-saxon:3.8.0.0-12.5 pongo build --force

#-------------------------------------------------------------------------------
# Execute the tests with the Kong standard image
#   it works only with libxml + libxslt but it doesn't work with the Saxon tests
#-------------------------------------------------------------------------------
# KONG_IMAGE=kong/kong-gateway pongo run --lpath=$PWD/spec/common

#-------------------------------------------------------------
# Execute the tests with the customized Kong image with Saxon
#-------------------------------------------------------------
pongo up

# Run pongo tests by using the code of plugins stored locally
KONG_IMAGE=jeromeguillaume/kong-saxon:3.9.0.0-1.2.4-12.5 pongo run --lpath=$PWD/spec/common

# Run pongo tests by using the code of plugins included in the Docker image
# KONG_IMAGE=jeromeguillaume/kong-saxon:3.9.0.0-1.2.4-12.5 pongo run

#---------------------------------------------------------
# Loop tests
#---------------------------------------------------------
#COUNTER=0
#while true
#do
#  ((COUNTER++))
#  echo "Exectuion #$COUNTER"
#	KONG_IMAGE=kong/kong-gateway pongo run --lpath=$PWD/spec/common
#done
