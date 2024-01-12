# Brno JUG Presentation (June 2023): Openshift Serverless in Action (Part 2)

https://www.meetup.com/brno-java-meetup/events/297046731/

## Abstract
See [Abstract.md](Abstract.md)

## Resources

### Try Serverless yourself

- Openshift Developer Sandbox: https://developers.redhat.com

- minikube on your local machine: https://github.com/knative-sandbox/kn-plugin-quickstart

### Tutorials

- Knative Tutorial - Introduction to Knative: [bit.ly/knative-tutorial](https://bit.ly/knative-tutorial)

- developers.redhat.com - Serverless Tutorial: https://developers.redhat.com/coderland/serverless

- Quarkus Funqy extension: https://quarkus.io/guides/funqy

### Demo apps

- `kn func create -l quarkus -t cloudevents quarkus-demo`
  - [README for the template](https://github.com/knative/func/blob/main/templates/quarkus/cloudevents/README.md)

- [funqy-knative-events-quickstart](https://github.com/quarkusio/quarkus-quickstarts/tree/main/funqy-quickstarts/funqy-knative-events-quickstart)

- Funqy Knative Events Binding demo [quarkus-demo3.zip](quarkus-demo3.zip)
  - based on https://quarkus.io/guides/funqy-knative-events

### Documentation

- Knative Functions: https://knative.dev/docs/functions/
  - func.yaml reference: https://github.com/knative/func/blob/main/docs/reference/func_yaml.md

- Openshift Serverless Functions: https://docs.openshift.com/serverless/latest/functions/serverless-functions-getting-started.html

## Other Info

The demo scripts are written using https://github.com/paxtonhare/demo-magic
