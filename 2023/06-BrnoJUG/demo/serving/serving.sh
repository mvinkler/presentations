#!/usr/bin/env bash

. ../base-scripts/demo-magic.sh

########################
# Configure the options
########################

TYPE_SPEED=40
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "
DEMO_CMD_COLOR=$WHITE

# demo props
NAMESPACE=knative-serving-demo
ACTION=run
# hide the evidence
clear

function check_args() {
  if [[ $# -ge 1 ]]; then
    case $1 in
    run | prep |delete)
      ACTION="$1"
      if [[ $# -ge 2 ]]; then
      case $2 in
      ''|*[!0-9]*)
        echo "Not a number. Using default TYPE_SPEED=40."
        ;;
      *)
        TYPE_SPEED="$2"
        ;;
      esac
      fi
      ;;
    *)
      echo "Unrecognized action. Allowed actions: [run|prep|delete]"
      exit 1
      ;;
    esac
  fi
}

check_args "$@"

if [ "$ACTION" == "prep" ]
then

  printf "Check if oc and kn CLI is installed and if knative is installed in the cluster \n"
  pei "oc whoami && oc config current-context || oc login"
  pei "kn version"
  pei "oc version"
  pei "oc get projects | grep knative"
  exit

fi

if [ "$ACTION" == "run" ]
then
  ######## Create the namespace
  pe "oc new-project $NAMESPACE"
  ######## Validate Knative Serving Installation
  pe "oc get pods -n knative-serving"
  pe "oc get pods -n knative-serving-ingress"
  ###pe "oc edit knativeserving knative-serving -n knative-serving" #-> show in GUI
  ######## Create the Service (Quarkus native REST API)
  ###pe "echo 'watch -t -n 1 oc get pods'" #-> watch revision changes in separate console tab
  pe "kn service create quarkus-rest-api --image quay.io/mvinkler/quarkus-rest-api"
  pe "kn service describe quarkus-rest-api"
  pe "kn service list"
  pe "kn routes list"
  ######## Show Service details and dependents
  pe "oc tree ksvc quarkus-rest-api"
  ######## Create a service in offline mode
  pe "kn service create quarkus-rest-api-offline --image quay.io/mvinkler/quarkus-rest-api --target ./offline-service --scale-min=2"
  pe "tree ./offline-service"
  pe "vim ./offline-service/$NAMESPACE/ksvc/quarkus-rest-api-offline.yaml"
  pe "oc apply -f ./offline-service/$NAMESPACE/ksvc/"
  ######## Cluster local services
  pe "kn routes list"
  pe "kn service update quarkus-rest-api-offline --cluster-local"
  pe "kn routes list"
  pe "kn service delete quarkus-rest-api-offline"
  ######## Access the endpoint
  ###pe "ROUTE=\$(kn service describe quarkus-rest-api --output json | jq -r '.status.url'); echo \$ROUTE"
  pe "ROUTE=\$(kn service describe quarkus-rest-api -o url); echo \$ROUTE"
  ###pe "open \$ROUTE/swagger-ui"
  pe "http \$ROUTE/hello"
  ######## Configure Autoscaling
  pe "echo https://knative.dev/docs/serving/autoscaling/autoscaler-types/"
  ###pe "oc edit knativeserving knative-serving -n knative-serving"
  pe "kn service update quarkus-rest-api --concurrency-limit 1 --scale-window=10s"
  pe "fortio load -t 20s -c 10 -qps 40 -timeout 10s \$ROUTE/hello"
  pe "kn service update quarkus-rest-api --annotation autoscaling.knative.dev/metric=rps --scale-target 1"
  pe "fortio load -t 20s -c 10 -qps 40 -timeout 10s \$ROUTE/hello"
  pe "kn service update quarkus-rest-api --scale-max 10"
  pe "fortio load -t 10s -c 10 -qps 40 -timeout 10s \$ROUTE/hello"
  ######## Traffic Management
  ###pe "echo 'watch -t -n 1 kn revision list'" #-> watch revision changes in separate console tab
  pe "kn service update quarkus-rest-api --traffic quarkus-rest-api-00003=100"
  pe "kn service update quarkus-rest-api --image quay.io/mvinkler/quarkus-rest-api-funqy --revision-name=green-revision"
  ###pe "kn revision list"
  pe "fortio load -t 10s -c 1 -qps 5 -timeout 10s \$ROUTE/hello"
  pe "kn service update quarkus-rest-api --tag @latest=green"
  ###pe "kn revision list"
  pe "oc get routes -n knative-serving-ingress"
  pe "ROUTE_GREEN=http://green-\$(echo \$ROUTE | sed 's#^http://##'); echo \$ROUTE_GREEN"
  pe "http \$ROUTE_GREEN/hello"
  pe "http \$ROUTE/hello"
  ###pe "fortio load -t 10s -c 1 -qps 5 -timeout 10s \$ROUTE/hello"
  pe "kn service update quarkus-rest-api --traffic green=20,quarkus-rest-api-00003=80"
  ###pe "kn revision list"
  pe "fortio load -t 20s -c 1 -qps 5 -timeout 10s \$ROUTE/hello"
  pe ""
  exit
fi

if [ "$ACTION" == "delete" ]
then
  set -x
  oc delete project $NAMESPACE
  rm -rf ./offline-service/* || true

  exit
fi
