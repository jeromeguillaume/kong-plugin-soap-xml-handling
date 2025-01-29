kubectl create configmap test100-libxslt-ok --from-file ./test100-libxslt-ok.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap test100-libxslt-with-xsd-error --from-file ./test100-libxslt-with-xsd-error.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap test200-libxslt-noplugin --from-file ./test200-libxslt-noplugin.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap test400-libxslt-noplugin --from-file ./test400-libxslt-noplugin.js -o yaml --dry-run=client | kubectl apply -f - 

kubectl create configmap scen0 --from-file ./scen0.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen1 --from-file ./scen1.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen2 --from-file ./scen2.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen3 --from-file ./scen3.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen4 --from-file ./scen4.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scen2endurance --from-file ./scen2endurance.js -o yaml --dry-run=client | kubectl apply -f - 

kubectl create configmap scenhttpbin0 --from-file ./scenhttpbin0.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scenhttpbin1 --from-file ./scenhttpbin1.js -o yaml --dry-run=client | kubectl apply -f - 
kubectl create configmap scenhttpbin2 --from-file ./scenhttpbin2.js -o yaml --dry-run=client | kubectl apply -f - 
