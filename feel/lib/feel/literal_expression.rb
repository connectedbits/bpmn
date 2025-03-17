# frozen_string_literal: true

module FEEL
  class LiteralExpression
    attr_reader :id, :text

    def self.from_json(json)
      LiteralExpression.new(id: json[:id], text: json[:text])
    end

    def initialize(id: nil, text:)
      @id = id
      @text = text&.strip
    end

    def tree
      @tree ||= FEEL::Parser.parse(text)
    end

    def valid?
      return false if text.blank?
      tree.present?
    end

    def evaluate(variables = {})
      tree.eval(functions.merge(variables))
    end

    def functions
      builtins = LiteralExpression.builtin_functions
      custom = (FEEL.config.functions || {})
      ActiveSupport::HashWithIndifferentAccess.new(builtins.merge(custom))
    end

    def named_functions
      # Initialize a set to hold the qualified names
      function_names = Set.new

      # Define a lambda for the recursive function
      walk_tree = lambda do |node|
        # If the node is a qualified name, add it to the set
        if node.is_a?(FEEL::FunctionInvocation)
          function_names << node.fn_name.text_value
        end

        # Recursively walk the child nodes
        node.elements&.each do |child|
          walk_tree.call(child)
        end
      end

      # Start walking the tree from the root
      walk_tree.call(tree)

      # Return the array of functions
      function_names.to_a
    end

    def named_variables
      # Initialize a set to hold the qualified names
      qualified_names = Set.new

      # Define a lambda for the recursive function
      walk_tree = lambda do |node|
        # If the node is a qualified name, add it to the set
        if node.is_a?(FEEL::QualifiedName)
          qualified_names << node.text_value
        end

        # Recursively walk the child nodes
        node.elements&.each do |child|
          walk_tree.call(child)
        end
      end

      # Start walking the tree from the root
      walk_tree.call(tree)

      # Return the array of qualified names
      qualified_names.to_a
    end

    def self.builtin_functions
      HashWithIndifferentAccess.new({
        # Conversion functions
        "string": ->(from) {
          return if from.nil?
          from.to_s
        },
        "number": ->(from) {
          return if from.nil?
          from.include?(".") ? from.to_f : from.to_i
        },
        # Boolean functions
        "not": ->(value) {
          if value == true || value == false
            !value
          end
        },
        "is defined": ->(value) {
          return if value.nil?
          !value.nil?
        },
        "get or else": ->(value, default) {
          value.nil? ? default : value
        },
        # String functions
        "substring": ->(string, start, length) {
          return if string.nil? || start.nil?
          return "" if length.nil?
          string[start - 1, length]
        },
        "substring before": ->(string, match) {
          return if string.nil? || match.nil?
          string.split(match).first
        },
        "substring after": ->(string, match) {
          return if string.nil? || match.nil?
          string.split(match).last
        },
        "string length": ->(string) {
          return if string.nil?
          string.length
        },
        "upper case": ->(string) {
          return if string.nil?
          string.upcase
        },
        "lower case": -> (string) {
          return if string.nil?
          string.downcase
        },
        "contains": ->(string, match) {
          return if string.nil? || match.nil?
          string.include?(match)
        },
        "starts with": ->(string, match) {
          return if string.nil? || match.nil?
          string.start_with?(match)
        },
        "ends with": ->(string, match) {
          return if string.nil? || match.nil?
          string.end_with?(match)
        },
        "matches": ->(string, match) {
          return if string.nil? || match.nil?
          string.match?(match)
        },
        "replace": ->(string, match, replacement) {
          return if string.nil? || match.nil? || replacement.nil?
          string.gsub(match, replacement)
        },
        "split": ->(string, match) {
          return if string.nil? || match.nil?
          string.split(match)
        },
        "strip": -> (string) {
          return if string.nil?
          string.strip
        },
        "extract": -> (string, pattern) {
          return if string.nil? || pattern.nil?
          string.match(pattern).captures
        },
        # Numeric functions
        "decimal": ->(n, scale) {
          return if n.nil? || scale.nil?
          n.round(scale)
        },
        "floor": ->(n) {
          return if n.nil?
          n.floor
        },
        "ceiling": ->(n) {
          return if n.nil?
          n.ceil
        },
        "round up": ->(n) {
          return if n.nil?
          n.ceil
        },
        "round down": ->(n) {
          return if n.nil?
          n.floor
        },
        "abs": ->(n) {
          return if n.nil?
          n.abs
        },
        "modulo": ->(n, divisor) {
          return if n.nil? || divisor.nil?
          n % divisor
        },
        "sqrt": ->(n) {
          return if n.nil?
          Math.sqrt(n)
        },
        "log": ->(n) {
          return if n.nil?
          Math.log(n)
        },
        "exp": ->(n) {
          return if n.nil?
          Math.exp(n)
        },
        "odd": ->(n) {
          return if n.nil?
          n.odd?
        },
        "even": ->(n) {
          return if n.nil?
          n.even?
        },
        "random number": ->(n) {
          return if n.nil?
          rand(n)
        },
        # List functions
        "list contains": ->(list, match) {
          return if list.nil?
          return false if match.nil?
          list.include?(match)
        },
        "count": ->(list) {
          return if list.nil?
          return 0 if list.empty?
          list.length
        },
        "min": ->(list) {
          return if list.nil?
          list.min
        },
        "max": ->(list) {
          return if list.nil?
          list.max
        },
        "sum": ->(list) {
          return if list.nil?
          list.sum
        },
        "product": ->(list) {
          return if list.nil?
          list.inject(:*)
        },
        "mean": ->(list) {
          return if list.nil?
          list.sum / list.length
        },
        "median": ->(list) {
          return if list.nil?
          list.sort[list.length / 2]
        },
        "stddev": ->(list) {
          return if list.nil?
          mean = list.sum / list.length.to_f
          Math.sqrt(list.map { |n| (n - mean)**2 }.sum / list.length)
        },
        "mode": ->(list) {
          return if list.nil?
          list.group_by(&:itself).values.max_by(&:size).first
        },
        "all": ->(list) {
          return if list.nil?
          list.all?
        },
        "any": ->(list) {
          return if list.nil?
          list.any?
        },
        "sublist": ->(list, start, length) {
          return if list.nil? || start.nil?
          return [] if length.nil?
          list[start - 1, length]
        },
        "append": ->(list, item) {
          return if list.nil?
          list + [item]
        },
        "concatenate": ->(list1, list2) {
          return [nil, nil] if list1.nil? && list2.nil?
          return [nil] + list2 if list1.nil?
          return list1 + [nil] if list2.nil?
          Array.wrap(list1) + Array.wrap(list2)
        },
        "insert before": ->(list, position, item) {
          return if list.nil? || position.nil?
          list.insert(position - 1, item)
        },
        "remove": ->(list, position) {
          return if list.nil? || position.nil?
          list.delete_at(position - 1); list
        },
        "reverse": ->(list) {
          return if list.nil?
          list.reverse
        },
        "index of": ->(list, match) {
          return if list.nil?
          return [] if match.nil?
          list.index(match) + 1
        },
        "union": ->(list1, list2) {
          return if list1.nil? || list2.nil?
          list1 | list2
        },
        "distinct values": ->(list) {
          return if list.nil?
          list.uniq
        },
        "duplicate values": ->(list) {
          return if list.nil?
          list.select { |e| list.count(e) > 1 }.uniq
        },
        "flatten": ->(list) {
          return if list.nil?
          list.flatten
        },
        "sort": ->(list) {
          return if list.nil?
          list.sort
        },
        "string join": ->(list, separator) {
          return if list.nil?
          list.join(separator)
        },
        # Context functions
        "get value": ->(context, name) {
          return if context.nil? || name.nil?
          context[name]
        },
        "context put": ->(context, name, value) {
          return if context.nil? || name.nil?
          context[name] = value; context
        },
        "context merge": ->(context1, context2) {
          return if context1.nil? || context2.nil?
          context1.merge(context2)
        },
        "get entries": ->(context) {
          return if context.nil?
          context.entries
        },
        # Temporal functions
        "now": ->() { Time.now },
        "today": ->() { Date.today },
        "day of week": ->(date) {
          return if date.nil?
          date.wday
        },
        "day of year": ->(date) {
          return if date.nil?
          date.yday
        },
        "week of year": ->(date) {
          return if date.nil?
          date.cweek
        },
        "month of year": ->(date) {
          return if date.nil?
          date.month
        },
      })
    end

    def as_json
      {
        id: id,
        text: text,
      }
    end
  end
end
