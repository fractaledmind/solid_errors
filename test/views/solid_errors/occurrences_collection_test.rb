require "test_helper"

class SolidErrors::OccurrencesCollectionTest < ActionView::TestCase
  test "an empty list of occurrences says so" do
    render partial: "solid_errors/occurrences/collection", locals: {occurrences: SolidErrors::Occurrence.none, page: nil}

    assert_select "svg.bi-list-ul"
    assert_select "span", text: "No occurrences yet…"
  end
end
