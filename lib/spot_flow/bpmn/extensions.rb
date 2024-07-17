# frozen_string_literal: true

module SpotFlow
  module Bpmn
    class Extension
      include ActiveModel::Model
    end
  end

  module Zeebe
    class AssignmentDefinition < Bpmn::Extension
      attr_accessor :assignee, :candidate_groups, :candidate_users
    end

    class CalledElement < Bpmn::Extension
      attr_accessor :process_id, :propagate_all_child_variables
    end

    class CalledDecision < Bpmn::Extension
      attr_accessor :decision_id, :result_variable
    end

    class FormDefinition < Bpmn::Extension
      attr_accessor :form_key
    end

    class IoMapping < Bpmn::Extension
      attr_reader :inputs, :outputs

      def initialize(attributes = {})
        super(attributes.except(:input, :output))

        @inputs = Array.wrap(attributes[:input]).map { |atts| Parameter.new(atts) } if attributes[:input].present?
        @outputs = Array.wrap(attributes[:output]).map { |atts| Parameter.new(atts) } if attributes[:output].present?
      end
    end

    class Parameter < Bpmn::Extension
      attr_accessor :source, :target
    end

    class Script < Bpmn::Extension
      attr_accessor :expression, :result_variable
    end

    class Subscription < Bpmn::Extension
      attr_accessor :correlation_key
    end

    class TaskDefinition < Bpmn::Extension
      attr_accessor :type, :retries
    end

    class TaskHeaders < Bpmn::Extension
      attr_accessor :headers

      def initialize(attributes = {})
        super(attributes.except(:header))

        @headers = HashWithIndifferentAccess.new
        Array.wrap(attributes[:header]).each { |header| @headers[header[:key]] = header[:value] }
      end
    end

    class TaskSchedule < Bpmn::Extension
      attr_accessor :due_date, :follow_up_date
    end
  end
end
