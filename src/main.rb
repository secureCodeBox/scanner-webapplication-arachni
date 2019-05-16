require 'sinatra'
require 'json'
require 'bundler'
Bundler.setup(:default)
require 'ruby-scanner-scaffolding'
require 'ruby-scanner-scaffolding/healthcheck'
require_relative "./arachni_worker"

set :port, 8080
set :bind, '0.0.0.0'
set :environment, :production

client = ArachniWorker.new(
    'http://localhost:8080',
    'arachni_webapplicationscan',
    ['PROCESS_TARGETS']
)

get '/status' do
  Healthcheck.new(client)
end
