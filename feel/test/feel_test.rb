# frozen_string_literal: true

require "test_helper"

module FEEL

  describe :module do
    it "should have a version number" do
      _(FEEL::VERSION).wont_be_nil
    end
  end

  describe :evaluate do
    it "should eval a simple expression" do
      _(FEEL.evaluate('"👋 Hello " + name', variables: { name: "World" })).must_equal "👋 Hello World"
    end

    it "should eval slightly more complex expressions" do
      _(FEEL.evaluate('if person.age >= 18 then "adult" else "minor"', variables: { person: { name: "Eric", age: 59 } })).must_equal "adult"
    end

    it "should eval built-in functions" do
      _(FEEL.evaluate("sum([1, 2, 3])")).must_equal 6
    end

    it "should eval user defined functions" do
      _(FEEL.evaluate('reverse_inline("Hello World!")', variables: { "reverse_inline": ->(s) { s.reverse } })).must_equal "!dlroW olleH"
    end

    it "should eval user defined functions from config" do
      FEEL.config.functions = {
        "upcase_config": ->(s) { s.upcase },
      }
      _(FEEL.evaluate('upcase_config("Hello World!")')).must_equal "HELLO WORLD!"
    ensure
      FEEL.config.functions = {}
    end
  end

  describe :test do
    it "should match input entry '42' to the numeric value 42" do
      _(FEEL.test(42, "42")).must_equal true
      _(FEEL.test(41, "42")).must_equal false
    end

    it "should match input entry '< 42' to a value less than 42" do
      _(FEEL.test(41, "< 42")).must_equal true
      _(FEEL.test(42, "< 42")).must_equal false
    end

    it "should match input entry '[41 .. 50]' to a value between 41 and 50 (inclusive)" do
      _(FEEL.test(41, "[41 .. 50]")).must_equal true
      _(FEEL.test(40, "[41 .. 50]")).must_equal false
    end

    it "should match input entry '<10, >20' to a value less than 10 or greater than 20" do
      _(FEEL.test(21, "<10, >20")).must_equal true
      _(FEEL.test(15, "<10, >20")).must_equal false
    end

    it "should match input entry '\"A\"' to the string value \"A\"" do
      _(FEEL.test("A", '"A"')).must_equal true
      _(FEEL.test("B", '"A"')).must_equal false
    end

    it "should match input entry: '\"A\"', '\"B\"' to the string value \"A\" or \"B\"" do
      _(FEEL.test("B", '"A", "B"')).must_equal true
      _(FEEL.test("A", '"A", "B"')).must_equal true
      _(FEEL.test("C", '"A", "B"')).must_equal false
    end

    it "should match input entry 'true' to the boolean value true" do
      _(FEEL.test(true, "true")).must_equal true
      _(FEEL.test(false, "true")).must_equal false
      _(FEEL.test(3, "true")).must_equal false
    end

    it "should match input entry '-' to anything" do
      _(FEEL.test("ANYTHING", "-")).must_equal true
      _(FEEL.test(3, "-")).must_equal true
      _(FEEL.test(false, "-")).must_equal true
    end

    it "should match input entry nil to anything" do
      _(FEEL.test(33, nil)).must_equal true
    end

    it "should match input entry 'null' to nil" do
      _(FEEL.test(nil, "null")).must_equal true
      _(FEEL.test(3, "null")).must_equal false
    end

    it "should match input entry 'not(null)' to any value other than nil" do
      _(FEEL.test("ANYTHING", "not(null)")).must_equal true
      _(FEEL.test(nil, "not(null)")).must_equal false
    end

    it "should match input entry 'property' to the same value as the property (must be given in the context)" do
      _(FEEL.test(42, "property", variables: { property: 42 })).must_equal true
    end

    it "should match input entry 'object.property' to the same value as the property of the object" do
      _(FEEL.test(42, "object.property", variables: { object: { property: 42 } })).must_equal true
    end

    it "should match input entry 'f(a)' to same value as the function evaluated with the property (function and property must be given in the context)" do
      FEEL.config.functions = { "f" => proc { |a| a == 42 } }
      _(FEEL.test(true, "f(a)", variables: { a: 42 })).must_equal true
    end

    it "should match input entry 'limit - 10' to the same value as the limit minus 10" do
      _(FEEL.test(42, "limit - 10", variables: { limit: 52 })).must_equal true
    end

    it "should match input entry 'limit * 2' to the same value as the limit times 2" do
      _(FEEL.test(42, "limit * 2", variables: { limit: 21 })).must_equal true
    end

    it "should match input entry '[limit.upper, limit.lower]' to a value between the value of two given properties of object limit" do
      _(FEEL.test(42, "[limit.lower .. limit.upper]", variables: { limit: { upper: 50, lower: 40 } })).must_equal true
    end

    it "should do date math inside an interval" do
      period_begin = Date.new(2018, 01, 01)
      variables = {
        period_begin: period_begin,
        period_duration: ActiveSupport::Duration.build(2716146),
      }
      input = period_begin + 20.days
      _(FEEL.test(input, "[period_begin .. period_begin + period_duration]", variables:)).must_equal true
    end

    it "should match input entry 'date(\"1963-12-23\")' to the date value 1963-12-23" do
      _(FEEL.test(Date.new(1963, 12, 23), 'date("1963-12-23")')).must_equal true
      _(FEEL.test(Date.new(1963, 12, 24), 'date("1963-12-23")')).must_equal false
    end

    it "should match input entry 'date(property)' to the date which is defined by the value of the given property, the time if cropped to 00:00:00" do
      _(FEEL.test(Date.new(1963, 12, 23), "date(property)", variables: { property: Date.new(1963, 12, 23) })).must_equal true
    end

    it "should match input entry 'date and time(property)' to the date and time which is defined by the value of the given property" do
      _(FEEL.test(DateTime.new(1963, 12, 23, 12, 34, 56), "date and time(property)", variables: { property: DateTime.new(1963, 12, 23, 12, 34, 56) })).must_equal true
    end

    it "should match input entry 'duration(d)' to the duration specified by d, an ISO 8601 duration string like P3D for three days (duration is built-in either)" do
      _(FEEL.test(3.days, 'duration("P3D")')).must_equal true
    end

    it "should match input entry 'duration(d) * 2' to twice the duration" do
      _(FEEL.test(6.days, 'duration("P3D") * 2')).must_equal true
    end

    it "should match input entry 'duration(begin, end)' to the duration between the specified begin and end date" do
      _(FEEL.test(3.days, 'duration("1963-12-23", "1963-12-26")')).must_equal true
    end

    it "should match input entry 'date(begin) + duration(d)' to the date that results by adding the given duration to the given date" do
      _(FEEL.test(Date.new(1963, 12, 26), 'date("1963-12-23") + duration("P3D")')).must_equal true
    end

    it "should match input entry '< date(begin) + duration(d)' to any date before the date that results by adding the given duration to the given date" do
      _(FEEL.test(Date.new(1963, 12, 22), '< date("1963-12-23") + duration("P3D")')).must_equal true
    end
  end
end
