require 'sinatra'
require 'json'
require 'rest-client'
# require_relative "./nikto_worker"

set :port, 8080
set :bind, '0.0.0.0'
set :environment, :production

# client = NiktoWorker.new(
#     'http://localhost:8080',
#     'nikto_webserverscan',
#     ['PROCESS_TARGETS']
# )

get '/status' do

return scanner_test
  #
  # status 500
  # if (healthcheck(client.last_connect) == "UP")
  #   status 200
  # end
  #
  # content_type :json
  # {
  #   started_at: client.start_time,
  #   worker_id: client.worker_id,
  #   healthcheck: healthcheck(client.last_connect),
  #   status: {
  #     started: client.started_tasks,
  #     completed: client.completed_tasks,
  #     failed: client.failed_tasks
  #   },
  #   engine: {
  #     connected_engine: client.camunda_url,
  #     last_successful_connection: client.last_connect
  #   },
  #   scanner: {
  #     version: 'latest',
  #     test_run: scanner_test
  #   },
  #   build: {
  #     repository_url: client.repository_url,
  #     branch: client.branch,
  #     commit_id: client.commit_id
  #   }
  # }.to_json
end

def healthcheck(connection)
  if (connection != "ERROR" && scanner_test == "SUCCESSFULL")
    return "UP"
  end
    return "DOWN"
end

def scanner_test
  response = RestClient::Request.execute(
    method: :get,
    url: 'http://127.0.0.1:7331/scans',
    timeout: 10
  )
  if response.code == 200
    return "SUCCESSFULL"
  else
    return "FAILED"
  end
end
