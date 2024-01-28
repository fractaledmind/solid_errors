# frozen_string_literal: true

module SolidErrors
  class Record < ActiveRecord::Base
    self.abstract_class = true

    connects_to(**SolidErrors.connects_to) if SolidErrors.connects_to
  end
end

ActiveSupport.run_load_hooks :solid_errors_record, SolidErrors::Record
