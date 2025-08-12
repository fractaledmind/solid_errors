module SolidErrors
  class Occurrence < Record
    belongs_to :error, class_name: "SolidErrors::Error"

    after_create :send_email, if: :should_send_email?
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
      return false unless SolidErrors.send_emails? && SolidErrors.email_to.present?

      # Check if resolved_at changed from a datetime to nil (resolved error reoccurred)
      resolved_at_changes = error.previous_changes['resolved_at']
      resolved_error_reoccurred = resolved_at_changes&.first.present? && resolved_at_changes&.last.nil?

      # Check if this is the first occurrence of a brand new error
      first_occurrence = error.occurrences.count == 1

      resolved_error_reoccurred || first_occurrence
    end
  end
end
