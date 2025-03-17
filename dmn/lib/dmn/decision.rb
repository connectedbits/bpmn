# frozen_string_literal: true

module DMN
  class Decision
    attr_reader :id, :name, :decision_table, :variable, :literal_expression, :information_requirements

    def self.from_json(json)
      information_requirements = Array.wrap(json[:information_requirement]).map { |ir| InformationRequirement.from_json(ir) } if json[:information_requirement]
      decision_table = DecisionTable.from_json(json[:decision_table]) if json[:decision_table]
      literal_expression = FEEL::LiteralExpression.from_json(json[:literal_expression]) if json[:literal_expression]
      variable = Variable.from_json(json[:variable]) if json[:variable]
      Decision.new(id: json[:id], name: json[:name], decision_table:, variable:, literal_expression:, information_requirements:)
    end

    def initialize(id:, name:, decision_table:, variable:, literal_expression:, information_requirements:)
      @id = id
      @name = name
      @decision_table = decision_table
      @variable = variable
      @literal_expression = literal_expression
      @information_requirements = information_requirements
    end

    def evaluate(variables = {})
      if literal_expression.present?
        result = literal_expression.evaluate(variables)
        variable.present? ? { variable.name => result } : result
      elsif decision_table.present?
        decision_table.evaluate(variables)
      end
    end

    def required_decision_ids
      information_requirements&.map(&:required_decision_id)
    end

    def as_json
      {
        id: id,
        name: name,
        decision_table: decision_table.as_json,
        variable: variable.as_json,
        literal_expression: literal_expression.as_json,
        information_requirements: information_requirements&.map(&:as_json),
      }
    end
  end
end
