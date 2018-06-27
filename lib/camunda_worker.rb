require 'json'
require 'rest-client'
require 'securerandom'
require 'logger'

$logger = Logger.new(STDOUT)

if ENV.key? 'DEBUG'
  $logger.level = Logger::DEBUG
  STDOUT.sync = ENV['DEBUG']
else
  $logger.level = Logger::INFO
end

class CamundaWorker
  attr_reader :worker_id
  attr_reader :started_tasks
  attr_reader :completed_tasks
  attr_reader :failed_tasks
  attr_reader :camunda_url
  attr_reader :start_time
  attr_reader :last_connect
  attr_reader :repository_url
  attr_reader :branch
  attr_reader :commit_id

  def initialize(camunda_url, topic, variables, task_lock_duration = 3600000, poll_interval = 5)
    @camunda_url = ENV.fetch('ENGINE_ADDRESS', camunda_url)
    @topic, @variables, @task_lock_duration = topic, variables, task_lock_duration
    @worker_id = SecureRandom.uuid
    @started_tasks, @completed_tasks, @failed_tasks = 0, 0, 0
    @start_time = Time.now
    @last_connect = "ERROR"

    @protected_engine = (ENV.has_key? 'ENGINE_BASIC_AUTH_USER') and (ENV.has_key? 'ENGINE_BASIC_AUTH_PASSWORD')
    @basic_auth_user = ENV.fetch('ENGINE_BASIC_AUTH_USER', '')
    @basic_auth_password = ENV.fetch('ENGINE_BASIC_AUTH_PASSWORD', '')
    @repository_url = ENV.fetch('SCB_REPOSITORY_URL')
    @branch = ENV.fetch('SCB_BRANCH')
    @commit_id = ENV.fetch('SCB_COMMIT_ID')

    Thread.new do
      sleep poll_interval

      loop do
        begin
          $logger.debug('Getting new scans')
          tick
          $logger.debug("Sleeping for #{poll_interval}...")
        rescue => err
          $logger.warn err
        end

        sleep poll_interval
      end
    end
  end

  def tick
    task = fetch_and_lock_task
    unless task.nil?
      @started_tasks = @started_tasks.succ

      job_id = task.dig('jobId')
      targets = task.dig('targets')

      $logger.info "Started scan #{job_id}"

      begin
        result = self.work(job_id, targets)

        @completed_tasks = @completed_tasks.succ

        self.complete_task job_id, result

        $logger.info "Completed scan #{job_id}"
      rescue => err
        $logger.warn "Failed to perform scan #{job_id}"
        $logger.warn err
        $logger.warn err.backtrace
        $logger.warn "Task will be unlocked for further tries."
        @failed_tasks = @failed_tasks.succ

        self.fail_task job_id
      end
    end
  end

# @param [String] job_id
# @param [Array] targets
  def work(job_id, targets)
    $logger.error "You should override the work method of the CamundaWorker with a proper implementation!"
  end

  def fetch_and_lock_task
    $logger.debug "fetching task"
    begin
      res = self.http_post("#{@camunda_url}/box/jobs/lock/#{@topic}/#{@worker_id}", "")
      if res.nil?
        nil
      else
        JSON.parse(res)
      end
    rescue => e
      nil
    end
  end

  def fail_task(job_id)
    begin
      result = self.http_post("#{@camunda_url}/box/jobs/#{job_id}/failure", {
        errorDetails: "Failed to perform nikto scan",
        errorMessage: "",
        scannerId: @worker_id
      }.to_json)
      $logger.debug "unlocked task: " + result.to_str
      result
    rescue => e
      $logger.warn "Failed to submit failure for Job #{job_id} to the Engine."
      $logger.warn e
    end
  end

  def complete_task(job_id, payload)
    begin
      $logger.debug "completing task: #{payload.to_json}"

      result = self.http_post("#{@camunda_url}/box/jobs/#{job_id}/result", payload.to_json)
      $logger.debug "completed task: #{result.to_str}"
      result
    rescue => e
      $logger.warn "Failed to submit scan result for Job #{job_id} to the Engine."
    end
  end

  def http_post(url, payload = "")
    begin
      request = self.create_post_request(url, payload)

      request.execute do |response, request, result|
        case response.code
        when 200, 201
          $logger.debug 'success ' + response.code.to_s
          @last_connect = Time.now
          return response
        when 204
          $logger.debug 'success ' + response.code.to_s
          @last_connect = Time.now
          return nil
        else
          $logger.debug "Invalid response #{response.to_str} received."
          @last_connect = "ERROR"
          fail "Code #{response.code}: Invalid response #{response.to_str} received."
        end
      end
    rescue => e
      $logger.debug "Error while connecting to #{url}"
      $logger.debug e.message
      throw nil
    end
  end

  def create_post_request(url, payload)
    if @protected_engine
      RestClient::Request.new({
                    method: :post,
                    url: url,
                    user: @basic_auth_user,
                    password: @basic_auth_password,
                    payload: payload,
                    headers: {:accept => :'application/json', content_type: :'application/json'}
                  })
    else
      RestClient::Request.new({
                    method: :post,
                    url: url,
                    payload: payload,
                    headers: {:accept => :'application/json', content_type: :'application/json'}
                  })
    end
  end
end
