# frozen_string_literal: true

module BPMN
  class ExtensionElements
    VALID_EXTENSION_NAMESPACES = %w[zeebe]

    attr_accessor :assignment_definition, :called_element, :called_decision, :form_definition, :io_mapping, :properties, :script, :subscription, :task_definition, :task_headers, :task_schedule

    def initialize(attributes = {})
      if attributes[:properties].present?
        @properties = HashWithIndifferentAccess.new
        Array.wrap(attributes[:properties][:property]).each { |property_moddle| @properties[property_moddle[:name]] = property_moddle[:value] }
      end

      @assignment_definition = Zeebe::AssignmentDefinition.new(attributes[:assignment_definition]) if attributes[:assignment_definition].present?
      @called_element = Zeebe::CalledElement.new(attributes[:called_element]) if attributes[:called_element].present?
      @called_decision = Zeebe::CalledDecision.new(attributes[:called_decision]) if attributes[:called_decision].present?
      @form_definition = Zeebe::FormDefinition.new(attributes[:form_definition]) if attributes[:form_definition].present?
      @io_mapping = Zeebe::IoMapping.new(attributes[:io_mapping]) if attributes[:io_mapping].present?
      @script = Zeebe::Script.new(attributes[:script]) if attributes[:script].present?
      @subscription = Zeebe::Subscription.new(attributes[:subscription]) if attributes[:subscription].present?
      @task_definition = Zeebe::TaskDefinition.new(attributes[:task_definition]) if attributes[:task_definition].present?
      @task_headers = Zeebe::TaskHeaders.new(attributes[:task_headers]) if attributes[:task_headers].present?
      @task_schedule = Zeebe::TaskSchedule.new(attributes[:task_schedule]) if attributes[:task_schedule].present?
    end
  end
end
