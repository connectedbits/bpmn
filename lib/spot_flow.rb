# frozen_string_literal: true

require "spot_flow/version"

require "active_support"
require "active_support/time"
require "active_support/core_ext/hash"
require "active_support/core_ext/object/json"
require "active_support/configurable"
require "json_logic"
require "awesome_print"

require "spot_feel"

require "spot_flow/bpmn/element"
require "spot_flow/bpmn/step"
require "spot_flow/bpmn/flow"
require "spot_flow/bpmn/association"
require "spot_flow/bpmn/task"
require "spot_flow/bpmn/event"
require "spot_flow/bpmn/extensions"
require "spot_flow/bpmn/extension_elements"
require "spot_flow/bpmn/gateway"
require "spot_flow/bpmn/builder"
require "spot_flow/bpmn/process"
require "spot_flow/bpmn/expression"
require "spot_flow/bpmn/event_definition"
require "spot_flow/bpmn/text_annotation"

require "spot_flow/context"
require "spot_flow/execution"
require "spot_flow/task_runner"

require "spot_flow/services/application_service"
require "spot_flow/services/decision_evaluator"
require "spot_flow/services/decision_reader"
require "spot_flow/services/expression_evaluator"
require "spot_flow/services/feel_evaluator"
require "spot_flow/services/json_logic_evaluator"
require "spot_flow/services/process_reader"
require "spot_flow/services/script_runner"

module SpotFlow
  include ActiveSupport::Configurable

  #
  # Entry point for starting a process execution.
  #
  def self.new(sources = [])
    Context.new(sources)
  end

  #
  # Entry point for continuing a process execution.
  #
  def self.restore(sources = [], execution_state:)
    Context.new(sources).restore(execution_state)
  end

  #
  # Extract processes from a BMPN XML file.
  #
  def self.processes_from_xml(xml)
    moddle = SpotFlow::Services::ProcessReader.call(xml)
    builder = Bpmn::Builder.new(moddle)
    builder.processes
  end

  #
  # Extract decisions from a DMN XML file.
  #
  def self.decisions_from_xml(xml)
    SpotFeel.decisions_from_xml(xml)
  end
end
