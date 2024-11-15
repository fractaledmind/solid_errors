require "test_helper"

class SolidErrors::CleanerTest < ActiveSupport::TestCase
  setup do
    assert_nil SolidErrors.destroy_after
  end

  test "not destroy if destroy_after is not set" do
    simulate_99_old_exceptions(:resolved)
    previous_error = SolidErrors::Error.last
    previous_occurrence = SolidErrors::Occurrence.last
    Rails.error.report(dummy_exception)

    assert SolidErrors::Error.exists?(id: previous_error.id)
    assert SolidErrors::Occurrence.exists?(id: previous_occurrence.id)
  end

  test "destroy old occurrences every 100 insertions if destroy_after is set" do
    set_destroy_after
    simulate_99_old_exceptions(:resolved)
    Rails.error.report(dummy_exception)

    assert_equal 1, SolidErrors::Error.count
    assert_equal 1, SolidErrors::Occurrence.count
  end

  test "not destroy if errors are unresolved" do
    set_destroy_after
    simulate_99_old_exceptions(:unresolved)

    assert_difference -> { SolidErrors::Error.count }, +1 do
      assert_difference -> { SolidErrors::Occurrence.count }, +1 do
        Rails.error.report(dummy_exception)
      end
    end
  end

  private

  def simulate_99_old_exceptions(status)
    Rails.error.report(dummy_exception("argh"))
    SolidErrors::Error.update_all(resolved_at: Time.current) if status == :resolved
    SolidErrors::Occurrence.last.update!(id: 99, created_at: 1.day.ago)
  end

  def set_destroy_after
    SolidErrors.stubs(destroy_after: 1.day)
  end

  def dummy_exception(message = "oof")
    exception = StandardError.new(message)
    exception.set_backtrace(caller)
    exception
  end
end
