ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require_relative '../app'

class TestHelper
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
end
