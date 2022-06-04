#!/usr/bin/env ruby

=begin

Run benchmarks against multiple versions of Rails:

  WITHOUT_LOGGER=1 RAILS_VERSION=6.0.5 ./benchmark_render.rb \
  && WITHOUT_LOGGER=1 RAILS_VERSION=7.0.3 ./benchmark_render.rb \
  && WITHOUT_LOGGER=1 ./benchmark_render.rb

=end

require "bundler/inline"

ENV['BUNDLE_PATH'] = "vendor/bundle"
VERBOSE = !!ENV.fetch('VERBOSE', false)

gemfile(VERBOSE) do
  source 'https://rubygems.org'
  gem 'stackprof'
  gem 'view_component'
  gem 'benchmark-ips'
  gem 'rails', ENV.fetch("RAILS_VERSION", { github: 'rails/rails' })
end

puts "Rails version: #{Rails.version}"
ENV['RAILS_ENV'] = 'production'
ENV['SECRET_KEY_BASE'] = 'f5eaada46ba1670954c05119a97ce018afedbbaa78b09d9c1833ed4d2c63ea6f7caefd91b010627563b9ff8771f582e711c24e6958f160b753e316264f287f6c'
require 'stackprof'
require 'benchmark/ips'
require 'view_component/engine'

require "rails"
# require 'active_record/railtie'
# require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_view/railtie'
# require 'action_mailer/railtie'
# require 'active_job/railtie'
# require 'action_cable/engine'
# require 'action_mailbox/engine'
# require 'action_text/engine'
# require 'rails/test_unit/railtie'
#

class RailsApplication < Rails::Application
  config.eager_load = true
  config.cache_classes = true

  routes.append do
    resource :page, only: [] do
      get :inline
      get :nested_loop
      get :nested_loop_path
      get :nested_collection
      get :vc_loop
    end
  end
end

class PagesController < ActionController::Base
  prepend_view_path 'views'

  def inline
  end

  def nested_loop
  end

  def nested_loop_path
  end

  def nested_collection
  end

  def vc_loop
  end
end

class EggComponent < ViewComponent::Base
end

RailsApplication.initialize!

app = Rack::Builder.new_from_string("run Rails.application")

ActionView::Base.logger = nil if ENV['WITHOUT_LOGGER']
# ActiveSupport::Notifications.unsubscribe 'render_partial.action_view'

make_request = -> (path) {
  env = Rack::MockRequest.env_for("http://localhost/#{path}")
  env["HTTP_HOST"] = "localhost"
  env["REMOTE_ADDR"] = "127.0.0.1"

  status, headers, body = app.call(env.dup)
  s = []
  body.each { |x| s << x }
  body.close if body.respond_to?(:close)
  raise unless status == 200
  [status, headers, s.join("")]
}

if VERBOSE
  p make_request.call("page/inline").last
  p make_request.call("page/nested_loop").last
  p make_request.call("page/nested_loop_path").last
  p make_request.call("page/nested_collection").last
  p make_request.call("page/vc_loop").last
end

Benchmark.ips do |x|
  x.report "/inline" do
    make_request.call("page/inline")
  end

  x.report "/nested_loop" do
    make_request.call("page/nested_loop")
  end

  x.report "/nested_loop_path" do
    make_request.call("page/nested_loop_path")
  end

  x.report "/nested_collection" do
    make_request.call("page/nested_collection")
  end

  x.report "/vc_loop" do
    make_request.call("page/vc_loop")
  end

  x.compare!
end

