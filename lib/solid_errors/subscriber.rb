module SolidErrors
  class Subscriber
    IGNORED_ERRORS = ["ActionController::RoutingError",
                      "AbstractController::ActionNotFound",
                      "ActionController::MethodNotAllowed",
                      "ActionController::UnknownHttpMethod",
                      "ActionController::NotImplemented",
                      "ActionController::UnknownFormat",
                      "ActionController::InvalidAuthenticityToken",
                      "ActionController::InvalidCrossOriginRequest",
                      "ActionDispatch::Http::Parameters::ParseError",
                      "ActionController::BadRequest",
                      "ActionController::ParameterMissing",
                      "ActiveRecord::RecordNotFound",
                      "ActionController::UnknownAction",
                      "ActionDispatch::Http::MimeNegotiation::InvalidType",
                      "Rack::QueryParser::ParameterTypeError",
                      "Rack::QueryParser::InvalidParameterError",
                      "CGI::Session::CookieStore::TamperedWithCookie",
                      "Mongoid::Errors::DocumentNotFound",
                      "Sinatra::NotFound",
                      "Sidekiq::JobRetry::Skip"].map(&:freeze).freeze

    def report(error, handled:, severity:, context:, source: nil)
      return if ignore_by_class?(error.class.name)

      error_attributes = {
        exception_class: error.class.name,
        message: s(error.message),
        severity: severity,
        source: source
      }
      fingerprint = Digest::SHA256.hexdigest(error_attributes.values.join)
      if (record = SolidErrors::Error.find_by(fingerprint: fingerprint))
        record.update!(resolved_at: nil, updated_at: Time.now)
      else
        record = SolidErrors::Error.create!(error_attributes.merge(fingerprint: fingerprint))
      end

      backtrace_cleaner = ActiveSupport::BacktraceCleaner.new
      backtrace_cleaner.add_silencer { |line| /puma|rubygems|gems/.match?(line) }
      backtrace = SolidErrors.full_backtrace? ? error.backtrace : backtrace_cleaner.clean(error.backtrace)

      SolidErrors::Occurrence.create(
        error_id: record.id,
        backtrace: backtrace&.join("\n"),
        context: s(context)
      )
    end

    def s(data)
      Sanitizer.sanitize(data)
    end

    def ignore_by_class?(error_class_name)
      IGNORED_ERRORS.any? do |ignored_class|
        ignored_class_name = ignored_class.respond_to?(:name) ? ignored_class.name : ignored_class

        ignored_class_name == error_class_name
      end
    end
  end
end
