# frozen_string_literal: true

require "test_helper"

class ChooseFortuneService
  def call(_variables, _headers)
    [
      "The fortune you seek is in another cookie.",
      "A closed mouth gathers no feet.",
      "A conclusion is simply the place where you got tired of thinking.",
      "A cynic is only a frustrated optimist.",
      "A foolish man listens to his heart. A wise man listens to cookies.",
      "You will die alone and poorly dressed.",
      "A fanatic is one who can't change his mind, and won't change the subject.",
      "If you look back, you’ll soon be going that way.",
      "You will live long enough to open many fortune cookies.",
      "An alien of some sort will be appearing to you shortly.",
      "Do not mistake temptation for opportunity.",
      "Flattery will go far tonight.",
      "He who laughs at himself never runs out of things to laugh at.",
      "He who laughs last is laughing at you.",
      "He who throws dirt is losing ground.",
      "Some men dream of fortunes, others dream of cookies.",
      "The greatest danger could be your stupidity.",
      "We don’t know the future, but here’s a cookie.",
      "The world may be your oyster, but it doesn't mean you'll get its pearl.",
      "You will be hungry again in one hour.",
      "The road to riches is paved with homework.",
      "You can always find happiness at work on Friday.",
      "Actions speak louder than fortune cookies.",
      "Because of your melodic nature, the moonlight never misses an appointment.",
      "Don’t behave with cold manners.",
      "Don’t forget you are always on our minds.",
      "Help! I am being held prisoner in a fortune cookie factory.",
      "It’s about time I got out of that cookie.",
      "Never forget a friend. Especially if he owes you.",
      "Never wear your best pants when you go to fight for freedom.",
      "Only listen to the fortune cookie; disregard all other fortune telling units.",
      "It is a good day to have a good day.",
      "All fortunes are wrong except this one.",
      "Someone will invite you to a Karaoke party.",
      "That wasn’t chicken.",
      "There is no mistake so great as that of being always right.",
      "You love Chinese food.",
      "I am worth a fortune.",
      "No snowflake feels responsible in an avalanche.",
      "You will receive a fortune cookie.",
      "Some fortune cookies contain no fortune.",
      "Don’t let statistics do a number on you.",
      "You are not illiterate.",
      "May you someday be carbon neutral.",
      "You have rice in your teeth.",
      "Avoid taking unnecessary gambles. Lucky numbers: 12, 15, 23, 28, 37",
      "Ask your mom instead of a cookie.",
      "This cookie contains 117 calories.",
      "Hard work pays off in the future. Laziness pays off now.",
      "You think it’s a secret, but they know.",
      "If a turtle doesn’t have a shell, is it naked or homeless?",
      "Change is inevitable, except for vending machines.",
      "Don’t eat the paper.",
    ].sample
  end
end

module BPMN
  describe :module do
    it "should have a version" do
      _(BPMN::VERSION).wont_be_nil
    end
  end

  describe :hello_world do
    let(:bpmn_xml) { fixture_source("hello_world.bpmn") }
    let(:dmn_xml) { fixture_source("choose_greeting.dmn") }
    let(:sources) { [bpmn_xml, dmn_xml] }

    describe :processes_from_xml do
      let(:processes) { BPMN.processes_from_xml(bpmn_xml) }
      let(:process) { processes.first }
      let(:start_event) { process.element_by_id("Start") }
      let(:user_task) { process.element_by_id("IntroduceYourself") }
      let(:boundary_event) { process.element_by_id("EggTimer") }
      let(:split_gateway) { process.element_by_id("Split") }
      let(:business_rule_task) { process.element_by_id("ChooseGreeting") }
      let(:service_task) { process.element_by_id("ChooseFortune") }
      let(:join_gateway) { process.element_by_id("Join") }
      let(:script_task) { process.element_by_id("GenerateMessage") }
      let(:end_event) { process.element_by_id("End") }

      it "should extract processes from XML" do
        _(process.id).must_equal "HelloWorld"
        _(process.name).must_equal "Hello World"
        _(start_event).wont_be_nil
        _(user_task).wont_be_nil
        _(boundary_event).wont_be_nil
        _(split_gateway).wont_be_nil
        _(business_rule_task).wont_be_nil
        _(service_task).wont_be_nil
        _(join_gateway).wont_be_nil
        _(script_task).wont_be_nil
        _(end_event.id).must_equal "End"
      end
    end

    describe :execution do
      before { @execution = BPMN.new(sources).start }

      let(:execution) { @execution }
      let(:start_event) { execution.child_by_step_id("Start") }
      let(:user_task) { execution.child_by_step_id("IntroduceYourself") }
      let(:boundary_event) { execution.child_by_step_id("EggTimer") }
      let(:split_gateway) { execution.child_by_step_id("Split") }
      let(:business_rule_task) { execution.child_by_step_id("ChooseGreeting") }
      let(:service_task) { execution.child_by_step_id("ChooseFortune") }
      let(:join_gateway) { execution.child_by_step_id("Join") }
      let(:script_task) { execution.child_by_step_id("GenerateMessage") }
      let(:end_event) { execution.child_by_step_id("End") }

      it "should initialize the context" do
        _(execution.started?).must_equal true
        _(user_task.waiting?).must_equal true
        _(boundary_event.waiting?).must_equal true
      end

      describe :serialization do
        let(:execution_state) { execution.serialize }

        it "should serialize the process state" do
          _(execution_state).wont_be_nil
        end

        describe :deserialization do
          before { @execution = BPMN.restore(sources, execution_state: execution_state) }

          it "process should be restored to waiting state" do
            _(execution.started?).must_equal true
            _(user_task.waiting?).must_equal true
            _(boundary_event.waiting?).must_equal true
          end

          describe :complete_user_task do
            before { user_task.signal(name: "Eric", language: "it", formal: false, cookie: true) }

            it "should split into two paths" do
              _(user_task.completed?).must_equal true
              _(business_rule_task.waiting?).must_equal true
              _(service_task.waiting?).must_equal true
            end

            describe :run_automated_tasks do
              before { execution.run_automated_tasks }

              it "should complete waiting tasks" do
                _(business_rule_task.completed?).must_equal true
                _(service_task.completed?).must_equal true
                _(script_task.waiting?).must_equal true
              end

              describe :run_script_task do
                before { script_task.run }

                it "should complete the process" do
                  _(script_task.completed?).must_equal true
                  _(end_event.completed?).must_equal true
                end
              end
            end
          end
        end
      end
    end
  end
end
