kubectl create configmap scen0 --from-file ./scen0.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen1 --from-file ./scen1.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen3 --from-file ./scen3.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen4 --from-file ./scen4.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen5 --from-file ./scen5.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen6saxon --from-file ./scen6saxon.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen7saxon --from-file ./scen7saxon.js -o yaml --dry-run=client | kubectl apply -f - 

kubectl create configmap scenhttpbin0 --from-file ./scenhttpbin0.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scenhttpbin1 --from-file ./scenhttpbin1.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scenhttpbin2 --from-file ./scenhttpbin2.js -o yaml --dry-run=client | kubectl apply -f - 
