# frozen_string_literal: true

module FEEL
  class Node < Treetop::Runtime::SyntaxNode
    #
    # Takes a context hash and returns an array of qualified names
    # { "person": { "name": { "first": "Eric", "last": "Carlson" }, "age": 60 } } => ["person", "person.name.first", "person.name.last", "person.age"]
    #
    def qualified_names_in_context(hash = {}, prefix = "", qualified_names = Set.new)
      hash.each do |key, value|
        new_prefix = prefix.empty? ? "#{key}" : "#{prefix}.#{key}"
        if value.is_a?(Hash)
          qualified_names_in_context(value, new_prefix, qualified_names)
        else
          qualified_names.add(new_prefix)
        end
      end if hash

      qualified_names.to_a
    end

    def raise_evaluation_error(missing_name, ctx = {})
      names = qualified_names_in_context(ctx)
      checker = DidYouMean::SpellChecker.new(dictionary: names)
      guess = checker.correct(missing_name)
      suffix = " Did you mean #{guess.first}?" unless guess.empty?
      raise EvaluationError.new("Identifier #{missing_name} not found.#{suffix}")
    end
  end

  #
  # 1. expression =
  # 1.a textual expression |
  # 1.b boxed expression ;
  #

  #
  # 2. textual expression =
  # 2.a function definition | for expression | if expression | quantified expression |
  # 2.b disjunction |
  # 2.c conjunction |
  # 2.d comparison |
  # 2.e arithmetic expression |
  # 2.f instance of |
  # 2.g path expression |
  # 2.h filter expression | function invocation |
  # 2.i literal | simple positive unary test | name | "(" , textual expression , ")" ;
  #

  #
  # 3. textual expressions = textual expression , { "," , textual expression } ;
  #

  #
  # 4. arithmetic expression =
  # 4.a addition | subtraction |
  # 4.b multiplication | division |
  # 4.c exponentiation |
  # 4.d arithmetic negation ;
  #

  #
  # 5. simple expression = arithmetic expression | simple value ;
  #

  #
  # 6. simple expressions = simple expression , { "," , simple expression } ;
  #
  class SimpleExpressions < Node
    def eval(context = {})
      [expr.eval(context)] + more_exprs.elements.map { |element| element.eval(context) }
    end
  end

  #
  # 7. simple positive unary test =
  # 7.a [ "<" | "<=" | ">" | ">=" ] , endpoint |
  # 7.b interval ;
  #
  class SimplePositiveUnaryTest < Node
    def eval(context = {})
      operator = head.text_value.strip
      endpoint = tail.eval(context)

      case operator
      when "<"
        ->(input) { input < endpoint }
      when "<="
        ->(input) { input <= endpoint }
      when ">"
        ->(input) { input > endpoint }
      when ">="
        ->(input) { input >= endpoint }
      else
        ->(input) { input == endpoint }
      end
    end
  end

  class UnaryOperator < Treetop::Runtime::SyntaxNode
    def eval(_context = {})
      text_value.strip
    end
  end

  #
  # 8. interval = ( open interval start | closed interval start ) , endpoint , ".." , endpoint , ( open interval end | closed interval end ) ;
  #
  class Interval < Node
    def eval(context = {})
      start = start_token.text_value
      finish = end_token.text_value
      first_val = first.eval(context)
      second_val = second.eval(context)

      case [start, finish]
      when ["(", ")"]
        ->(input) { first_val < input && input < second_val }
      when ["[", "]"]
        ->(input) { first_val <= input && input <= second_val }
      when ["(", "]"]
        ->(input) { first_val < input && input <= second_val }
      when ["[", ")"]
        ->(input) { first_val <= input && input < second_val }
      end
    end
  end

  #
  # 9. open interval start = "(" | "]" ;
  #
  class OpenIntervalStart < Node
    def eval(_context = {})
      text_value.strip
    end
  end

  #
  # 10. closed interval start = "[" ;
  #
  class ClosedIntervalStart < Node
    def eval(_context = {})
      text_value.strip
    end
  end

  #
  # 11. open interval end = ")" | "[" ;
  #
  class OpenIntervalEnd < Node
    def eval(_context = {})
      text_value.strip
    end
  end

  #
  # 12. closed interval end = "]" ;
  #
  class ClosedIntervalEnd < Node
    def eval(_context = {})
      text_value.strip
    end
  end

  #
  # 13. simple positive unary tests = simple positive unary test , { "," , simple positive unary test } ;
  #
  class SimplePositiveUnaryTests < Node
    def eval(context = {})
      tests = [test.eval(context)]
      more_tests.elements.each do |more_test|
        tests << more_test.simple_positive_unary_test.eval(context)
      end
      tests
    end
  end

  #
  # 14. simple unary tests =
  # 14.a simple positive unary tests |
  # 14.b "not", "(", simple positive unary tests, ")" |
  # 14.c "-";
  #
  class SimpleUnaryTests < Node
    def eval(context = {})
      if defined?(expr) && expr.present?
        tests = Array.wrap(expr.eval(context))
        if defined?(negate) && negate.present?
          ->(input) { !tests.any? { |test| test.call(input) } }
        else
          ->(input) { tests.any? { |test| test.call(input) } }
        end
      else
        ->(_input) { true }
      end
    end
  end

  #
  # 15. positive unary test = simple positive unary test | "null" ;
  #

  #
  # 16. positive unary tests = positive unary test , { "," , positive unary test } ;
  #

  #
  # 17. unary tests =
  # 17.a positive unary tests |
  # 17.b "not", " (", positive unary tests, ")" |
  # 17.c "-"
  #

  #
  # 18. endpoint = simple value ;
  #

  #
  # 19. simple value = qualified name | simple literal ;
  #

  #
  # 20. qualified name = name , { "." , name } ;
  #
  class QualifiedName < Node
    def eval(context = {})
      if tail.empty?
        raise_evaluation_error(head.text_value, context) if FEEL.config.strict && !context.key?(head.text_value.to_sym)
        context[head.text_value.to_sym]
      else
        tail.elements.flat_map { |element| element.name.text_value.split(".") }.inject(context[head.text_value.to_sym]) do |hash, key|
          raise_evaluation_error("#{head.text_value}#{tail.text_value}", context) if FEEL.config.strict && (hash.blank? || !hash.key?(key.to_sym))
          return nil unless hash
          hash[key.to_sym]
        end
      end
    end
  end

  #
  # 21. addition = expression , "+" , expression ;
  #
  class Addition < Node
    def eval(context = {})
      head_val = head.eval(context)
      tail_val = tail.eval(context)
      return nil if head_val.nil? || tail_val.nil?
      head.eval(context) + tail.eval(context)
    end
  end

  #
  # 22. subtraction = expression , "-" , expression ;
  #
  class Subtraction < Node
    def eval(context = {})
      head.eval(context) - tail.eval(context)
    end
  end

  #
  # 23. multiplication = expression , "\*" , expression ;
  #
  class Multiplication < Node
    def eval(context = {})
      head.eval(context) * tail.eval(context)
    end
  end

  #
  # 24. division = expression , "/" , expression ;
  #
  class Division < Node
    def eval(context = {})
      head.eval(context) / tail.eval(context)
    end
  end

  #
  # 25. exponentiation = expression, "\*\*", expression ;
  #
  class Exponentiation < Node
    def eval(context = {})
      head.eval(context) ** tail.eval(context)
    end
  end

  #
  # 26. arithmetic negation = "-" , expression ;
  #

  #
  # 27. name = name start , { name part | additional name symbols } ;
  #
  class Name < Node
    def eval(_context = {})
      #head + tail.map{|t| t[1]}.join("")
      text_value.strip
    end
  end

  #
  # 28. name start = name start char, { name part char } ;
  #

  #
  # 29. name part = name part char , { name part char } ;
  #

  #
  # 30. name start char = "?" | [A-Z] | "\_" | [a-z] | [\uC0-\uD6] | [\uD8-\uF6] | [\uF8-\u2FF] | [\u370-\u37D] | [\u37F-\u1FFF] | [\u200C-\u200D] | [\u2070-\u218F] | [\u2C00-\u2FEF] | [\u3001-\uD7FF] | [\uF900-\uFDCF] | [\uFDF0-\uFFFD] | [\u10000-\uEFFFF] ;
  #

  #
  # 31. name part char = name start char | digit | \uB7 | [\u0300-\u036F] | [\u203F-\u2040] ;
  #

  #
  # 32. additional name symbols = "." | "/" | "-" | "’" | "+" | "\*" ;
  #

  #
  # 33. literal = simple literal | "null" ;
  #

  #
  # 34. simple literal = numeric literal | string literal | boolean literal | date time literal ;
  #

  #
  # 35. string literal = '"' , { character – ('"' | vertical space) }, '"' ;
  #
  class StringLiteral < Node
    def eval(_context = {})
      text_value[1..-2]
    end
  end

  #
  # 36. Boolean literal = "true" | "false" ;
  #
  class BooleanLiteral < Node
    def eval(_context = {})
      case text_value
      when "true"
        true
      when "false"
        false
      end
    end
  end

  #
  # 37. numeric literal = [ "-" ] , ( digits , [ ".", digits ] | "." , digits ) ;
  #
  class NumericLiteral < Node
    def eval(_context = {})
      if text_value.include?(".")
        text_value.to_f
      else
        text_value.to_i
      end
    end
  end

  class NullLiteral < Node
    def eval(_context = {})
      nil
    end
  end

  #
  # 38. digit = [0-9] ;
  #

  #
  # 39. digits = digit , {digit} ;
  #

  #
  # 40. function invocation = expression , parameters ;
  #
  class FunctionInvocation < Node
    def eval(context = {})
      fn = context[fn_name.text_value.to_sym]

      unless fn
        raise_evaluation_error(fn_name.text_value, context) if FEEL.config.strict
        return nil
      end

      args = params.present? ? params.eval(context) : []

      fn.call(*args)
    end
  end

  #
  # 41. parameters = "(" , ( named parameters | positional parameters ) , ")" ;
  #

  #
  # 42. named parameters = parameter name , ":" , expression , { "," , parameter name , ":" , expression } ;
  #

  #
  # 43. parameter name = name ;
  #

  #
  # 44. positional parameters = [ expression , { "," , expression } ] ;
  #
  class PositionalParameters < Node
    def eval(context = {})
      expressions.inject([]) { |arr, exp| arr << exp.eval(context) }
    end

    def expressions
      [expression] + more_expressions.elements.map { |e| e.expression }
    end
  end

  #
  # 45. path expression = expression , "." , name ;
  #

  #
  # 46. for expression = "for" , name , "in" , expression { "," , name , "in" , expression } , "return" , expression ;
  #

  #
  # 47. if expression = "if" , expression , "then" , expression , "else" expression ;
  #
  class IfExpression < Node
    def eval(context = {})
      if condition.eval(context)
        true_case.eval(context)
      else
        false_case.eval(context)
      end
    end
  end

  #
  # 48. quantified expression = ("some" | "every") , name , "in" , expression , { name , "in" , expression } , "satisfies" , expression ;
  #
  class QuantifiedExpression < Node
    def eval(context = {})
      if quantifier.text_value == "some"
        quantified_some(context)
      else
        quantified_every(context)
      end
    end

    def quantified_some(context)
      quantified_expression = quantified_expression(context)
      quantified_expression.any? { |input| satisfies(input, context) }
    end

    def quantified_every(context)
      quantified_expression = quantified_expression(context)
      quantified_expression.all? { |input| satisfies(input, context) }
    end
  end

  #
  # 49. disjunction = expression , "or" , expression ;
  #
  class Disjunction < Node
    def eval(context = {})
      head.eval(context) || tail.eval(context)
    end
  end

  #
  # 50. conjunction = expression , "and" , expression ;
  #
  class Conjunction < Node
    def eval(context = {})
      head.eval(context) && tail.eval(context)
    end
  end

  #
  # 51. comparison =
  # 51.a expression , ( "=" | "!=" | "<" | "<=" | ">" | ">=" ) , expression |
  # 51.b expression , "between" , expression , "and" , expression |
  # 51.c expression , "in" , positive unary test ;
  # 51.d expression , "in" , " (", positive unary tests, ")" ;
  #
  class Comparison < Node
    def eval(context = {})
      case operator.text_value
      when "<" then left.eval(context) < right.eval(context)
      when "<=" then left.eval(context) <= right.eval(context)
      when ">=" then left.eval(context) >= right.eval(context)
      when ">" then left.eval(context) > right.eval(context)
      when "!=" then left.eval(context) != right.eval(context)
      when "=" then left.eval(context) == right.eval(context)
      end
    end
  end

  class ComparisonOperator < Node
    def eval(_context = {})
      text_value.strip
    end
  end

  #
  # 52. filter expression = expression , "[" , expression , "]" ;
  #
  class FilterExpression < Node
    def eval(context = {})
      filter_expression = filter_expression(context)
      filter_expression.select { |input| filter(input, context) }
    end
  end

  #
  # 53. instance of = expression , "instance" , "of" , type ;
  #
  class InstanceOf < Node
    def eval(_context = {})
      case type.text_value
      when "string"
        ->(input) { input.is_a?(String) }
      when "number"
        ->(input) { input.is_a?(Numeric) }
      when "boolean"
        ->(input) { input.is_a?(TrueClass) || input.is_a?(FalseClass) }
      when "date"
        ->(input) { input.is_a?(Date) }
      when "time"
        ->(input) { input.is_a?(Time) }
      when "date and time"
        ->(input) { input.is_a?(DateTime) }
      when "duration"
        ->(input) { input.is_a?(ActiveSupport::Duration) }
      when "years and months duration"
        ->(input) { input.is_a?(ActiveSupport::Duration) && input.parts.keys.sort == [:months, :years] }
      when "days and time duration"
        ->(input) { input.is_a?(ActiveSupport::Duration) && input.parts.keys.sort == [:days, :hours, :minutes, :seconds] }
      when "years duration"
        ->(input) { input.is_a?(ActiveSupport::Duration) && input.parts.keys.sort == [:years] }
      when "months duration"
        ->(input) { input.is_a?(ActiveSupport::Duration) && input.parts.keys.sort == [:months] }
      when "days duration"
        ->(input) { input.is_a?(ActiveSupport::Duration) && input.parts.keys.sort == [:days] }
      when "hours duration"
        ->(input) { input.is_a?(ActiveSupport::Duration) && input.parts.keys.sort == [:hours] }
      when "minutes duration"
        ->(input) { input.is_a?(ActiveSupport::Duration) && input.parts.keys.sort == [:minutes] }
      when "seconds duration"
        ->(input) { input.is_a?(ActiveSupport::Duration) && input.parts.keys.sort == [:seconds] }
      when "time duration"
        ->(input) { input.is_a?(ActiveSupport::Duration) && input.parts.keys.sort == [:hours, :minutes, :seconds] }
      when "list"
        ->(input) { input.is_a?(Array) }
      when "interval"
        ->(input) { input.is_a?(Range) }
      when "context"
        ->(input) { input.is_a?(Hash) }
      when "any"
        ->(_input) { true }
      end
    end
  end

  #
  # 54. type = qualified name ;
  #

  #
  # 55. boxed expression = list | function definition | context ;
  #

  #
  # 56. list = "[" [ expression , { "," , expression } ] , "]" ;
  #
  class List < Node
    def eval(context = {})
      return [] unless defined?(list_entries)
      if list_entries.present?
        list_entries.eval(context)
      else
        []
      end
    end
  end

  class ListEntries < Node
    def eval(context = {})
      expressions.inject([]) { |arr, exp| arr << exp.eval(context) }
    end

    def expressions
      [expression] + more_expressions.elements.map { |e| e.expression }
    end
  end

  #
  # 57. function definition = "function" , "(" , [ formal parameter { "," , formal parameter } ] , ")" , [ "external" ] , expression ;
  #
  class FunctionDefinition < Node
  end

  #
  # 58. formal parameter = parameter name ;
  #
  class FormalParameter < Node
  end

  #
  # 59. context = "{" , [context entry , { "," , context entry } ] , "}" ;
  #
  class Context < Node
    def eval(context = {})
      if entries&.present?
        entries.eval(context)
      else
        {}
      end
    end
  end

  class ContextEntryList < Node
    def eval(context = {})
      context_entries.inject({}) do |hash, entry|
        hash.merge(entry.eval(context))
      end
    end

    def context_entries
      [context_entry] + tail.elements.map { |e| e.context_entry }
    end
  end

  #
  # 60. context entry = key , ":" , expression ;
  #
  class ContextEntry < Node
    def eval(context = {})
      { context_key.eval(context) => context_value.eval(context) }
    end
  end

  #
  # 61. key = name | string literal ;
  #

  #
  # 62. date time literal = ( "date" | "time" | "date and time" | "duration" ) , "(" , string literal , ")" ;
  #
  class DateTimeLiteral < Node
    def eval(context = {})
      head_val = head.eval(context)
      return nil if head_val.nil?
      return head_val if head_val.is_a?(ActiveSupport::Duration) || head_val.is_a?(DateTime) || head_val.is_a?(Date) || head_val.is_a?(Time)

      case keyword.text_value
      when "date and time"
        DateTime.parse(head_val)
      when "date"
        Date.parse(head_val)
      when "time"
        Time.parse(head_val)
      when "duration"
        if defined?(tail) && tail.present?
          (Date.parse(tail.text_value) - Date.parse(head.text_value)).to_i.days
        else
          ActiveSupport::Duration.parse(head_val)
        end
      end
    end

    def duration_range(start_date, end_date)
      (Date.parse(end_date) - Date.parse(start_date)).to_i
    end
  end
end
