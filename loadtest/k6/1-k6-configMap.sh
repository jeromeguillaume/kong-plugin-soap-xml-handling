kubectl create configmap scen0 --from-file ./scen0.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen1 --from-file ./scen1.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen3 --from-file ./scen3.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen4 --from-file ./scen4.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen5 --from-file ./scen5.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen6 --from-file ./scen6.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen7 --from-file ./scen7.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen8saxon --from-file ./scen8saxon.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen9saxon --from-file ./scen9saxon.js -o yaml --dry-run=client | kubectl apply -f - 

kubectl create configmap scen1endurance --from-file ./scen1endurance.js -o yaml --dry-run=client | kubectl apply -f - 

kubectl create configmap scenhttpbin0 --from-file ./scenhttpbin0.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scenhttpbin1 --from-file ./scenhttpbin1.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scenhttpbin2 --from-file ./scenhttpbin2.js -o yaml --dry-run=client | kubectl apply -f - 
