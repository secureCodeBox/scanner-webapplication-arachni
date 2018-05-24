# Ruby Arachni Client
require 'json'
require 'rest-client'

# 1 hour
# TASK_LOCK_DURATION = 3600000
#current 5 hours
#TASK_LOCK_DURATION = 18000000
#24 hours
TASK_LOCK_DURATION = 86400000


####### Definition of general Camunda Methods #######
def getnewtask
  RestClient.get $camundaurl + "?topicName=#{$scannerTopic}"
end

def countnewtasks
    $logger.debug "fetching task count"
    # count = RestClient.post($camundaurl + "/count", "{\"topicName\" : \"#{$scannerTopic}\", \"notLocked\" : true}",
    #                            :content_type => :'application/json', ){|response, request, result| response }
    request = create_post_request($camundaurl + '/count', '{"topicName": "' + $scannerTopic + '", "notLocked": true}')
    result = execute_http_request(request)
    if result != nil
    count = JSON.parse(result.to_str)['count']
    else
      count = -1
    end
    $logger.debug "counts: #{count}"
    count
end

def gettask(taskId)
  RestClient.get $camundaurl + "/#{taskId}"
end

def fetchAndLockTask
  $logger.debug "fetching task"
  fetch = "{\"workerId\":\"#{$workerId}\",\"maxTasks\": \"1\",\"topics\":[{\"topicName\": \"#{$scannerTopic}\",\"lockDuration\": #{TASK_LOCK_DURATION},  \"variables\": #{$variables}}]}"
  $logger.debug "fetching task payload: #{fetch}"
  # RestClient.post $camundaurl + "/fetchAndLock", fetch, {:content_type => :'application/json', :user => :'microservice', :password => $basic_auth_pw}
  request = create_post_request($camundaurl + "/fetchAndLock", fetch)
  result = execute_http_request(request)
  # $logger.debug "locked task: " + result.to_str
  result
end

def unlock_task_on_failure(task_id, error)
  payload = "{\"workerId\": \"#{$workerId}\",\"errorMessage\": \"#{error}\",\"retries\": 0,\"retryTimeout\": 60000}"
  failure = create_post_request($camundaurl + "/" + task_id + "/failure", payload)
  unlock = create_post_request($camundaurl + "/" + task_id + "/unlock", "")
  execute_http_request(failure)
  execute_http_request(unlock)
  $logger.debug "Unlocked task with error : " + error
end

def pass_report_to_camunda(camundaId, report)
  # RestClient.post $camundaurl + "/#{camundaId}/complete" , "{\"workerId\" : \"#{$workerId}\", \"variables\" : {\"report\" : {\"value\" : #{report.to_json}}}}", :content_type => :'application/json'
  payload = "{ \"workerId\": \"#$workerId\", \"variables\": {\"arachni_result_raw\": {\"value\": #{report} }, \"arachni_microservice_id\": {\"value\": \"#{$workerId}\"}, \"microservice\": {\"value\": \"arachni\"}}}"
  request = create_post_request($camundaurl + "/#{camundaId}/complete", payload)
  result = execute_http_request(request)
end

def completeTask(taskId)
  # RestClient.post $camundaurl + "/#{taskId}/complete" , "{\"workerId\" : \"#{$workerId}\"}", :content_type => :'application/json'
  request = create_post_request($camundaurl + "/#{taskId}/complete", "{\"workerId\" : \"#{$workerId}\"}")
  result = execute_http_request(request)
  $logger.debug "completed task: " + result.to_str
  result
end

def countworkertasks
  # count = RestClient.post $camundaurl + "/count", "{\"topicName\" : \"#{topic}\", \"locked\" : true, \"workerId\" : \"#{$workerId}\"}", :content_type => :'application/json'
  request = create_post_request($camundaurl + "/count", "{\"topicName\" : \"#{topic}\", \"locked\" : true, \"workerId\" : \"#{$workerId}\"}")
  result = execute_http_request(request)
  $logger.debug "count worker tasks: " + result.to_str
  JSON.parse(result)['count']
end

def getworkertasks
  # RestClient.post $camundaurl, "{\"topicName\" : \"#{topic}\", \"locked\" : true, \"workerId\" : \"#{$workerId}\"}", :content_type => :'application/json'
  request = create_post_request($camundaurl, "{\"topicName\" : \"#{topic}\", \"locked\" : true, \"workerId\" : \"#{$workerId}\"}")
  result = execute_http_request(request)
  $logger.debug "get worker tasks: " + result.to_str
  result
end


def execute_http_request(request)
  begin
    request.execute do |response, request, result|
      case response.code
        when 200
          $logger.debug 'success ' + response.code.to_s
          return response
        when 204
          $logger.debug 'success ' + response.code.to_s
          return ''
        else
          # $logger.debug request.inspect
          $logger.debug response.code
          # $logger.debug response.inspect
          $logger.error "Invalid response #{response.to_str} received."
          fail "Code #{response.code}: Invalid response #{response.to_str} received."
      end
    end
  rescue => e
    $logger.error "Error while connecting to #{$camundaurl}"
    $logger.debug e.message
    return nil
  end
end

def create_post_request(url, payload)
  if $basic_auth_pw != nil
    request = create_post_request_with_auth(url, payload)
  else
    request = create_post_request_without_auth(url, payload)
  end
end

#TODO set ssl verify true
def create_post_request_without_auth(url, payload)
  RestClient::Request.new({
                              method: :post,
                              url: url,
                              payload: payload,
                              headers: {:accept => :'application/json', content_type: :'application/json'},
                              :verify_ssl => false
                          })
end

def create_post_request_with_auth(url, payload)
  RestClient::Request.new({
                              method: :post,
                              url: url,
                              user: :'microservice',
                              password: $basic_auth_pw,
                              payload: payload,
                              headers: {:accept => :'application/json', content_type: :'application/json'},
                              :verify_ssl => false
                          })
end
