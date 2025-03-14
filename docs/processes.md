# Processes

## Process

A process is the work someone (or something) does to accomplish an objective. A process represents a sequence of steps in the form of a graph.

## SubProcess (WIP)

A SubProcess (Embedded, Event, or AdHoc) has parts that are modeled in a child-level process, a process with its own step flows and start and end states. 

## CallActivity

A CallActivity is a reusable activity. It's behavior is like a sub process except the sub process is not embedded in the parent, instead it's defined as it's own process and can be reused in other process models.

The `called_element` property can be a string representing the id of the called process or an expression that evaluates to the id.

[source](../lib/bpmn/process.rb) | [tests](../test/bpmn/process_test.rb)