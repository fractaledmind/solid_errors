module SolidErrors
  module Api
    class ErrorsController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate
      before_action :set_error, only: %i[show update destroy]

      rescue_from ActiveRecord::RecordNotFound do
        render json: {error: "Not found"}, status: :not_found
      end

      # GET /api/errors
      def index
        errors = (params[:scope] == "resolved") ? Error.resolved : Error.unresolved
        occurrences = Occurrence.where(error: errors).group(:error_id)
        counts, first_seen, last_seen = occurrences.count, occurrences.minimum(:created_at), occurrences.maximum(:created_at)

        render json: {
          errors: errors.where(id: counts.keys).sort_by { |error| last_seen[error.id] }.reverse.map do |error|
            error_json(error).merge(occurrences_count: counts[error.id], first_seen_at: first_seen[error.id], last_seen_at: last_seen[error.id])
          end
        }
      end

      # GET /api/errors/1
      def show
        page = ApplicationController::Page.new(@error.occurrences, params)
        occurrences = @error.occurrences.order(created_at: :desc).offset(page.offset).limit(page.items)

        render json: error_json(@error).merge(
          markdown: @error.to_markdown,
          occurrences: occurrences.map { |occurrence| occurrence.slice(:id, :backtrace, :context, :created_at) },
          pagination: {count: page.count, pages: page.pages, prev: page.prev, next: page.next}
        )
      end

      # PATCH/PUT /api/errors/1
      def update
        @error.update!(params.require(:error).permit(:resolved_at))
        render json: error_json(@error)
      end

      # DELETE /api/errors/1
      def destroy
        if @error.resolved?
          @error.destroy
          head :no_content
        else
          render json: {error: "You must resolve the error before deleting it."}, status: 422
        end
      end

      private

      def authenticate
        return head(:not_found) if SolidErrors.api_key.blank?

        authenticate_or_request_with_http_token do |token|
          ActiveSupport::SecurityUtils.secure_compare(token, SolidErrors.api_key)
        end
      end

      def set_error
        @error = Error.find(params[:id])
      end

      def error_json(error)
        error.slice(:id, :exception_class, :message, :severity, :source, :resolved_at)
      end
    end
  end
end
