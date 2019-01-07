require 'sinatra'
require 'json'
require 'rest-client'
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
  test_run = scanner_test
  status 500
  if healthy?(client, test_run)
    status 200
  end

  content_type :json
  {
    started_at: client.start_time,
    worker_id: client.worker_id,
    healthcheck: healthy?(client, test_run),
    status: {
      started: client.started_tasks,
      completed: client.completed_tasks,
      failed: client.failed_tasks
    },
    engine: {
      connected_engine: client.camunda_url,
      last_successful_connection: client.last_connect
    },
    scanner: {
      version: ENV.fetch('ARACHNI_LONG_VERSION', 'unkown'),
      test_run: test_run ,
      has_errored: client.errored
    },
    build: {
      repository_url: client.repository_url,
      branch: client.branch,
      commit_id: client.commit_id
    }
  }.to_json
end

def healthy?(worker, test_run)
  test_run == "SUCCESSFUL"
end

def scanner_test
  begin
    response = RestClient::Request.execute(
        method: :get,
        url: 'http://127.0.0.1:7331/scans',
        timeout: 2
    )
    if response.code == 200
      "SUCCESSFUL"
    else
      "FAILED"
    end
  rescue
    "FAILED"
  end
end
