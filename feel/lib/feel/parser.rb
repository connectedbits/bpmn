# frozen_string_literal: true

module FEEL
  class Parser
    # Load the Treetop grammar from the 'feel' file, and create a new
    # instance of that parser as a class variable so we don't have to re-create
    # it every time we need to parse a string
    Treetop.load(File.expand_path(File.join(File.dirname(__FILE__), "feel.treetop")))
    @@parser = FEELParser.new

    def self.parse(expression, root: nil)
      @@parser.parse(expression, root:).tap do |ast|
        raise SyntaxError, "Invalid expression: #{expression.inspect}" unless ast
      end
    end

    def self.parse_test(expression)
      @@parser.parse(expression || "-", root: :simple_unary_tests).tap do |ast|
        raise SyntaxError, "Invalid unary test: #{expression.inspect}" unless ast
      end
    end

    def self.clean_tree(root_node)
      return if(root_node.elements.nil?)
      root_node.elements.delete_if{ |node| node.class.name == "Treetop::Runtime::SyntaxNode" }
      root_node.elements.each { |node| self.clean_tree(node) }
    end
  end
end
