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
    occurrences = SolidErrors::Error.find_by!(message: "oof").occurrences.order(:created_at)
    assert_equal 2, oof["occurrences_count"]
    assert_equal [occurrences.first.created_at.as_json, occurrences.last.created_at.as_json], oof.values_at("first_seen_at", "last_seen_at")
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
    assert_equal({"page" => 1, "count" => 2, "pages" => 2, "prev" => nil, "next" => 2}, response.parsed_body["pagination"])
  end

  test "show gives the backtrace with the project and gem roots filtered out, as the dashboard does" do
    error = SolidErrors::Error.find_by!(message: "ouch")
    error.occurrences.last.update!(backtrace: [
      "#{Gem.path.first}/gems/rack-3.0.0/lib/rack.rb:1:in 'call'",
      "#{Rails.root.join("config/routes.rb")}:8:in 'block in <main>'"
    ].join("\n"))

    get solid_errors.api_error_path(error), headers: authorization

    backtrace = response.parsed_body["occurrences"].first["backtrace"]
    assert_match %r{\A\[GEM_ROOT\]/gems/rack-3\.0\.0/lib/rack\.rb:1}, backtrace.first
    assert_match %r{\A\[PROJECT_ROOT\]/config/routes\.rb:8}, backtrace.last
  end

  test "show treats a page or items below one as one" do
    error = SolidErrors::Error.find_by!(message: "oof")

    get solid_errors.api_error_path(error, items: 0, page: 0), headers: authorization

    assert_response :success
    assert_equal 1, response.parsed_body["occurrences"].size
    assert_equal({"page" => 1, "count" => 2, "pages" => 2, "prev" => nil, "next" => 2}, response.parsed_body["pagination"])
  end

  test "update resolves an error with resolved true and reopens it with false" do
    error = SolidErrors::Error.find_by!(message: "oof")

    patch solid_errors.api_error_path(error), params: {error: {resolved: true}}, headers: authorization, as: :json

    assert_response :success
    assert error.reload.resolved?
    assert_equal error.resolved_at.as_json, response.parsed_body["resolved_at"]

    patch solid_errors.api_error_path(error), params: {error: {resolved: false}}, headers: authorization, as: :json

    assert_response :success
    assert_not error.reload.resolved?
  end

  test "update refuses anything but resolved true or false" do
    error = SolidErrors::Error.find_by!(message: "oof")

    [{error: {resolved: "maybe"}}, {error: {resolved_at: 1700000000}}, {error: "x"}, {}].each do |body|
      patch solid_errors.api_error_path(error), params: body, headers: authorization, as: :json

      assert_response 422, body.inspect
      assert response.parsed_body["error"].present?
    end
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

  test "an unknown error is not found, in JSON" do
    get solid_errors.api_error_path(0), headers: authorization

    assert_response :not_found
    assert_equal "Not found", response.parsed_body["error"]
  end

  test "an empty api_key falls back to SOLIDERRORS_API_KEY" do
    SolidErrors.api_key = ""
    ENV["SOLIDERRORS_API_KEY"] = "from-env"

    get solid_errors.api_errors_path, headers: authorization("from-env")

    assert_response :success
  ensure
    ENV.delete("SOLIDERRORS_API_KEY")
  end

  test "a wrong or missing key is unauthorized" do
    get solid_errors.api_errors_path, headers: authorization("wrong")
    assert_response :unauthorized
    assert_equal "Unauthorized", response.parsed_body["error"]

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
