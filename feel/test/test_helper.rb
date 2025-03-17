# frozen_string_literal: true

GEM_ROOT = File.join(File.dirname(__FILE__), "..")

require "minitest/autorun"
require "minitest/reporters"
require "minitest/spec"
require "minitest/focus"
require "active_support"
require "active_support/testing/time_helpers"
require "pry"

Time.zone_default = Time.find_zone!("UTC")

Minitest::Reporters.use!(
  Minitest::Reporters::ProgressReporter.new(color: true),
    ENV,
    Minitest.backtrace_filter,
)

require_relative "../lib/feel"

class Minitest::Spec
  include ActiveSupport::Testing::TimeHelpers

  before :each do
  end

  after :each do
  end

  def file_fixture(filename)
    Pathname.new(File.join(GEM_ROOT, "/test/fixtures/files", filename))
  end

  def fixture_source(filename)
    file_fixture(filename).read
  end

  def eval(expression, context: {})
    FEEL::Parser.new.evaluate(expression, context: context)
  end

  def unary(context, expression)
    FEEL::Parser.new.unary_test(expression, context: context)
  end

  def custom_functions
    {
      reverse: proc { |s| s.reverse },
      cookie: proc {
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
      },
    }
  end
end
