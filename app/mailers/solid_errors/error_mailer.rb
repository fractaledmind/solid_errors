module SolidErrors
  # adapted from: https://github.com/codergeek121/email_error_reporter/blob/main/lib/email_error_reporter/error_mailer.rb
  class ErrorMailer < ActionMailer::Base
    def error_occurred(occurrence)
      @occurrence = occurrence
      @error = occurrence.error
      subject = "#{@error.severity_emoji} #{@error.exception_class}"
      if SolidErrors.email_subject_prefix.present?
        subject = [SolidErrors.email_subject_prefix, subject].join(" ").squish!
      end
      mail(
        subject: subject,
        from: SolidErrors.email_from,
        to: SolidErrors.email_to
      )
    end
  end
end
