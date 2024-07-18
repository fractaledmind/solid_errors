module SolidErrors
  class Occurrence < Record
    belongs_to :error, class_name: "SolidErrors::Error"

    after_create_commit :send_email, if: :should_send_email?

    # The parsed exception backtrace. Lines in this backtrace that are from installed gems
    # have the base path for gem installs replaced by "[GEM_ROOT]", while those in the project
    # have "[PROJECT_ROOT]".
    # @return [Array<{:number, :file, :method => String}>]
    def parsed_backtrace
      return @parsed_backtrace if defined? @parsed_backtrace

      @parsed_backtrace = parse_backtrace(backtrace.split("\n"))
    end

    private

    def parse_backtrace(backtrace)
      Backtrace.parse(backtrace)
    end

    def send_email
      ErrorMailer.error_occurred(self).deliver_later
    end

    def should_send_email?
      return false unless SolidErrors.send_emails?
      return false unless SolidErrors.email_to.present?
      return true if error.occurrences.count == 1
      return true unless SolidErrors.one_email_per_occurrence?

      error.occurrences.where(created_at: error.prev_resolved_at..).one?
    end
  end
end
