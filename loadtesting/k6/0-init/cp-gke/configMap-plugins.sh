kubectl -n kong delete configmap soap-xml-request-handling
kubectl -n kong delete configmap soap-xml-response-handling
kubectl -n kong delete configmap soap-xml-handling-lib
kubectl -n kong delete configmap libxml2ex
kubectl -n kong delete configmap libxslt

cd /Users/jeromeg/Documents/Kong/Tips/kong-plugin-soap-xml-handling/kong/plugins
kubectl -n kong create configmap soap-xml-request-handling --from-file=./soap-xml-request-handling
kubectl -n kong create configmap soap-xml-response-handling --from-file=./soap-xml-response-handling
kubectl -n kong create configmap soap-xml-handling-lib --from-file=./soap-xml-handling-lib

cd soap-xml-handling-lib
kubectl -n kong create configmap libxml2ex --from-file=./libxml2ex
kubectl -n kong create configmap libxslt --from-file=./libxslt