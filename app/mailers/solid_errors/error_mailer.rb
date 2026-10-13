module SolidErrors
  # adapted from: https://github.com/codergeek121/email_error_reporter/blob/main/lib/email_error_reporter/error_mailer.rb
  class ErrorMailer < (defined?(ActionMailer::Base) ? ActionMailer::Base : Object)
    if defined?(ActionMailer::Base)
      # A failure here reported as usual would email again and fail again, without end
      rescue_from StandardError do |exception|
        SolidErrors.without_emails do
          Rails.error.report(exception, handled: true, source: "solid_errors.error_mailer")
        end
      end

      helper_method :occurrence_url
    end

    # reason is passed on to SolidErrors.email_subject: :created or :reopened when the occurrence
    # opened its error, or whatever an app sending this email for its own events passes
    def error_occurred(occurrence, reason = nil)
      unless defined?(ActionMailer::Base)
        raise "ActionMailer is not available. Make sure that you require \"action_mailer/railtie\" in application.rb"
      end
      @occurrence = occurrence
      @error = occurrence.error
      subject = SolidErrors.email_subject.call(error: @error, occurrence: @occurrence, reason: reason&.to_sym)
      if SolidErrors.email_subject_prefix.present?
        subject = [SolidErrors.email_subject_prefix, subject].join(" ").squish!
      end
      mail(
        subject: subject,
        from: SolidErrors.email_from,
        to: SolidErrors.email_to
      )
    end

    private

    # Optional: an app without default_url_options[:host] still gets the email, just unlinked
    def occurrence_url
      public_send(SolidErrors.url_helper_name).error_url(@error, **SolidErrors.url_options, anchor: "occurrence_#{@occurrence.id}")
    rescue ArgumentError, NoMethodError, ActionController::UrlGenerationError
      nil
    end
  end
end
