# frozen_string_literal: true

module DMN
  class Rule
    attr_accessor :id, :input_entries, :output_entries, :description

    def self.from_json(json)
      input_entries = Array.wrap(json[:input_entry]).map { |input_entry| FEEL::UnaryTests.from_json(input_entry) }
      output_entries = Array.wrap(json[:output_entry]).map { |output_entry| FEEL::LiteralExpression.from_json(output_entry) }
      Rule.new(id: json[:id], input_entries:, output_entries:, description: json[:description])
    end

    def initialize(id:, input_entries:, output_entries:, description: nil)
      @id = id
      @input_entries = input_entries
      @output_entries = output_entries
      @description = description
    end

    def evaluate(input_values = [], variables = {})
      [].tap do |test_results|
        input_entries.each_with_index do |input_entry, index|
          test_results.push input_entry.test(input_values[index], variables)
        end
      end
    end

    def as_json
      {
        id: id,
        input_entries: input_entries.map(&:as_json),
        output_entries: output_entries.map(&:as_json),
        description: description,
      }
    end

    def output_value(outputs, variables)
      HashWithIndifferentAccess.new.tap do |ov|
        output_entries.each_with_index do |output_entry, index|
          if output_entry.valid?
            val = output_entry.evaluate(variables)
            nested_hash_value(ov, outputs[index].name, val)
          end
        end
      end
    end

    private

    def nested_hash_value(hash, key_string, value)
      keys = key_string.split(".")
      current = hash
      keys[0...-1].each do |key|
        current[key] ||= {}
        current = current[key]
      end
      current[keys.last] = value
      hash
    end
  end
end
