# frozen_string_literal: true

# Specify Rack class to run
require './app/controllers/app'
run Calendar::Api.freeze.app