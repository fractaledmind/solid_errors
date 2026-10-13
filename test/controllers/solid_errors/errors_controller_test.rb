require "test_helper"

class SolidErrors::ErrorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    report_errors(2)
    @error = SolidErrors::Error.last
  end

  test "occurrence pagination links use the default page size without an items param" do
    report_errors(19)
    get solid_errors.error_path(@error)

    assert_response :success
    assert_equal [solid_errors.error_path(@error, page: 2)] * 2, pagination_hrefs
  end

  test "occurrence pagination links keep the items param" do
    get solid_errors.error_path(@error, items: 1)

    assert_response :success
    assert_equal [solid_errors.error_path(@error, items: 1, page: 2)] * 2, pagination_hrefs
  end

  test "occurrence pagination links ignore url_for options in the request params" do
    get solid_errors.error_path(@error), params: {
      items: 1,
      script_name: "javascript:alert(1)//",
      original_script_name: "javascript:alert(1)//",
      host: "evil.example",
      protocol: "https",
      port: 6666,
      anchor: "x"
    }

    assert_response :success
    assert_equal [solid_errors.error_path(@error, items: 1, page: 2)] * 2, pagination_hrefs
  end

  test "inline styles and scripts carry the content security policy nonce" do
    get solid_errors.error_path(@error)

    nonce = response.headers["Content-Security-Policy"][/style-src [^;]*'nonce-([^']+)'/, 1]
    assert nonce
    inline_tags = css_select("style, script:not([src])")
    assert_not_empty inline_tags
    inline_tags.each { |tag| assert_equal nonce, tag["nonce"], tag.to_html[0, 40] }
  end

  test "an occurrence reported without a backtrace still renders" do
    # Rails 7 reports exceptions that were never raised without a backtrace
    @error.occurrences.update_all(backtrace: nil)

    get solid_errors.error_path(@error)

    assert_response :success
  end

  test "the dashboard links back to the host app's root" do
    get solid_errors.errors_path

    assert_select "main a[href='/']", text: "← Back to main app"
  end

  private

  def report_errors(count)
    count.times do
      raise StandardError, "oof"
    rescue => error
      Rails.error.report(error)
    end
  end

  def pagination_hrefs
    css_select("nav[aria-label=Pages] a[href]").map { |link| link["href"] }
  end
end
