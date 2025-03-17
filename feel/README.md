# FEEL

A light-weight FEEL expression evaluator ruby gem.

This gem implements a subset of FEEL (Friendly Enough Expression Language) as defined in the [DMN 1.3 specification](https://www.omg.org/spec/DMN/1.3/PDF) with some additional extensions.

FEEL expressions are parsed into an abstract syntax tree (AST) and then evaluated in a context. The context is a hash of variables and functions to be resolved inside the expression.

Expressions are safe, side-effect free, and deterministic. They are ideal for capturing business logic for storage in a database or embedded in DMN, BPMN, or Form documents for execution in a workflow engine.

This project was inspired by these excellent libraries:

- [feelin](https://github.com/nikku/feelin)
- [dmn-eval-js](https://github.com/mineko-io/dmn-eval-js)

## Usage

To evaluate an expression:

```ruby
FEEL.evaluate('"👋 Hello " + name', variables: { name: "World" })
# => "👋 Hello World"
```

A slightly more complex example:

```ruby
variables = {
  person: {
    name: "Eric",
    age: 59,
  }
}
FEEL.evaluate('if person.age >= 18 then "adult" else "minor"', variables:)
# => "adult"
```

Calling a built-in function:

```ruby
FEEL.evaluate('sum([1, 2, 3])')
# => 6
```

Calling a user-defined function:

```ruby
FEEL.config.functions = {
  "reverse": ->(s) { s.reverse }
}
DMN.evaluate('reverse("Hello World!")', functions:)
# => "!dlroW olleH"
```

To evaluate a unary tests:

```ruby
FEEL.test(3, '<= 10, > 50'))
# => true
```

```ruby
FEEL.test("Eric", '"Bob", "Holly", "Eric"')
# => true
```

To get a list of variables or functions used in an expression:

```ruby
LiteralExpression.new(text: 'person.first_name + " " + person.last_name').variable_names
# => ["person.age, person.last_name"]
```

```ruby
LiteralExpression.new(text: 'sum([1, 2, 3])').function_names
# => ["sum"]
```

```ruby
UnaryTests.new(text: '> speed - speed_limit').variable_names
# => ["speed, speed_limit"]
```

## Supported Features

### Data Types

- [x] Boolean (true, false)
- [x] Number (integer, decimal)
- [x] String (single and double quoted)
- [x] Date, Time, Duration (ISO 8601)
- [x] List (array)
- [x] Context (hash)

### Expressions

- [x] Literal
- [x] Path
- [x] Arithmetic
- [x] Comparison
- [x] Function Invocation
- [x] Positional Parameters
- [x] If Expression
- [ ] For Expression
- [ ] Quantified Expression
- [ ] Filter Expression
- [ ] Disjunction
- [ ] Conjuction
- [ ] Instance Of
- [ ] Function Definition

### Unary Tests

- [x] Comparison
- [x] Interval/Range (inclusive and exclusive)
- [x] Disjunction
- [x] Negation
- [ ] Expression

### Built-in Functions

- [x] Conversion: `string`, `number`
- [x] Boolean: `not`, `is defined`, `get or else`
- [x] String: `substring`, `substring before`, `substring after`, `string length`, `upper case`, `lower case`, `contains`, `starts with`, `ends with`, `matches`, `replace`, `split`, `strip`, `extract`
- [x] Numeric: `decimal`, `floor`, `ceiling`, `round`, `abs`, `modulo`, `sqrt`, `log`, `exp`, `odd`, `even`, `random number`
- [x] List: `list contains`, `count`, `min`, `max`, `sum`, `product`, `mean`, `median`, `stddev`, `mode`, `all`, `any`, `sublist`, `append`, `concatenate`, `insert before`, `remove`, `reverse`, `index of`, `union`, `distinct values`, `duplicate values`, `flatten`, `sort`, `string join`
- [x] Context: `get entries`, `get value`, `get keys`
- [x] Temporal: `now`, `today`, `day of week`, `day of year`, `month of year`, `week of year`

## Installation

Execute:

```bash
$ bundle add "feel"
```

Or install it directly:

```bash
$ gem install feel
```

### Setup

```bash
$ git clone ...
$ bin/setup
$ bin/guard
```

## Development

[Treetop Doumentation](https://cjheath.github.io/treetop/syntactic_recognition.html) is a good place to start learning about Treetop.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Developed by [Connected Bits](http://www.connectedbits.com)
