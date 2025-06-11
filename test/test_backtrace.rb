# frozen_string_literal: true

require "test_helper"

class TestSolidErrors < Minitest::Test
  def test_backtrace
    backtrace = SolidErrors::Backtrace.parse(caller(0)).to_a
    assert_includes backtrace[0][:method], "test_backtrace"
  end
end
