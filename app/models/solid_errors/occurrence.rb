module SolidErrors
  class Occurrence < Record
    belongs_to :error, class_name: "SolidErrors::Error"

    after_create_commit :send_email, if: :should_send_email?
    after_create_commit :clear_resolved_errors, if: :should_clear_resolved_errors?

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
      self.update_column(:resolved_at, nil)
    end

    def clear_resolved_errors
      transaction do
        SolidErrors::Occurrence
          .where(error: SolidErrors::Error.resolved)
          .where(created_at: ...SolidErrors.destroy_after.ago)
          .delete_all
        SolidErrors::Error.resolved
          .where
          .missing(:occurrences)
          .delete_all
      end
    end

    def should_clear_resolved_errors?
      return false unless SolidErrors.destroy_after
      return false unless SolidErrors.destroy_after.respond_to?(:ago)
      return false unless (id % 100).zero?

      true
    end

    def should_send_email?
      SolidErrors.send_emails? && SolidErrors.email_to.present? && self.resolved_at.nil?
    end
  end
end
