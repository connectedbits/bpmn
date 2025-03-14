# Event Definitions

Event definitions futher describe the behavior of an event.

## Error Event Definition

## Message Event Definition

## Terminate Event Definition

## Timer Event Definition

Timer events are events which are triggered by a bpmn:TimerEventDefinition. They can be used as start event, intermediate event or boundary events. Boundary events can be interrupting or not. Timers are configured using an ISO 8601 time format.

### Time Duration

Specify how long the timer should run before it's fired. These are specified as ISO 8601 durations.

Example (timer will expire in 4 days):

```xml
<bpmn:timerEventDefinition>
  <bpmn:timeDuration>P4D</bpmn:timeDuration>
</bpmn:timerEventDefinition>
```

[source](../lib/bpmn/event_definition.rb) | [tests](../test/bpmn/event_definition_test.rb)