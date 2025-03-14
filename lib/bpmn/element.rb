# frozen_string_literal: true

module BPMN
  class Element
    include ActiveModel::Model

    attr_accessor :id, :name, :extension_elements

    def initialize(attributes = {})
      super(attributes.slice(:id, :name))

      @extension_elements = ExtensionElements.new(attributes[:extension_elements]) if attributes[:extension_elements].present?
    end

    def inspect
      "#<#{self.class.name.gsub(/BPMN::/, "")} @id=#{id.inspect} @name=#{name.inspect}>"
    end
  end

  class Message < Element
  end

  class Signal < Element
  end

  class Error < Element
  end

  class Collaboration < Element
  end

  class LaneSet < Element
  end

  class Participant < Element
    attr_accessor :process_ref, :process

    def initialize(attributes = {})
      super(attributes.except(:process_ref))
    end
  end
end
