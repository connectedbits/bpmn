# frozen_string_literal: true

require_relative "feel/version"

require "active_support"
require "active_support/time"
require "active_support/core_ext/hash"

require "treetop"

require "feel/configuration"
require "feel/nodes"
require "feel/parser"

require "feel/literal_expression"
require "feel/unary_tests"

module FEEL
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

  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield(config)
  end
end
