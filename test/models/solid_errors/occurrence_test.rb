require "test_helper"

class SolidErrors::OccurrenceTest < ActiveSupport::TestCase
  def teardown
    SolidErrors.destroy_after = nil
  end

  test "do not destroy if destroy_after is not set" do
    SolidErrors.destroy_after = nil
    simulate_99_old_exceptions(:resolved)

    assert_difference -> { SolidErrors::Error.count }, +1 do
      assert_difference -> { SolidErrors::Occurrence.count }, +1 do
        Rails.error.report(StandardError.new("oof"))
      end
    end
  end

  test "destroy old occurrences every 100 insertions if destroy_after is set" do
    SolidErrors.destroy_after = 1.day
    simulate_99_old_exceptions(:resolved)

    assert_difference -> { SolidErrors::Error.count }, 0 do
      assert_difference -> { SolidErrors::Occurrence.count }, 0 do
        Rails.error.report(StandardError.new("oof"))
      end
    end
  end

  test "not destroy if errors are unresolved" do
    SolidErrors.destroy_after = 1.day
    simulate_99_old_exceptions(:unresolved)

    assert_difference -> { SolidErrors::Error.count }, +1 do
      assert_difference -> { SolidErrors::Occurrence.count }, +1 do
        assert_empty SolidErrors::Error.resolved
        Rails.error.report(StandardError.new("oof"))
      end
    end
  end

  private

  def simulate_99_old_exceptions(status)
    Rails.error.report(StandardError.new("argh"))
    SolidErrors::Error.update_all(resolved_at: Time.current) if status == :resolved
    SolidErrors::Occurrence.last.update!(id: 99, created_at: 1.day.ago)
  end
end
