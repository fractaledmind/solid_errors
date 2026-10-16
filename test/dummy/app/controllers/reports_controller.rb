class ReportsController < ApplicationController
  def create
    Rails.error.handle { raise "reported from a request" }
    head :ok
  end
end
