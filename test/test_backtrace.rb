# frozen_string_literal: true

require "test_helper"

class TestSolidErrors < Minitest::Test
  def test_backtrace
    backtrace = SolidErrors::Backtrace.parse(caller(0)).to_a
    assert_equal backtrace[0][:method], "TestSolidErrors#test_backtrace"
  end
end
