#KONG_IMAGE=jeromeguillaume/kong-saxon:3.7.1.1 pongo build

#KONG_IMAGE=kong/kong-gateway pongo run --lpath=$PWD/spec/common
KONG_IMAGE=jeromeguillaume/kong-saxon:3.7.1.1 pongo run --lpath=$PWD/spec/common

#COUNTER=0
#while true
#do
#  ((COUNTER++))
#  echo "Exectuion #$COUNTER"
#	KONG_IMAGE=kong/kong-gateway pongo run --lpath=$PWD/spec/common
#done
