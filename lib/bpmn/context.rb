# frozen_string_literal: true

module BPMN
  class Context
    attr_reader :sources, :processes, :decisions, :services, :executions
    attr_reader :bpmn_definitions, :dmn_definitions

    def initialize(sources = [], processes:[], decisions:[], services: {})
      @sources = Array.wrap(sources)
      @processes = Array.wrap(processes)
      @bpmn_definitions = []
      @dmn_definitions = []
      @decisions = Array.wrap(decisions)
      @services = HashWithIndifferentAccess.new((BPMN.config.services || {}).merge(services))

      @sources.each do |source|
        if source.include?("http://www.omg.org/spec/DMN/20180521/DC/")
          definitions = DMN.definitions_from_xml(source)
          @dmn_definitions << definitions
          @decisions += definitions.decisions
        else
          @processes += BPMN.processes_from_xml(source)
        end
      end

      @executions = []
    end

    def start(process_id: nil, start_event_id: nil, variables: {})
      process = process_id ? process_by_id(process_id) : default_process
      raise ExecutionError.new(process_id ? "Process #{process_id} not found." : "No default process found.") if process.blank?
      execution = Execution.start(context: self, process: process, start_event_id: start_event_id, variables: variables)
      executions << execution
      execution
    end

    def start_with_message(message_name:, variables: {})
      [].tap do |executions|
        processes.map do |process|
          process.start_events.map do |start_event|
            start_event.message_event_definitions.map do |message_event_definition|
              if message_name == message_event_definition.message_name
                Execution.start(context: self, process: process, variables: variables, start_event_id: start_event.id).tap { |execution| executions.push execution }
              end
            end
          end
        end
      end
    end

    def restore(execution_state)
      Execution.deserialize(execution_state, context: self).tap do |execution|
        executions << execution
      end
    end

    def notify_listener(*args)
      BPMN.config.listener&.call(args)
    end

    def default_process
      raise "Multiple processes defined, must identify process" if processes.size > 1
      processes.first
    end

    def process_by_id(id)
      processes.each do |process|
        return process if process.id == id
        process.sub_processes.each do |sub_process|
          return sub_process if sub_process.id == id
        end
      end
      nil
    end

    def element_by_id(id)
      processes.each do |process|
        element = process.element_by_id(id)
        return element if element
      end
      nil
    end

    def execution_by_id(id)
      executions.find { |e| e.id == id }
    end

    def execution_by_step_id(step_id)
      executions.find { |e| e.step.id == step_id }
    end

    def decision_by_id(id)
      decisions.find { |d| d.id == id }
    end

    def dmn_definitions_by_decision_id(decision_id)
      dmn_definitions.find { |definitions| definitions.decisions.find { |decision| decision.id == decision_id } }
    end

    def inspect
      parts = ["#<Context"]
      parts << "@processes=#{processes.inspect}" if processes.present?
      parts << "@decisions=#{decisions.inspect}" if decisions.present?
      parts << "@executions=#{executions.inspect}" if executions.present?
      parts.join(" ") + ">"
    end
  end
end
