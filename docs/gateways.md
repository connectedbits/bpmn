# Gateways

Gateways are elements that control the flow of the process. For example if you want to include alternative paths depending on the output of something, you use a gateway.

Gateways have two behaviors:

* Converging, how they handle incoming flows.
* Diverging, how they handle outgoing flows.

This engine supports the following gateway types:

## Exclusive Gateway

An exclusive gateway evaluates all outgoing paths and the token flows into one of the two or more mutally exclusive paths. One of the conditions must evaluate to true. If none of the conditions evaluate to true the process will get stuck. For this reason it's always a good idea to have a default path.

## Parallel Gateway

A parallel gateway generates a token for each outgoing path and doesn't evaluate any conditions.

## Inclusive Gateway

An inclusive gateway breaks the process flow into one or more flows. It behaves like a parallel gateway execept the conditions are checked on each path and only those paths (or default) will be taken.

## Event Based Gateway

An event-based gateway is similar to an exclusive gateway because both involve one path in the flow. In the case of an event-based gateway, however, you evaluate which event has occurred, not which condition has been met. Once the event occurs, all other waiting events are canceled.

[source](../lib/bpmn/gateway.rb) | [tests](../test/bpmn/gateway_test.rb)