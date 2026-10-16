require "test_helper"

class SolidErrors::ContextTest < ActionDispatch::IntegrationTest
  test "an error in a request records the controller action and its filtered params" do
    post "/reports", params: {name: "Ada", password: "secret"}

    context = SolidErrors::Occurrence.last.context
    assert_equal "ReportsController#create", context["controller"]
    assert_equal({"name" => "Ada", "password" => "[FILTERED]"}, context["params"])
  end

  test "an error in a job records the job and its filtered arguments, with records as global ids" do
    record = record_an_error

    job = ReportJob.new(record, {"password" => "secret", "retries" => 3})
    job.perform_now

    context = SolidErrors::Occurrence.last.context
    assert_equal ["ReportJob", job.job_id, "default"], context.values_at("job", "job_id", "queue")
    assert_equal [record.to_global_id.to_s, {"password" => "[FILTERED]", "retries" => 3}], context["arguments"]
  end

  test "a record in the context is recorded as its global id" do
    record = record_an_error

    Rails.error.report(StandardError.new("with a record"), context: {error_record: record})

    assert_equal record.to_global_id.to_s, SolidErrors::Occurrence.last.context["error_record"]
  end

  test "an unsaved record in the context is recorded by its class" do
    Rails.error.report(StandardError.new("with a new record"), context: {error_record: SolidErrors::Error.new})

    assert_equal "#<SolidErrors::Error>", SolidErrors::Occurrence.last.context["error_record"]
  end

  private

  def record_an_error
    Rails.error.report(StandardError.new("first"))
    SolidErrors::Error.last
  end
end
