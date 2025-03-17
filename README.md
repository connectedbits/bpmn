# WorkflowKit

WorkflowKit provides essential Ruby gems for managing business processes ([BPMN](bpmn)), rules ([DMN](dmn)), and expressions ([FEEL](feel)); keeping your apps clean, organized, and maintainable. These gems are light-weight with minimal dependencies and are based on [open standards](https://www.bpmn.org).

## FEEL

FEEL expressions are safe and side-effect free. They are ideal for capturing business logic for storage in a database or embedded in DMN or BPMN documents for execution.

Here is a simple example of evaluating a feel expression:

```ruby
FEEL.evaluate('"👋 Hello " + name', variables: { name: "World" })
# => "👋 Hello World"
```

The gem can be used to evaluate unary expressions too:

```ruby
FEEL.test(3, '<= 10, > 50'))
# => true
```

See the FEEL [README](feel/README.md) and [tests](feel/test) for more examples and documentation.

## DMN

DMN (Decision Model and Notation) is a standard for defining and executing business rules. DMN uses FEEL to evaluate expressions in the decision tables.

![Decision Table](dmn/docs/media/decision_table.png)

To evaluate a DMN decision table:

```ruby
variables = {
  violation: {
    type: "speed",
    actual_speed: 100,
    speed_limit: 65,
  }
}
result = DMN.decide('fine_decision', definitions_xml: fixture_source("fine.dmn"), variables:)
# => { "amount" => 1000, "points" => 7 })
```

See the DMN [README](dmn/README.md) and [tests](dmn/test) for more examples and documentation.

Learn more about the [DMN and FEEL Specs](https://www.omg.org/spec/DMN). Note: this gem implements a subset of the DMN 1.3 specification.

## BPMN

BPMN manages the flow of activities within a process, DMN and FEEL manages the decision logic that drives those activities.

Processes are made of a series of tasks. The engine supports the following task types:

- UserTask (manual): requires a signal to continue.
- ServiceTask (automated): instantiates a type defined in the task definition and invokes `call` on it.
- BusinessRuleTask (automated): evaluates the decision_id (expects dmn source to be included in the context).
- ScriptTask (automated): evaluates the FEEL expression in the script property.

![Example](bpmn/test/fixtures/files/hello_world.png)

To start the process, initialize with the BPMN and DMN source files, then call `start`.

```ruby
sources = [
  File.read("hello_world.bpmn"),
  File.read("choose_greeting.dmn")
]
execution = BPMN.new(sources).start
```

It's often useful to print the process state to the console.

```ruby
execution.print
```

```ruby
HelloWorld started * Flow_080794y

0 StartEvent Start: completed * out: Flow_080794y
1 UserTask IntroduceYourself: waiting * in: Flow_080794y
2 BoundaryEvent EggTimer: waiting
```

What makes the BPMN gem unique is the ability to save the state of a process until a task is complete.

```ruby
# Returns a hash of the process state.
execution_state = execution.serialize

# Now we can save the execution state in a database until a user submits a form (UserTask)
# or a background job completes (ServiceTask)

# Restores the process from the execution state.
execution = BPMN.restore(sources, execution_state:)

# Now we can continue the process by `signaling` the waiting task.
step = execution.step_by_element_id("IntroduceYourself")
step.signal(name: "Eric", language: "it", formal: false, cookie: true)
```

This continues until the process is complete.

```ruby
HelloWorld completed *

{
  "name": "Eric",
  "language": "it",
  "formal": false,
  "cookie": true,
  "choose_greeting": {
    "greeting": "Ciao"
  },
  "choose_fortune": "A foolish man listens to his heart. A wise man listens to cookies.",
  "message": "👋 Ciao Eric 🥠 A foolish man listens to his heart. A wise man listens to cookies."
}

0 StartEvent Start: completed * out: Flow_080794y
1 UserTask IntroduceYourself: completed { "name": "Eric", "language": "it", "formal": false, "cookie": true } * in: Flow_080794y * out: Flow_0t9jhga
2 BoundaryEvent EggTimer: terminated
3 ParallelGateway Split: completed * in: Flow_0t9jhga * out: Flow_0gi9kt6, Flow_0q1vtg3
4 BusinessRuleTask ChooseGreeting: completed { "choose_greeting": { "greeting": "Ciao" } } * in: Flow_0gi9kt6 * out: Flow_1652shv
5 ExclusiveGateway WantsCookie: completed * in: Flow_0q1vtg3 * out: Flow_0pb7kh6
6 ServiceTask ChooseFortune: completed { "choose_fortune": "A foolish man listens to his heart. A wise man listens to cookies." } * in: Flow_0pb7kh6 * out: Flow_1iuc1xe
7 ParallelGateway Join: completed * in: Flow_1652shv, Flow_1iuc1xe * out: Flow_0ws7a4m
8 ScriptTask GenerateMessage: completed { "message": "👋 A foolish man listens to his heart. A wise man listens to cookies." } * in: Flow_0ws7a4m * out: Flow_0gkfhvr
9 EndEvent End: completed * in: Flow_0gkfhvr
```

See the BPMN [README](bpmn/README.md) and [tests](bpmn/test) for more examples and documentation.

Learn more about the [BPMN Spec](https://www.omg.org/spec/BPMN).

## License

These gems are available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Developed by [Connected Bits](http://www.connectedbits.com)
