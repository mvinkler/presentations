#!/usr/bin/env bash

. ../base-scripts/demo-magic.sh

########################
# Configure the options
########################

TYPE_SPEED=40
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "
DEMO_CMD_COLOR=$WHITE

# demo props
NAMESPACE=knative-eventing-demo
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
  ####### Validate Knative Eventing Installation
  ###pe "oc edit knativeeventing knative-eventing -n knative-eventing" # -> show in GUI
  pe "oc get pods -n knative-eventing"
  pe "kn source list-types"
  ######## Create the Service (Quarkus native REST API)
  pe "kn service create event-consumer-cli --image gcr.io/knative-releases/knative.dev/eventing-contrib/cmd/event_display --scale-window=10s"
  pe "kn service create event-consumer-web --image docker.io/n3wscott/sockeye:v0.7.0 --scale-min=1"
  ### another option for images to use:
  ###pe "kn service create event-consumer-cli --image quay.io/openshift-knative/knative-eventing-sources-event-display --scale-min=1"
  ###pe "kn service create event-consumer-web --image quay.io/openshift-knative/showcase --scale-min=1"
  pe "kn service list"
  ###pei "echo 'stern event-consumer-cli -c user-container'" -> watch output in separate console tab
  pe "ROUTE_CLI=\$(kn service describe event-consumer-cli -o url); echo \$ROUTE_CLI"
  pe "ROUTE_WEB=\$(kn service describe event-consumer-web -o url); echo \$ROUTE_WEB"
  ######## Show Source to Sink
  pe "http -v POST \$ROUTE_CLI ce-id:say-hello ce-type:my-type ce-source:myhttpie ce-specversion:1.0 'msg=Hello Knative'"
  pe "http -v POST \$ROUTE_WEB ce-id:say-hello ce-type:my-type ce-source:myhttpie ce-specversion:1.0 'msg=Hello Knative'"
  pe "kn source ping create ping-producer --data '{ \"value\": \"Ping\" }' --sink ksvc:event-consumer-cli"
  ######## Show in-memory Channels
  pe "kn channel list-types"
  pe "kn channel create my-channel"
  pe "kn source ping update ping-producer --sink channel:my-channel"
  pe "kn subscription create event-consumer-cli-sub --channel my-channel --sink ksvc:event-consumer-cli"
  ###pe "kn subscription create event-consumer-web-sub --channel my-channel --sink ksvc:event-consumer-web" #-> GUI
  ####### Cleanup
  pe "kn subscription delete event-consumer-cli-sub"
  pei "kn subscription delete event-consumer-web-sub" #probably named differently but it doesn't matter
  pei "kn channel delete my-channel"
  ####### Show Kafka Channels
  pe "oc get pods -n kafka"
  pe "oc edit knativekafka knative-kafka -n knative-eventing -o yaml"
  pe "kn channel create my-kafka-channel --type messaging.knative.dev:v1beta1:KafkaChannel"
  pe "oc get -n kafka kafkatopics"
  pe "vim ./sources/my-kafka-topic.yaml"
  pe "oc apply -f ./sources/my-kafka-topic.yaml"
  pe "oc get -n kafka kafkatopics"
  pe "vim ./sources/my-kafka-source.yaml"
  pe "oc apply -f ./sources/my-kafka-source.yaml"
  pe "kn subscription create kafkachannel-cli-sub --channel my-kafka-channel --sink ksvc:event-consumer-cli"
  ###pe "kn subscription create kafkachannel-web-sub --channel my-kafka-channel --sink ksvc:event-consumer-web" #-> GUI
  pe "oc exec -i -t my-cluster-kafka-0 -n kafka -- bin/kafka-console-producer.sh --bootstrap-server=localhost:9092 --topic=my-kafka-topic"
  ### another option of sending Kafka messages:
  ###pe "./sources/kafka-producer.sh"
  ####### Cleanup
  pe "kn subscription delete kafkachannel-cli-sub"
  pei "kn subscription delete kafkachannel-web-sub" #probably named differently but it doesn't matter
  pei "kn channel delete my-kafka-channel"
  pei "oc delete -f ./sources/my-kafka-source.yaml"
  ###### Show Brokers and Triggers
  pe "kn broker create mybroker"
  pe "kn trigger create mytrigger --broker mybroker --filter type=dev.knative.sources.ping --sink ksvc:event-consumer-cli"
  pe "kn trigger describe mytrigger"
  pe "kn source ping update ping-producer --sink broker:mybroker"
  ###pe "kn trigger create mytrigger_orders --broker mybroker --filter type=kn_order --sink ksvc:event-consumer-web" #-> show in GUI
  pe "kn broker describe mybroker"
  ###pe "oc describe service broker-ingress -n knative-eventing"
  ###### Expose broker-ingress service
  pe "oc expose service broker-ingress -n knative-eventing"
  pe "oc get routes -n knative-eventing"
  pe "ROUTE_BROKER=\$(oc get route broker-ingress -n knative-eventing -o json | jq -r '.spec.host'); echo \$ROUTE_BROKER"
  pe "http -v POST \$ROUTE_BROKER/$NAMESPACE/mybroker ce-id:custom-ping ce-type:dev.knative.sources.ping ce-source:local-httpie ce-specversion:1.0 msg=PingFromHTTP"
  pe "http -v POST \$ROUTE_BROKER/$NAMESPACE/mybroker ce-id:kn-order-1 ce-type:kn-order ce-source:local-httpie ce-specversion:1.0 orderId=1, custUsername=john.doe, orderItem=12450"
  pe ""
  exit
fi

if [ "$ACTION" == "delete" ]
then
  set -x
  oc delete -f ./sources/my-broker-route.yaml || true
  oc delete -f ./sources/my-kafka-topic.yaml || true
  oc delete route broker-ingress -n knative-eventing || true
  oc delete project $NAMESPACE
  exit
fi
