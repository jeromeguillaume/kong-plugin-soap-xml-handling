kubectl delete configmap soap-xml-request-handling -n dp
kubectl create configmap soap-xml-request-handling --from-file=./soap-xml-request-handling -n dp

kubectl delete configmap soap-xml-response-handling -n dp
kubectl create configmap soap-xml-response-handling --from-file=./soap-xml-response-handling -n dp

kubectl delete configmap libxslt -n dp
kubectl create configmap libxslt --from-file=./soap-xml-handling-lib/libxslt -n dp

kubectl delete configmap soap-xml-handling-lib -n dp
kubectl create configmap soap-xml-handling-lib --from-file=./soap-xml-handling-lib  -n dp

kubectl delete configmap libxml2ex -n dp
kubectl create configmap libxml2ex --from-file=./soap-xml-handling-lib/libxml2ex -n dp

kubectl delete configmap soap-xml-request-handling -n cp
kubectl create configmap soap-xml-request-handling --from-file=./soap-xml-request-handling -n cp

kubectl delete configmap soap-xml-response-handling -n cp
kubectl create configmap soap-xml-response-handling --from-file=./soap-xml-response-handling -n cp

kubectl delete configmap libxslt -n cp
kubectl create configmap libxslt --from-file=./soap-xml-handling-lib/libxslt -n cp

kubectl delete configmap soap-xml-handling-lib -n cp
kubectl create configmap soap-xml-handling-lib --from-file=./soap-xml-handling-lib  -n cp

kubectl delete configmap libxml2ex -n cp
kubectl create configmap libxml2ex --from-file=./soap-xml-handling-lib/libxml2ex -n cp
