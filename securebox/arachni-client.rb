# Ruby Arachni Client
require 'json'
require 'rest-client'
require 'logger'
require 'sinatra'
require 'securerandom'
require 'active_support'
require 'active_support/core_ext'

#debug setting, turn off for production
STDOUT.sync = true
$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG

#install pry for debugging
# require 'pry'
# Place the next line to debug at that point
# binding.pry
require_relative './camunda-client.rb'
require_relative './shell-executor.rb'
require_relative './util.rb'
require_relative './credentials-service.rb'
require_relative './scan.rb'

set :port, 8080
set :bind, '0.0.0.0'
set :environment, :development

$logger.info("Starting up Arachni Client...")


@credential_service = CredentialsService.instance

####### Definition of Variables #######



$camundaurl = "http://secureboxengine:8080/engine-rest/external-task"
if ENV.has_key? 'ENGINE_ADDRESS'
  $camundaurl = ENV['ENGINE_ADDRESS']
end
$logger.info("SecureBox Engine Address: #{$camundaurl}")

# use the hard-coded IP for shorter roundtrips during testing
# $camundaurl = "http://192.168.99.101:80/engine-rest/external-task"
# $camundaurl = "https://172.20.0.1:8080/engine-rest/external-task"

$maxscans = 3

$workerId = 'securebox.arachni.' + SecureRandom.uuid
$scannerTopic = "arachni_vulnerabilityscan"
$runningscans = 0
$mapping = JSON.parse("{}")
# $variables = '["arachniScannerTarget" , "scanmethods"]'
$variables = '["arachni_scanner_target",
               "arachni_dom_depth_limit",
               "arachni_dir_depth_limit",
               "arachni_page_limit",
               "arachni_exclude_patterns",
               "arachni_include_patterns",
               "arachni_scan_methods",
               "arachni_authentication",
               "arachni_cookie_string",
               "arachni_login_url",
               "arachni_login_credentials",
               "arachni_login_check",
               "arachni_login_advanced_script_type",
               "arachni_login_advanced_script",
               "arachni_login_advanced_script_name",
               "arachni_login_advanced_script_args",
               "arachni_login_advanced_check_url",
               "arachni_login_advanced_check_pattern"]'

# for secured camunda engine
$basic_auth_pw = @credential_service.get_microservice_pw
# $basic_auth_pw =

$active_scans = Hash.new
$active_reporting = Hash.new

####### Definition of specific Camunda Methods #######

#transfers the camundarachniId and arachniId to the camunda task
def setscannerid(cId, aId)
  $mapping = $mapping.merge(JSON.parse("{\"#{aId}\" : \"#{cId}\"}"))
  $logger.debug("current mapping #{$mapping.to_s}")
end

def log_exception e
  $logger.error e.inspect
  $logger.error e.backtrace
end

####### Definition of specific Arachni Methods #######
# TODO enable usage of scan snapshots to ensure results even during a crash
#      usage : --snapshot-save-path PATH
# TODO create resume function using snapshots
#      usage :     You can use the generated file to resume the scan with the 'arachni_restore' executable.

def start_new_scan(task_id, variables)
  $logger.debug "starting new scan #{task_id}"

  begin
    scan = Scan.new(task_id, variables)
    $active_scans[task_id] = scan

    scan.start_scan

  rescue => e
    err = "error starting scan with id #{task_id}"
    $logger.error err
    unlock_task_on_failure(id, err)
    $logger.debug e.inspect
  end

end


# New tasks are obtained from Camunda if available and started
def getnewscans
  if countnewtasks > 0
    begin
      $logger.info 'locking new task'
      tasks = fetchAndLockTask
      if tasks == '[]' || tasks == nil
        $logger.debug 'task response empty or error occurred'
        return
      end
    rescue => e
      err = "scan with id #{id} cannot be fetched from camunda"
      $logger.error err
      unlock_task_on_failure(id, err)
      $logger.debug e.inspect
    end
    # $logger.debug "#{tasks}"


    parsed_tasks = JSON.parse(tasks)
    taskId = parsed_tasks[0]['id']
    $logger.debug "#{parsed_tasks}"
    $logger.debug "taskId: #{taskId}"


    $parsed_task_vars = parsed_tasks[0]['variables']

    start_new_scan(taskId, $parsed_task_vars)
  end
end

def complete_task(camundaId, report)
  $logger.debug "================================================ inserting report =========================================="
  pass_report_to_camunda(camundaId, report)
end

def log_error_and_unlock_task(err, id)
  $logger.error err
  unlock_task_on_failure(id, err)
  $active_scans.delete(id)
end

def check_running_jobs
  $logger.debug "#{$active_scans.length} jobs currently running"
  $active_scans.each do |id, scan|
    $logger.debug "checking scan #{id}"
    begin
      if scan.is_scanning
        $logger.debug "job #{id} is still scanning"
      elsif !scan.scan_exit_success
        err = "scan with id #{id} stopped scanning with exit code : #{scan.get_exit_code}"
        log_error_and_unlock_task id, err
        scan.clean_up
        raise
      elsif scan.scan_exit_success and !scan.reporting_started
        $logger.debug "scan #{id} finished scanning"
        scan.start_reporting
      end

      if scan.scan_finished
        if scan.is_reporting
          $logger.debug "job #{id} is still reporting"
        elsif !scan.report_exit_success
          err = "checking for report of scan #{id} failed with exit code : #{scan.get_exit_code}"
          log_error_and_unlock_task id, err
          scan.clean_up
          raise
        elsif scan.report_exit_success
          $logger.debug "scan #{id} finished reporting"

          complete_task(id, scan.get_report)
          scan.clean_up
          $active_scans.delete(id)
        end
      end
    rescue => e
      err = "error during job #{id}"
      $logger.debug err
      $logger.error e.backtrace
      unlock_task_on_failure(id, err)
      $logger.debug e.inspect
      scan.clean_up

    end
  end
end




def getServiceStatus(url)
  begin
    req = RestClient::Request.new(method: :get, url: url, timeout: 5)
    $logger.debug("trying to reach : " + url)
    req.execute do |response, request, result|
      response.code.to_s
      "UP"
    end
  rescue => e
    "DOWN"
  end
end

####### Definition of Actions #######
Thread.new do
  sleep 5
  loop do
    $logger.debug("Getting new scans from " + $camundaurl)
    if $active_scans.length < $maxscans
      getnewscans
    end
    check_running_jobs

    $logger.debug("Sleeping for 20s...")
    sleep 20
  end
end

####### Definition of Sinatra Interface #######

get '/' do
  "Arachni-Client is started!"
end

get '/id' do
  $workerId
end

get '/internal/health' do
  $workerId
end

#checking availability of camunda from within the Container
get '/status' do
  camStatus = getServiceStatus($camundaurl)
  if camStatus == 'UP'
    JSON.generate(JSON.parse("{\"Overall Status\":\"UP\", \"Camunda Status\":\"#{camStatus}\"}"))
    status 200
  else
    JSON.generate(JSON.parse("{\"Overall Status\":\"DOWN\", \"Camunda Status\":\"#{camStatus}\"}"))
    status 500
  end
end
