#!/usr/bin/env bash

. ../base-scripts/demo-magic.sh

########################
# Configure the options
########################

TYPE_SPEED=50
DEMO_PROMPT="${GREEN}➜ \W "
DEMO_CMD_COLOR=$WHITE

# demo props
NAMESPACE=demo
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
  pe "kn func create -l quarkus -t http quarkus-demo1"
  pe "cd quarkus-demo1"
  pe "# https://github.com/knative/func/blob/main/docs/reference/func_yaml.md"
  pe "#show pom.xml, application.properties, func.yaml + change build: pack"
  pe "# another terminal: cd ~/demo/quarkus-demo1; kn func build -r quay.io/mvinkler -v"
  pe "# show func.yaml after build, show IntelliJ plugin"
  pei "# show quarkus-demo2 -> CloudEventBuilder"
  pe "kn func build -r quay.io/mvinkler -v"
  pe "#another terminal: docker volume ls; kn func run -r quay.io/mvinkler -v; mvn quarkus:dev"
#   pe "curl \"http://localhost:8080\" -X POST -H \"Content-Type: application/json\" -d '{\"message\": \"Hello there.\"}'"
#   npei ""
  pe "http POST http://localhost:8080/ message='Hello there.'"
  pe "kn func invoke --target=local --format=http --data='{\"message\":\"Hello there.\"}'"
  npei ""
  pei "# delete quarkus.funqy.export=function, re-run"
  ######## invoke
  pe "http POST http://localhost:8080/ message='Hello there.'"
  pe "http POST http://localhost:8080/function message='Hello there.'"
  pei "#explain ce-type differences in next invocations"
  pe "http POST http://localhost:8080/ Ce-Specversion:1.0 Ce-Type:MyCloudEventType Ce-Source:local-httpie Ce-Id:arbitrary-hash-or-number message='Hello there.'"
  pe "http POST http://localhost:8080/ Ce-Specversion:1.0 Ce-Type:function Ce-Source:local-httpie Ce-Id:arbitrary-hash-or-number message='Hello there.'"
  pe "#another terminal: cd ~/demo/quarkus-demo2; mvn quarkus:dev"
  pe "http POST http://localhost:8080/ Ce-Specversion:1.0 Ce-Type:function Ce-Source:local-httpie Ce-Id:arbitrary-hash-or-number message='Hello there.'"
  pe "http POST http://localhost:8080/ Ce-Specversion:1.0 Ce-Type:RANDOM_TYPE Ce-Source:local-httpie Ce-Id:arbitrary-hash-or-number message='Hello there.'"
  pe "http POST http://localhost:8080/function message='Not gonna work.'"
  ######## quarkus-demo3
  pe "#show demo3 + slides"
  pei "#another terminal: cd ~/demo/quarkus-demo3; kn func run --build=false -r quay.io/mvinkler -v"
  pe "cd ~/demo/quarkus-demo3"
  pe "kn func invoke --target=local --format=cloudevent --data=Hello --type=defaultChain"
  pe "kn func invoke --target=local --format=cloudevent --data=Hello --type=defaultChain.output"
  pe "kn func invoke --target=local --format=cloudevent --data=Hello --type=annotated"
  pe "kn func invoke --target=local --format=cloudevent --data=Hello --type=builderChain"
  pe "kn func invoke --target=local --format=cloudevent --data=Hello --type=lastChainLink --id=123"
  ####### deploy
  pe "#another terminal: kn func deploy -r quay.io/mvinkler -v"
  pei "#show IntelliJ plugin -> knative"
  pe "kn broker create mybroker"

  pei "# create trigger manually (type=defaultChain)"
#   pe "kn trigger create defaultchain --broker mybroker --filter type=defaultChain --sink ksvc:quarkus-demo3"
  pe "kn trigger create configchain --broker mybroker --filter type=defaultChain.output --sink ksvc:quarkus-demo3"
  pe "kn trigger create annotatedchain --broker mybroker --filter type=annotated --sink ksvc:quarkus-demo3"
  pe "kn trigger create builderchain --broker mybroker --filter type=builderChain --sink ksvc:quarkus-demo3"
  pe "kn trigger create lastchainlink --broker mybroker --filter type=lastChainLink --sink ksvc:quarkus-demo3"
  pe "#another terminal: stern quarkus-demo3 -c user-container"
  pe "ROUTE_BROKER=\$(oc get route broker-ingress -n knative-eventing -o json | jq -r '.spec.host'); echo \$ROUTE_BROKER"
  pe "http POST \$ROUTE_BROKER/$NAMESPACE/mybroker ce-id:42 ce-type:defaultChain ce-source:local-httpie ce-specversion:1.0 --raw='\"Hello there!\"' "
  ####### on-cluster builds
  pe "# on-cluster builds"
  pe "oc apply -f https://raw.githubusercontent.com/openshift-knative/kn-plugin-func/release-next/pkg/pipelines/resources/tekton/task/func-s2i/0.1/func-s2i.yaml"
  pe "oc apply -f https://raw.githubusercontent.com/openshift-knative/kn-plugin-func/release-next/pkg/pipelines/resources/tekton/task/func-deploy/0.1/func-deploy.yaml"
  pe "kn func delete"
  pe "kn func deploy --remote -r quay.io/mvinkler -v"
  pe "http POST \$ROUTE_BROKER/$NAMESPACE/mybroker ce-id:42 ce-type:defaultChain ce-source:local-httpie ce-specversion:1.0 --raw='\"Hello there!\"' "
  exit
fi

if [ "$ACTION" == "delete" ]
then
  set -x
#   oc delete -f ./sources/my-broker-route.yaml || true
#   oc delete -f ./sources/my-kafka-topic.yaml || true
#   oc delete route broker-ingress -n knative-eventing || true
  rm -rf ~/demo/quarkus-demo1
  rm -rf ~/demo/quarkus-demo2
  oc delete project $NAMESPACE
  exit
fi
