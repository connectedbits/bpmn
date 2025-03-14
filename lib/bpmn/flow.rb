# frozen_string_literal: true

module BPMN
  class Flow < Element
    attr_accessor :source_ref, :target_ref
    attr_accessor :source, :target

    def initialize(attributes = {})
      super(attributes.except(:source_ref, :target_ref))

      @source_ref = attributes[:source_ref]
      @target_ref = attributes[:target_ref]
      @source = nil
      @target = nil
    end

    def inspect
      parts = ["#<#{self.class.name.gsub(/BPMN::/, "")} @id=#{id.inspect}"]
      parts << "@source_ref=#{source_ref.inspect}" if source_ref
      parts << "@target_ref=#{target_ref.inspect}" if target_ref
      parts.join(" ") + ">"
    end
  end

  class Association < Flow
  end

  class SequenceFlow < Flow
    attr_accessor :condition

    def initialize(attributes = {})
      super(attributes.except(:condition))

      @condition = attributes[:condition_expression]
    end

    def evaluate(execution)
      return true unless condition
      execution.evaluate_condition(condition)
    end
  end

  class TextAnnotation < Flow
  end
end
