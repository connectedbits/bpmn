# frozen_string_literal: true

module BPMN
  class Execution
    attr_accessor :id, :status, :started_at, :ended_at, :variables, :tokens_in, :tokens_out, :start_event_id, :timer_expires_at, :message_names, :error_names, :condition
    attr_accessor :step, :parent, :children, :context, :attached_to_id

    delegate :print, to: :printer

    def self.start(context:, process:, variables: {}, start_event_id: nil, parent: nil)
      Execution.new(context: context, step: process, variables: variables, start_event_id: start_event_id, parent: parent).tap do |execution|
        context.executions.push execution
        execution.start
      end
    end

    def self.deserialize(json, context:)
      if json.is_a?(String)
        attributes = JSON.parse(json)
      else
        attributes = json
      end
      Execution.from_json(attributes, context: context)
    end

    def self.from_json(attributes, context:)
      step_id = attributes.delete("step_id")
      step_type = attributes.delete("step_type")
      step = step_type == "Process" ? context.process_by_id(step_id) : context.element_by_id(step_id)
      child_attributes = attributes.delete("children")
      Execution.new(attributes.merge(step: step, context:)).tap do |execution|
        execution.children = child_attributes.map do |ca|
          Execution.from_json(ca, context:).tap { |child| child.parent = execution }
        end if child_attributes
      end
    end

    def gen_uid
      rand(36**8).to_s(36)
    end

    def initialize(attributes={})
      attributes.each do |k, v|
        send("#{k}=", v)
      end
      @id ||= gen_uid
      @status ||= "activated"
      @variables = @variables&.with_indifferent_access || {}.with_indifferent_access
      @tokens_in ||= []
      @tokens_out ||= []
      @message_names ||= []
      @error_names ||= []
      @children ||= []
    end

    def started?
      started_at.present?
    end

    def ended?
      ended_at.present?
    end

    def activated?
      status == "activated"
    end

    def waiting?
      status == "waiting"
    end

    def completed?
      status == "completed"
    end

    def terminated?
      status == "terminated"
    end

    def execute_steps(steps)
      steps.each { |step| execute_step(step) }
    end

    def execute_step(step, attached_to: nil, sequence_flow: nil)
      child_execution = children.find { |child| child.step.id == step.id }
      child_execution = Execution.new(context: context, step: step, parent: self, attached_to_id: attached_to&.id).tap { |ce| children.push ce } unless child_execution
      child_execution.tokens_in += [sequence_flow.id] if sequence_flow
      child_execution.start
    end

    def invoke_listeners(type, sequence_flow = nil)
      context.listeners.each { |listener| listener[type].call(self, sequence_flow) if listener[type] }
    end

    def start
      @status = "started"
      @started_at = Time.zone.now
      map_input_variables if step&.input_mappings&.present?
      context.notify_listener(:execution_started, execution: self)
      step.attachments.each { |attachment| parent.execute_step(attachment, attached_to: self) } if step.is_a?(BPMN::Activity)
      continue
    end

    def continue
      step.execute(self)
    end

    def wait
      @status = "waiting"
      context.notify_listener(:execution_waited, execution: self)
    end

    def terminate
      @status = "terminated"
      self.end
    end

    def end(notify_parent = false)
      @status = "completed" unless status == "terminated"
      map_output_variables if step&.output_mappings&.present?
      parent.variables.merge!(variables) if parent && variables.present?
      @ended_at = Time.zone.now
      context.notify_listener(:execution_ended, execution: self)
      children.each { |child| child.terminate unless child.ended? }
      parent.children.each { |child| child.terminate if child.attached_to == self && child.waiting? } if parent
      parent.has_ended(self) if parent && notify_parent
    end

    def take_all(sequence_flows)
      sequence_flows.each { |sequence_flow| take(sequence_flow) }
    end

    def take(sequence_flow)
      to_step = sequence_flow.target
      tokens_out.push sequence_flow.id
      tokens_out.uniq!
      context.notify_listener(:flow_taken, execution: self, sequence_flow: sequence_flow)
      parent.execute_step(to_step, sequence_flow: sequence_flow)
    end

    def signal(result = nil)
      @variables.merge!(result_to_variables(result)) if result.present?
      raise ExecutionError.new("Cannot signal a step execution that has ended.") if ended?
      step.signal(self)
    end

    def throw_message(message_name, variables: {})
      waiting_children.each do |child|
        step = child.step
        if step.is_a?(BPMN::Event) && step.message_event_definitions.any? { |message_event_definition| message_event_definition.message_name == message_name }
          child.signal(variables)
          break
        end
      end
      context.notify_listener(:message_thrown, execution: self, message_name: message_name)
    end

    def throw_error(error_name, variables: {})
      waiting_children.each do |child|
        step = child.step
        if step.is_a?(BPMN::Event) && step.error_event_definitions.any? { |error_event_definition| error_event_definition.error_name == error_name }
          child.signal(variables)
          break
        end
      end
      context.notify_listener(:error_thrown, execution: self, error_name: error_name)
    end

    def check_expired_timers
      waiting_children.each { |child| child.signal if child.timer_expires_at.present? && Time.zone.now > child.timer_expires_at }
    end

    def evaluate_condition(condition)
      evaluate_expression(condition.delete_prefix("=")) == true
    end

    def evaluate_expression(expression, variables: parent&.variables || {}.with_indifferent_access)
      DMN.evaluate(expression.delete_prefix("="), variables:)
    end

    def run_automated_tasks
      waiting_automated_tasks.each { |child| child.run }
    end

    def run
      return unless step.is_automated?

      result = step.run(self)

      if result.present?
        signal(result)
      else
        wait
      end
    end

    def call(process)
      execute_step(process, attached_to: self)
    end

    #
    # Called by the child step executors when they have ended
    #
    def has_ended(_child)
      step.leave(self) if step.is_a?(BPMN::SubProcess) || step.is_a?(BPMN::CallActivity)
      self.end(true)
    end

    def attached_to
      @attached_to ||= parent.children.find { |child| child.id == attached_to_id } if parent
    end

    def child_by_step_id(id)
      children.find { |child| child.step.id == id }
    end

    def waiting_children
      children.filter { |child| child.waiting? }
    end

    def waiting_tasks
      waiting_children.select { |child| child.step.is_a?(BPMN::Task) }
    end

    def waiting_automated_tasks
      waiting_tasks.select { |child| child.step.is_automated? }
    end

    def tokens(active_tokens = [])
      children.each do |child|
        active_tokens = active_tokens + child.tokens_out
        active_tokens = active_tokens - child.tokens_in if child.ended?
        active_tokens = active_tokens + child.tokens(active_tokens)
      end
      active_tokens.uniq
    end

    def serialize(...)
      to_json(...)
    end

    def as_json(_options = {})
      {
        id: id,
        step_id: step&.id,
        step_type: step&.class&.name&.demodulize,
        attached_to_id: attached_to_id,
        status: status,
        started_at: started_at,
        ended_at: ended_at,
        variables: variables.as_json,
        tokens_in: tokens_in,
        tokens_out: tokens_out,
        message_names: message_names,
        error_names: error_names,
        timer_expires_at: timer_expires_at,
        condition: condition,
        children: children.map { |child| child.as_json },
      }.transform_values(&:presence).compact
    end

    def inspect
      parts = ["#<Execution @id=#{id.inspect}"]
      parts << "@step_type=#{step&.class&.name&.demodulize}" if step
      parts << "@step_id=#{step.id.inspect}" if step
      parts << "@status=#{status.inspect}" if status
      parts << "@started_at=#{started_at.inspect}" if started_at
      parts << "@ended_at=#{ended_at.inspect}" if ended_at
      parts << "@attached_to_id=#{attached_to_id.inspect}" if attached_to_id
      parts << "@variables=#{variables.inspect}" if variables.present?
      # parts << "@tokens_in=#{tokens_in.inspect}" if tokens_in.present?
      # parts << "@tokens_out=#{tokens_out.inspect}" if tokens_out.present?
      parts << "@message_names=#{message_names.inspect}" if message_names.present?
      parts << "@error_names=#{error_names.inspect}" if error_names.present?
      parts << "@timer_expires_at=#{timer_expires_at.inspect}" if timer_expires_at
      parts << "@condition=#{condition.inspect}" if condition
      parts << "@children=#{children.inspect}" if children.present?
      parts.join(" ") + ">"
    end

    private

    def map_input_variables
      return unless step&.input_mappings&.present?
      step.input_mappings.each do |parameter|
        variables[parameter.target] = evaluate_expression(parameter.source)
      end
    end

    def map_output_variables
      return unless step&.output_mappings&.present?
      step.output_mappings.each do |parameter|
        variables[parameter.target] = evaluate_expression(parameter.source)
      end
    end

    def result_to_variables(result)
      if step.respond_to?(:result_variable) && step.result_variable
        return { "#{step.result_variable}": result }
      else
        if result.is_a? Hash
          result
        else
          {}.tap { |h| h[step.id.underscore] = result }
        end
      end
    end

    def printer
      @printer ||= ExecutionPrinter.new(self)
    end
  end

  class ExecutionError < StandardError
    attr_reader :execution

    def initialize(msg, execution: nil)
      @execution = execution
      super(msg)
    end
  end

  class ExecutionPrinter
    attr_accessor :execution

    def initialize(execution)
      @execution = execution
    end

    def print
      puts
      puts "#{execution.step.id} #{execution.status} * #{execution.tokens.join(', ')}"
      print_variables unless execution.variables.empty?
      print_children
      puts
    end

    def print_children
      puts
      execution.children.each_with_index do |child, index|
        print_child(child, index)
      end
    end

    def print_child(child, index)
      str = "#{index} #{child.step.class.name.demodulize} #{child.step.id}: #{child.status} #{JSON.pretty_generate(child.variables, { indent: '', object_nl: ' ' }) unless child.variables.empty? }".strip
      str = "#{str} * in: #{child.tokens_in.join(', ')}" if child.tokens_in.present?
      str = "#{str} * out: #{child.tokens_out.join(', ')}" if child.tokens_out.present?
      puts str
      child.children.each_with_index do |grandchild, grandindex|
        print_child(grandchild, "#{index}.#{grandindex}")
      end
    end

    def print_variables
      puts
      puts JSON.pretty_generate(execution.variables)
    end
  end
end
