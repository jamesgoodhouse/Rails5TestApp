# sinatra.rb
require_relative 'bundle/bundler/setup'
require 'sinatra'

get '/' do
  'Hello world!'
end
