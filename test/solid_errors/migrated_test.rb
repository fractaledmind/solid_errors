require "test_helper"

class SolidErrors::MigratedTest < ActiveSupport::TestCase
  teardown do
    SolidErrors::Error.reset_column_information
    SolidErrors::Occurrence.reset_column_information
  end

  test "migrated when the errors database has the current schema" do
    assert SolidErrors.migrated?
  end

  test "not migrated when a column this version uses is missing" do
    ActiveRecord::Base.connection.remove_column :solid_errors, :fingerprint
    SolidErrors::Error.reset_column_information

    assert_not SolidErrors.migrated?
  end

  test "not migrated when a table is missing" do
    ActiveRecord::Base.connection.drop_table :solid_errors_occurrences
    SolidErrors::Occurrence.reset_column_information

    assert_not SolidErrors.migrated?
  end
end
