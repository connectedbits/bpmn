# frozen_string_literal: true

module DMN
  class Input
    attr_reader :id, :label, :input_expression

    def self.from_json(json)
      input_expression = FEEL::
      LiteralExpression.from_json(json[:input_expression]) if json[:input_expression]
      Input.new(id: json[:id], label: json[:label], input_expression:)
    end

    def initialize(id:, label:, input_expression:)
      @id = id
      @label = label
      @input_expression = input_expression
    end

    def as_json
      {
        id: id,
        label: label,
        input_expression: input_expression.as_json,
      }
    end
  end
end
