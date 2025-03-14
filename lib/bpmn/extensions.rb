# frozen_string_literal: true

module BPMN
  class Extension
    include ActiveModel::Model
  end
end

module Zeebe
  class AssignmentDefinition < BPMN::Extension
    attr_accessor :assignee, :candidate_groups, :candidate_users
  end

  class CalledElement < BPMN::Extension
    attr_accessor :process_id, :propagate_all_child_variables, :propagate_all_parent_variables

    def initialize(attributes = {})
      super(attributes.except(:propagate_all_child_variables))

      @propagate_all_parent_variables = true
      @propagate_all_parent_variables = attributes[:propagate_all_parent_variables] == "true" if attributes[:propagate_all_parent_variables].present?
      @propagate_all_child_variables = attributes[:propagate_all_child_variables] == "true"
    end
  end

  class CalledDecision < BPMN::Extension
    attr_accessor :decision_id, :result_variable
  end

  class FormDefinition < BPMN::Extension
    attr_accessor :form_key
  end

  class IoMapping < BPMN::Extension
    attr_reader :inputs, :outputs

    def initialize(attributes = {})
      super(attributes.except(:input, :output))

      @inputs = Array.wrap(attributes[:input]).map { |atts| Parameter.new(atts) } if attributes[:input].present?
      @outputs = Array.wrap(attributes[:output]).map { |atts| Parameter.new(atts) } if attributes[:output].present?
    end
  end

  class Parameter < BPMN::Extension
    attr_accessor :source, :target
  end

  class Script < BPMN::Extension
    attr_accessor :expression, :result_variable
  end

  class Subscription < BPMN::Extension
    attr_accessor :correlation_key
  end

  class TaskDefinition < BPMN::Extension
    attr_accessor :type, :retries
  end

  class TaskHeaders < BPMN::Extension
    attr_accessor :headers

    def initialize(attributes = {})
      super(attributes.except(:header))

      @headers = HashWithIndifferentAccess.new
      Array.wrap(attributes[:header]).each { |header| @headers[header[:key]] = header[:value] }
    end
  end

  class TaskSchedule < BPMN::Extension
    attr_accessor :due_date, :follow_up_date
  end
end
