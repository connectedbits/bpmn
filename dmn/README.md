# DMN

A light-weight DMN (Decision Model and Notation) business rule ruby gem.

This gem depends on the [FEEL](https://github.com/connectedbits/bpmn/tree/main/feel) gem to evaluate DMN decision tables and expressions.

## Usage

![Decision Table](docs/media/decision_table.png)

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

## Supported Features

- [x] Parse DMN XML documents
- [x] Evaluate DMN Decision Tables
- [x] Evaluate dependent DMN Decision Tables
- [x] Evaluate Expression Decisions

## Installation

Execute:

```bash
$ bundle add "dmn"
```

Or install it directly:

```bash
$ gem install dmn
```

### Setup

```bash
$ git clone ...
$ bin/setup
$ bin/guard
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Developed by [Connected Bits](http://www.connectedbits.com)
