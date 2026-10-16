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

  test "the application backtrace lists only application frames and the hidden full backtrace lists them all" do
    occurrence = @error.occurrences.last
    occurrence.update!(backtrace: [
      "#{Gem.path.first}/gems/rack-3.0.0/lib/rack.rb:1:in 'call'",
      "#{Rails.root.join("config/routes.rb")}:8:in 'block in <main>'"
    ].join("\n"))

    get solid_errors.error_path(@error)

    assert_select "#backtrace-application-#{occurrence.id} summary", count: 1
    assert_select "#backtrace-application-#{occurrence.id} summary", text: /routes\.rb/
    assert_select "#backtrace-full-#{occurrence.id}[hidden] summary", count: 2
  end

  test "a backtrace without application frames offers the full trace" do
    occurrence = @error.occurrences.last
    occurrence.update!(backtrace: "#{Gem.path.first}/gems/rack-3.0.0/lib/rack.rb:1:in 'call'")

    get solid_errors.error_path(@error)

    assert_select "#backtrace-application-#{occurrence.id}", text: /No application code in backtrace/
    assert_select "#backtrace-application-#{occurrence.id} button[data-backtrace-toggle=full]"
  end

  test "the dashboard links back to the host app's root" do
    get solid_errors.errors_path

    assert_select "main a[href='/']", text: "← Back to main app"
  end

  test "the dashboard renders in apps that do not make English available" do
    available_locales, default_locale, locale = I18n.available_locales, I18n.default_locale, I18n.locale
    I18n.available_locales = [:fr]
    I18n.default_locale = I18n.locale = :fr

    get solid_errors.errors_path
    assert_response :success

    get solid_errors.error_path(@error)
    assert_response :success
  ensure
    I18n.available_locales = available_locales
    I18n.default_locale = default_locale
    I18n.locale = locale
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
