COUNTER=0
while true
do
  ((COUNTER++))
  echo "Exectuion #$COUNTER"
	KONG_IMAGE=kong/kong-gateway pongo run --lpath=$PWD/spec/common
done
