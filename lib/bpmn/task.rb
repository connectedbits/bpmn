# frozen_string_literal: true

module BPMN
  class Task < Activity

    def is_automated?
      false
    end

    def is_manual?
      true
    end

    def execute(execution)
      execution.wait
    end

    def signal(execution)
      leave(execution)
    end

    def result_to_variables(result)
      if result_variable
        return { "#{result_variable}": result }
      else
        if result.is_a? Hash
          result
        else
          {}.tap { |h| h[id.underscore] = result }
        end
      end
    end
  end

  class UserTask < Task

    def form_key
      extension_elements&.form_definition&.form_key
    end

    def assignee
      extension_elements&.assignment_definition&.assignee
    end

    def candidate_groups
      extension_elements&.assignment_definition&.candidate_groups
    end

    def candidate_users
      extension_elements&.assignment_definition&.candidate_users
    end

    def due_date
      extension_elements&.task_schedule&.due_date
    end

    def follow_up_date
      extension_elements&.task_schedule&.follow_up_date
    end
  end

  class ServiceTask < Task
    attr_accessor :service

    def is_automated?
      true
    end

    def is_manual?
      false
    end

    def execute(execution)
      execution.wait
    end

    def task_type
      extension_elements&.task_definition&.type
    end

    def task_retries
      extension_elements&.task_definition&.retries
    end

    def headers
      extension_elements&.task_headers&.headers
    end

    def run(execution)
      if defined?(task_type)
        klass = task_type.constantize
        klass.new.call(execution.parent.variables, headers || {})
      end
    end
  end

  class ScriptTask < ServiceTask

    def script
      extension_elements&.script&.expression
    end

    def result_variable
      extension_elements&.script&.result_variable
    end

    def run(execution)
      DMN.evaluate(script.delete_prefix("="), variables: execution.parent.variables)
    end
  end

  class BusinessRuleTask < ServiceTask

    def decision_id
      extension_elements&.called_decision&.decision_id
    end

    def result_variable
      extension_elements&.called_decision&.result_variable
    end

    def run(execution)
      DMN.decide(decision_id, definitions: execution.context.dmn_definitions_by_decision_id(decision_id), variables: execution.parent.variables)
    end
  end
end
