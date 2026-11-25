require "test_helper"

class SolidErrors::Api::ErrorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    SolidErrors.api_key = "secret"
    report_error("oof")
    report_error("oof")
    report_error("ouch")
  end

  teardown do
    SolidErrors.api_key = nil
  end

  test "index lists the unresolved errors with their occurrences, the latest first" do
    SolidErrors::Error.find_by!(message: "ouch").update!(resolved_at: Time.current)
    report_error("ugh")

    get solid_errors.api_errors_path, headers: authorization

    assert_response :success
    assert_equal ["ugh", "oof"], response.parsed_body["errors"].pluck("message")
    oof = response.parsed_body["errors"].last
    assert_equal 2, oof["occurrences_count"]
    assert_equal %w[exception_class first_seen_at id last_seen_at message occurrences_count resolved_at severity source], oof.keys.sort
  end

  test "index lists the resolved errors with scope=resolved" do
    SolidErrors::Error.find_by!(message: "ouch").update!(resolved_at: Time.current)

    get solid_errors.api_errors_path(scope: :resolved), headers: authorization

    assert_equal ["ouch"], response.parsed_body["errors"].pluck("message")
  end

  test "show gives the error with its markdown and a page of its occurrences, the latest first" do
    error = SolidErrors::Error.find_by!(message: "oof")

    get solid_errors.api_error_path(error, items: 1), headers: authorization

    assert_response :success
    assert_equal error.id, response.parsed_body["id"]
    assert_equal error.to_markdown, response.parsed_body["markdown"]
    assert_equal [error.occurrences.order(:created_at).last.id], response.parsed_body["occurrences"].pluck("id")
    assert_equal({"count" => 2, "pages" => 2, "prev" => nil, "next" => 2}, response.parsed_body["pagination"])
  end

  test "update resolves an error and a null resolved_at reopens it" do
    error = SolidErrors::Error.find_by!(message: "oof")

    patch solid_errors.api_error_path(error), params: {error: {resolved_at: Time.current}}, headers: authorization, as: :json

    assert_response :success
    assert error.reload.resolved?
    assert_equal error.resolved_at.as_json, response.parsed_body["resolved_at"]

    patch solid_errors.api_error_path(error), params: {error: {resolved_at: nil}}, headers: authorization, as: :json

    assert_not error.reload.resolved?
  end

  test "destroy deletes a resolved error and refuses an unresolved one" do
    error = SolidErrors::Error.find_by!(message: "oof")

    delete solid_errors.api_error_path(error), headers: authorization

    assert_response 422
    assert_equal "You must resolve the error before deleting it.", response.parsed_body["error"]
    assert SolidErrors::Error.exists?(error.id)

    error.update!(resolved_at: Time.current)
    delete solid_errors.api_error_path(error), headers: authorization

    assert_response :no_content
    assert_not SolidErrors::Error.exists?(error.id)
  end

  test "an unknown error is not found" do
    get solid_errors.api_error_path(0), headers: authorization

    assert_response :not_found
  end

  test "a wrong or missing key is unauthorized" do
    get solid_errors.api_errors_path, headers: authorization("wrong")
    assert_response :unauthorized

    get solid_errors.api_errors_path
    assert_response :unauthorized
  end

  test "without an api_key the API is off" do
    SolidErrors.api_key = nil

    get solid_errors.api_errors_path, headers: authorization

    assert_response :not_found
  end

  private

  def authorization(key = "secret")
    {"Authorization" => ActionController::HttpAuthentication::Token.encode_credentials(key)}
  end

  def report_error(message)
    raise StandardError, message
  rescue => error
    Rails.error.report(error)
  end
end
