class ReportJob < ActiveJob::Base
  def perform(record, options)
    Rails.error.handle { raise "reported from a job" }
  end
end
