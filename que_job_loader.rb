# frozen_string_literal: true

# Load the application for the Que CLI job server
# This gets loaded by the command: bundle exec que ./que_job_loader.rb

ENV['RACK_ENV'] ||= 'production'
require 'bundler'
Bundler.require(:default, ENV.fetch('RACK_ENV', 'development'))

require_relative 'config/environment'

# require 'base64'
# require 'pstore'
require './config/app_const'
require './lib/types_for_dry'
require './lib/crossbeams_responses'
require './lib/base_que_job'
require './lib/base_repo'
require './lib/base_repo_association_finder'
require './lib/base_interactor'
require './lib/base_service'
# require './lib/base_step'
require './lib/document_sequence'
# require './lib/local_store' # Will only work for processes running from one dir.
require './lib/ui_rules'
require './lib/library_versions'
# require './lib/dataminer_connections'
Dir['./helpers/**/*.rb'].each { |f| require f }
Dir['./lib/applets/*.rb'].each { |f| require f }

ENV['ROOT'] = File.dirname(__FILE__)
ENV['VERSION'] = File.read('VERSION')
ENV['GRID_QUERIES_LOCATION'] ||= File.expand_path('grid_definitions/dataminer_queries', __dir__)

# DM_CONNECTIONS = DataminerConnections.new

module Crossbeams
  class FrameworkError < StandardError
  end

  class AuthorizationError < StandardError
  end

  class TaskNotPermittedError < StandardError
  end
end
