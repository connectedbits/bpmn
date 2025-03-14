# frozen_string_literal: true

module BPMN
  class Definitions
    include ActiveModel::Model

    attr_accessor :id, :name, :target_namespace, :exporter, :exporter_version, :execution_platform, :execution_platform_version
    attr_reader :messages, :signals, :errors, :processes

    def self.from_xml(xml)
      XmlHasher.configure do |config|
        config.snakecase = true
        config.ignore_namespaces = true
        config.string_keys = false
      end
      hash = XmlHasher.parse(xml)
      Definitions.new(hash[:definitions].except(:bpmn_diagram)).tap do |definitions|
        definitions.processes.each do |process|
          process.wire_references(definitions)
        end
      end
    end

    def initialize(attributes={})
      super(attributes.except(:message, :signal, :error, :process))

      @messages = Array.wrap(attributes[:message]).map { |atts| Message.new(atts) }
      @signals = Array.wrap(attributes[:signal]).map { |atts| Signal.new(atts) }
      @errors = Array.wrap(attributes[:error]).map { |atts| Error.new(atts) }
      @processes = Array.wrap(attributes[:process]).map { |atts| Process.new(atts) }
    end

    def message_by_id(id)
      messages.find { |message| message.id == id }
    end

    def signal_by_id(id)
      signals.find { |signal| signal.id == id }
    end

    def error_by_id(id)
      errors.find { |error| error.id == id }
    end

    def process_by_id(id)
      processes.find { |process| process.id == id }
    end

    def inspect
      "#<BPMN::Definitions @id=#{id.inspect} @name=#{name.inspect} @messages=#{messages.inspect} @signals=#{signals.inspect} @errors=#{errors.inspect} @processes=#{processes.inspect}>"
    end
  end
end
