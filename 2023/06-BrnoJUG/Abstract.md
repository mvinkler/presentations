# Abstract

OpenShift Serverless is an abstraction layer built on top of the OpenShift Container Platform (OCP) that facilitates standardized application deployment for developers. OpenShift Serverless is built upon the Knative open-source project, offering a cohesive and consistent interface across the hybrid cloud ecosystem.

In this talk, we will explore two key components of OpenShift Serverless:

1. Knative Serving: This component allows you to deploy, run, and scale serverless applications on OCP. It incorporates essential features like automatic scaling, revision management, and traffic routing.

1. Knative Eventing: This component equips you with tools for implementing event-driven architectures in a serverless manner. Knative Eventing provides mechanisms for routing events from event-publishing services to event-consuming services.

Throughout this talk, we will use multiple runtimes for our applications, including Quarkus with its native compilation to get superfast boot and subatomic memory footprint!