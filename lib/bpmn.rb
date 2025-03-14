# frozen_string_literal: true

require "bpmn/version"

require "active_support"
require "active_support/time"
require "active_support/core_ext/hash"
require "active_support/core_ext/object/json"
require "active_support/configurable"
require "active_model"

require "dmn"

require "bpmn/element"
require "bpmn/extensions"
require "bpmn/extension_elements"
require "bpmn/step"
require "bpmn/flow"
require "bpmn/event_definition"
require "bpmn/event"
require "bpmn/gateway"
require "bpmn/task"
require "bpmn/process"
require "bpmn/definitions"

require "bpmn/context"
require "bpmn/execution"

module BPMN
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
    Definitions.from_xml(xml)&.processes || []
  end

  #
  # Extract decisions from a DMN XML file.
  #
  def self.decisions_from_xml(xml)
    definitions = DMN.definitions_from_xml(xml)
    definitions.decisions
  end
end
