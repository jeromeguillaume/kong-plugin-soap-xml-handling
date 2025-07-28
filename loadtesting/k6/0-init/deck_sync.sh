deck gateway sync --konnect-token $KONNECT_JEROME --konnect-addr https://eu.api.konghq.com --konnect-control-plane-name cp-gke-prod --select-tag k6 k6-kong.yaml

deck gateway sync --konnect-token $KONNECT_JEROME --konnect-addr https://eu.api.konghq.com --konnect-control-plane-name cp-gke-prod --select-tag k6-endurance-scen5 k6-kong-scen5-100routes.yaml

deck gateway sync --konnect-token $KONNECT_JEROME --konnect-addr https://eu.api.konghq.com --konnect-control-plane-name cp-gke-prod --select-tag k6-endurance-scen9 k6-kong-scen9saxon-100routes.yaml

deck gateway sync --konnect-token $KONNECT_JEROME --konnect-addr https://eu.api.konghq.com --konnect-control-plane-name cp-gke-prod --select-tag k6-endurance-scen10 k6-kong-scen10saxon-100routes.yaml
