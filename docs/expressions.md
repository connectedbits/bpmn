# Expressions

Expressions are evaluated at execution time to make decisions. They are frequently used to conditionally take a sequence flow but can also be used to determine a value dynamically (for example which process to call from a CallActivity). This engine supports FEEL expressions or JSONLogic.

[Try Feel](https://nikku.github.io/feel-playground) | 
[Try JSONLogic](https://jsonlogic.com/play.html)

Required Expressions:
- Sequence flow on an exclusive gateway: condition
- Message catch event/receive task (not yet implemented) 
- Multi-instance activity: input collection, output element (not yet implemented)
- Input/output variable mappings: source (not yet implemented)

Optional Expressions (conditions can be used in place of a static value):
- Call activity: process id
- Timer catch event: timer definition (not yet implemented) 
- Message catch event/receive task: message name (not yet implemented) 
- Service task: job type, job retries (not yet implemented) 

Note: sequence flows allow a script instead of an expression. This should only be used when a util function is needed.

## Sequence Flow

A sequence flow represents the transition in a process from one step to another. Sequence flows can specify conditions that are checked to determine if the path should be taken.