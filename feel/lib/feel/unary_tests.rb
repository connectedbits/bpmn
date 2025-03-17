# frozen_string_literal: true

module FEEL
  class UnaryTests < LiteralExpression
    attr_reader :id, :text

    def self.from_json(json)
      UnaryTests.new(id: json[:id], text: json[:text])
    end

    def tree
      @tree ||= Parser.parse_test(text)
    end

    def valid?
      return true if text.nil? || text == "-"
      tree.present?
    end

    def test(input, variables = {})
      return true if text.nil? || text == "-"
      tree.eval(functions.merge(variables)).call(input)
    end
  end
end
