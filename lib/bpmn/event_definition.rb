# frozen_string_literal: true

module BPMN
  class EventDefinition < Element
    def execute(execution)
    end
  end

  class ConditionalEventDefinition < EventDefinition
    attr_accessor :variable_name, :variable_events, :condition

    def initialize(attributes = {})
      super(attributes.except(:variable_name, :variable_events, :condition))

      @variable_name = moddle[:variable_name] # "var1"
      @variable_events = moddle[:variable_events] # "create, update"
      @condition = moddle[:condition] # var1 = 1
    end
  end

  class EscalationEventDefinition < EventDefinition
  end

  class ErrorEventDefinition < EventDefinition
    attr_accessor :error_ref, :error
    attr_accessor :error_code_variable, :error_message_variable

    def initialize(attributes = {})
      super(attributes.except(:error_ref, :error_code_variable, :error_message_variable))

      @error_ref = attributes[:error_ref]
      @error_code_variable = attributes[:error_code_variable]
      @error_message_variable = attributes[:error_message_variable]
    end

    def execute(execution)
      if execution.step.is_throwing?
        execution.throw_error(error_name)
      else
        execution.error_names.push error_name
      end
    end

    def error_id
      error&.id
    end

    def error_name
      error&.name
    end
  end

  class MessageEventDefinition < EventDefinition
    attr_accessor :message_ref, :message

    def initialize(attributes = {})
      super(attributes.except(:message_ref))

      @message_ref = attributes[:message_ref]
    end

    def execute(execution)
      if execution.step.is_throwing?
        execution.throw_message(message_name)
      else
        execution.message_names.push message_name
      end
    end

    def message_id
      message&.id
    end

    def message_name
      message&.name
    end
  end

  class SignalEventDefinition < EventDefinition
    attr_accessor :signal_ref, :signal

    def initialize(attributes = {})
      super(attributes.except(:signal_ref))

      @signal_ref = moddle[:signal_ref]
    end

    def signal_id
      signal&.id
    end

    def signal_name
      signal&.name
    end
  end

  class TerminateEventDefinition < EventDefinition

    def execute(execution)
      execution.parent&.terminate
    end
  end

  class TimerEventDefinition < EventDefinition
    attr_accessor :time_date, :time_duration_type, :time_duration, :time_cycle

    def initialize(attributes = {})
      super(attributes.except(:time_date, :time_duration, :time_cycle))

      @time_duration_type = attributes[:time_duration_type]
      @time_duration = attributes[:time_duration]
    end

    def execute(execution)
      if execution.step.is_catching?
        execution.timer_expires_at = time_due
      end
    end

    private

    def time_due
      # Return the next time the timer is due
      if time_date
        return Date.parse(time_date)
      elsif time_duration
        return Time.zone.now + ActiveSupport::Duration.parse(time_duration)
      else
        return Time.zone.now # time_cycle not yet implemented
      end
    end
  end
end
