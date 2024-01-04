# frozen_string_literal: true

require "test_helper"

module SpotFlow
  module Bpmn

    describe Task do
      let(:sources) { fixture_source("task_test.bpmn") }
      let(:context) { SpotFlow.new(sources) }

      describe :definition do
        let(:process) { context.process_by_id("TaskTest") }
        let(:task) { process.element_by_id("Task") }

        it "should parse the task" do
          _(task).wont_be_nil
        end
      end

      describe :execution do
        before { @execution = context.start }

        let(:execution) { @execution }
        let(:task) { execution.child_by_step_id("Task") }

        it "should start the process" do
          _(execution.started?).must_equal true
          _(task.waiting?).must_equal true
        end

        describe :signal do
          before { task.signal }

          it "should end the process" do
            _(execution.completed?).must_equal true
            _(task.completed?).must_equal true
          end
        end
      end
    end

    describe UserTask do
      # Behaves like Task
    end

    describe ServiceTask do
      let(:sources) { fixture_source("service_task_test.bpmn") }
      let(:context) { SpotFlow.new(sources) }

      describe :definition do
        let(:process) { context.process_by_id("ServiceTaskTest") }
        let(:service_task) { process.element_by_id("ServiceTask") }

        it "should parse the service task" do
          _(service_task.task_type).must_equal "do_it"
        end
      end

      describe :manual_execution do
        before do
          @execution = context.start(variables: { name: "Eric" })
        end

        let(:execution) { @execution }
        let(:service_step) { execution.child_by_step_id("ServiceTask") }

        it "should wait at the service task" do
          _(service_step.waiting?).must_equal true
        end

        describe :run do
          before { service_step.signal({ "service_task": "👋 Hello Eric!" }) }

          it "should run the service task" do
            _(execution.completed?).must_equal true
            _(service_step.completed?).must_equal true
            _(execution.variables["service_task"]).must_equal "👋 Hello Eric!"
            _(service_step.variables["service_task"]).must_equal "👋 Hello Eric!"
          end
        end
      end
    end

    describe ScriptTask do
      let(:sources) { fixture_source("script_task_test.bpmn") }
      let(:context) { SpotFlow.new(sources) }

      describe :definition do
        let(:process) { context.process_by_id("ScriptTaskTest") }
        let(:script_task) { process.element_by_id("ScriptTask") }

        it "should parse the script task" do
          _(script_task.script).wont_be_nil
          _(script_task.script).must_equal "=\"👋 Hello \" + name + \" from ScriptTask!\""
        end
      end

      describe :execution do
        before { @execution = context.start(variables: { name: "Eric" }) }

        let(:execution) { @execution }
        let(:script_task) { execution.child_by_step_id("ScriptTask") }

        it "should run the script task" do
          _(execution.completed?).must_equal true
          _(script_task.completed?).must_equal true
          _(execution.variables["greeting"]).must_equal "👋 Hello Eric from ScriptTask!"
          _(script_task.variables["greeting"]).must_equal "👋 Hello Eric from ScriptTask!"
        end
      end
    end

    describe BusinessRuleTask do
      let(:sources) { [fixture_source("business_rule_task_test.bpmn"), fixture_source("dish.dmn")] }
      let(:context) { Context.new(sources) }

      describe :definition do
        let(:process) { context.process_by_id("BusinessRuleTaskTest") }
        let(:business_rule_task) { process.element_by_id("BusinessRuleTask") }

        it "should parse the business rule task" do
          _(business_rule_task.decision_id).wont_be_nil
          _(business_rule_task.decision_id).must_equal "Dish"
        end
      end

      describe :execution do
        before { @execution = context.start(variables: { season: "Spring", guests: 7 }) }

        let(:execution) { @execution }
        let(:business_rule_task) { execution.child_by_step_id("BusinessRuleTask") }

        it "should run the business rule task" do
          _(execution.completed?).must_equal true
          _(business_rule_task.completed?).must_equal true
          _(business_rule_task.variables["result"]["dish"]).must_equal "Steak"
        end
      end
    end
  end
end
