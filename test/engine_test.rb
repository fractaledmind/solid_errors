# frozen_string_literal: true

require "test_helper"

class EngineTest < Minitest::Test
  def setup
    @config = Rails.application.config
    @original_config_enabled = @config.solid_errors.enabled
    @original_module_enabled = SolidErrors.enabled
    @subscriber = nil

    # Unsubscribe any existing SolidErrors subscribers from boot
    unsubscribe_all_solid_errors_subscribers
  end

  def teardown
    Rails.error.unsubscribe(@subscriber) if @subscriber
    @config.solid_errors.enabled = @original_config_enabled
    SolidErrors.enabled = @original_module_enabled

    # Re-register subscriber if it was originally enabled
    if @original_module_enabled
      Rails.error.subscribe(SolidErrors::Subscriber.new)
    end
  end

  def test_subscriber_is_enabled_when_enabled_is_true
    @config.solid_errors.enabled = true

    run_subscriber_initializer

    assert solid_errors_subscriber, "Subscriber should be registered when enabled is true"
  end

  def test_subscriber_is_disabled_when_enabled_is_false
    @config.solid_errors.enabled = false

    run_subscriber_initializer

    refute solid_errors_subscriber, "Subscriber should not be registered when enabled is false"
  end

  private

  def run_subscriber_initializer
    config_initializer = SolidErrors::Engine.initializers.find { |i| i.name == "solid_errors.config" }
    SolidErrors::Engine.instance_exec(Rails.application, &config_initializer.block)

    subscriber_initializer = SolidErrors::Engine.initializers.find { |i| i.name == "solid_errors.active_record.error_subscriber" }
    SolidErrors::Engine.instance_exec(Rails.application, &subscriber_initializer.block)
  end

  def solid_errors_subscriber
    subscribers = Rails.error.instance_variable_get(:@subscribers)
    @subscriber = subscribers.find { |s| s.is_a?(SolidErrors::Subscriber) }
  end

  def unsubscribe_all_solid_errors_subscribers
    subscribers = Rails.error.instance_variable_get(:@subscribers)
    subscribers.select { |s| s.is_a?(SolidErrors::Subscriber) }.each do |s|
      Rails.error.unsubscribe(s)
    end
  end
end
