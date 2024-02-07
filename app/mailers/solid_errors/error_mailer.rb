module SolidErrors
  # adapted from: https://github.com/codergeek121/email_error_reporter/blob/main/lib/email_error_reporter/error_mailer.rb
  class ErrorMailer < ActionMailer::Base
    def error_occurred(occurrence)
      @occurrence = occurrence
      @error = occurrence.error

      mail(
        subject: "#{@error.emoji} #{@error.exception_class}",
        from: SolidErrors.email_from,
        to: SolidErrors.email_to
      )
    end
  end
end
