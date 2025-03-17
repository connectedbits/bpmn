# frozen_string_literal: true

require_relative "dmn/version"

require "active_support"
require "active_support/time"
require "active_support/core_ext/hash"

require "feel"

require "xmlhasher"

require "dmn/configuration"

require "dmn/variable"
require "dmn/input"
require "dmn/output"
require "dmn/rule"
require "dmn/decision_table"
require "dmn/information_requirement"
require "dmn/decision"
require "dmn/definitions"


module DMN
  class SyntaxError < StandardError; end
  class EvaluationError < StandardError; end

  def self.evaluate(expression_text, variables: {})
    literal_expression = FEEL::LiteralExpression.new(text: expression_text)
    raise SyntaxError, "Expression is not valid" unless literal_expression.valid?
    literal_expression.evaluate(variables)
  end

  def self.test(input, unary_tests_text, variables: {})
    unary_tests = FEEL::UnaryTests.new(text: unary_tests_text)
    raise SyntaxError, "Unary tests are not valid" unless unary_tests.valid?
    unary_tests.test(input, variables)
  end

  def self.decide(decision_id, definitions: nil, definitions_json: nil, definitions_xml: nil, variables: {})
    if definitions_xml.present?
      definitions = DMN::Definitions.from_xml(definitions_xml)
    elsif definitions_json.present?
      definitions = DMN::Definitions.from_json(definitions_json)
    end
    definitions.evaluate(decision_id, variables: variables)
  end

  def self.definitions_from_xml(xml)
    DMN::Definitions.from_xml(xml)
  end

  def self.definitions_from_json(json)
    DMN::Definitions.from_json(json)
  end

  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield(config)
  end
end
