# frozen_string_literal: true

module BPMN
  class Event < Step
    attr_accessor :event_definitions

    def initialize(attributes = {})
      super(attributes.except(:message_event_definition, :signal_event_definition, :error_event_definition, :terminate_event_definition, :timer_event_definition))

      @event_definitions = []

      Array.wrap(attributes[:message_event_definition]).each do |med|
        @event_definitions.push MessageEventDefinition.new(med)
      end if attributes[:message_event_definition].present?

      Array.wrap(attributes[:signal_event_definition]).each do |sed|
        @event_definitions.push SignalEventDefinition.new(sed)
      end if attributes[:signal_event_definition].present?

      Array.wrap(attributes[:error_event_definition]).each do |eed|
        @event_definitions.push ErrorEventDefinition.new(eed)
      end if attributes[:error_event_definition].present?

      Array.wrap(attributes[:terminate_event_definition]).each do |ted|
        @event_definitions.push TerminateEventDefinition.new(ted)
      end if attributes[:terminate_event_definition].present?

      Array.wrap(attributes[:timer_event_definition]).each do |ted|
        @event_definitions.push TimerEventDefinition.new(ted)
      end if attributes[:timer_event_definition].present?
    end

    def event_definition_ids
      event_definitions.map(&:id)
    end

    def is_catching?
      false
    end

    def is_throwing?
      false
    end

    def is_none?
      event_definitions.empty?
    end

    def is_conditional?
      conditional_event_definition.present?
    end

    def is_escalation?
      escalation_event_definition.present?
    end

    def is_error?
      error_event_definition.present?
    end

    def is_message?
      !message_event_definitions.empty?
    end

    def is_signal?
      !signal_event_definitions.empty?
    end

    def is_terminate?
      terminate_event_definition.present?
    end

    def is_timer?
      timer_event_definition.present?
    end

    def conditional_event_definition
      event_definitions.find { |ed| ed.is_a?(ConditionalEventDefinition) }
    end

    def escalation_event_definition
      event_definitions.find { |ed| ed.is_a?(EscalationEventDefinition) }
    end

    def error_event_definitions
      event_definitions.select { |ed| ed.is_a?(ErrorEventDefinition) }
    end

    def error_event_definition
      event_definitions.find { |ed| ed.is_a?(ErrorEventDefinition) }
    end

    def message_event_definitions
      event_definitions.select { |ed| ed.is_a?(MessageEventDefinition) }
    end

    def signal_event_definitions
      event_definitions.select { |ed| ed.is_a?(SignalEventDefinition) }
    end

    def terminate_event_definition
      event_definitions.find { |ed| ed.is_a?(TerminateEventDefinition) }
    end

    def timer_event_definition
      event_definitions.find { |ed| ed.is_a?(TimerEventDefinition) }
    end

    def execute(execution)
      event_definitions.each { |event_definition| event_definition.execute(execution) }
    end
  end

  class StartEvent < Event

    def is_catching?
      true
    end

    def execute(execution)
      super
      leave(execution)
    end
  end

  class IntermediateThrowEvent < Event

    def is_throwing?
      true
    end

    def execute(execution)
      super
      leave(execution)
    end
  end

  class IntermediateCatchEvent < Event

    def is_catching?
      true
    end

    def execute(execution)
      super
      execution.wait
    end

    def signal(execution)
      leave(execution)
    end
  end

  class BoundaryEvent < Event
    attr_accessor :attached_to_ref, :attached_to, :cancel_activity

    def initialize(attributes = {})
      super(attributes.except(:attached_to_ref, :cancel_activity))

      @attached_to_ref = attributes[:attached_to_ref]
      @cancel_activity = true
      if attributes[:cancel_activity].present?
        @cancel_activity = attributes[:cancel_activity] == "false" ? false : true
      end
    end

    def is_catching?
      true
    end

    def execute(execution)
      super
      execution.wait
    end

    def signal(execution)
      execution.attached_to.terminate if cancel_activity
      leave(execution)
    end
  end

  class EndEvent < Event

    def is_throwing?
      true
    end

    def execute(execution)
      super
      execution.end(true)
    end
  end
end
