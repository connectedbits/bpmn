# Events

An event is something important that happens during a business process. Events are classified by their:

* Trigger: why the event is fired (ie: reception of message, time condition, etc.)
* Behavior: throwing/catching, interupting/non-interupting
* Type: start, end, intermediate, boundary

This engine supports the following event types:

## Start Event

Represents the start of a process or subprocess.

## Intermediate Catch Event

## Intermediate Throw Event

## Boundary Event

Intermediate events are either placed between activities or attached to the boundary of an activity. The latter are called boundary events. Boundary events are entered when the attached element is started and wait for an event to occur such as a timer, message, or error. Boundary events can be interupting or non-interupting. If the host ends before an event occurs the boundary events are canceled.

## End Event

[source](../lib/bpmn/event.rb) | [tests](../test/bpmn/event_test.rb)
