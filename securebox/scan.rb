require 'active_support'
require 'active_support/core_ext'
require 'json'


require_relative './shell-executor.rb'
require_relative './util.rb'
require_relative './constants.rb'

class Scan

  @task_id
  @variables_raw

  @target

  @checks

  @dom_depth_limit

  @directory_depth_limit

  @page_limit

  @exclude_patterns

  @include_patterns

  @cookie_string

  @login_basic_url

  @login_basic_credentials

  @login_basic_check

  @login_advanced_script_name

  @login_advanced_script_args

  @login_advanced_check_url

  @login_advanced_script_raw

  @login_advanced_script_type

  @login_advanced_check_pattern

  @login_script_file_path

  @shell_command

  @scan_process

  @reporting_process

  def initialize(task_id, variables)
    @task_id = task_id
    @variables_raw = variables
  end


  private def extract_task_variables(variables)
    @target = variables['arachni_scanner_target']['value']


    @dom_depth_limit = variables.dig('arachni_dom_depth_limit', 'value')

    @directory_depth_limit = variables.dig('arachni_dir_depth_limit', 'value')

    @page_limit = variables.dig('arachni_page_limit', 'value')



    @exclude_patterns = variables.dig('arachni_exclude_patterns', 'value')


    @include_patterns = variables.dig('arachni_include_patterns', 'value')


    @checks = variables.dig('arachni_scan_methods', 'value')


    @login_basic_url = variables.dig('arachni_login_url', 'value')


    @login_basic_credentials = variables.dig('arachni_login_credentials', 'value')

    @login_basic_check = variables.dig('arachni_login_check', 'value')


    @login_advanced_script_type = variables.dig('arachni_login_advanced_script_type', 'value')


    @login_advanced_script_raw = variables.dig('arachni_login_advanced_script', 'value')

    @login_advanced_script_name = variables.dig('arachni_login_advanced_script_name', 'value')

    @login_advanced_script_args = variables.dig('arachni_login_advanced_script_args', 'value')

    @login_advanced_check_url = variables.dig('arachni_login_advanced_check_url', 'value')

    @login_advanced_check_pattern = variables.dig('arachni_login_advanced_check_pattern', 'value')

    @cookie_string = variables.dig('arachni_cookie_string', 'value')

  end

  private def prepare_authentication
    auth_string = ''

    if @login_basic_url.present?
      auth_string += "--plugin=autologin:url=\"#{@login_basic_url}\",parameters=\"#{@login_basic_credentials}\",check=\"#{@login_basic_check}\" "
    elsif @login_advanced_script_raw.present?
      file_type = @login_advanced_script_type === 'ruby' ? 'rb' : 'js'

      file_path = "/sectools/#{id}-login.#{file_type}"
      begin
        file = File.open(file_path, 'w')
        file.write(@login_advanced_script_raw)
      rescue IOError => e
        $logger.error 'Cant write to File! IO Error!'
        $logger.debug e.inspect
      rescue => e
        $logger.error 'Unexpected Error while trying to write the login script file'
        $logger.debug e.inspect
      ensure
        file.close unless file.nil?
      end
      auth_string += "--plugin=login_script:script=#{file_path} --session-check-url=\"#{@login_advanced_check_url}\" --session-check-pattern=\"#{@login_advanced_check_pattern}\" "
      @login_script_file_path = file_path

    elsif @login_advanced_script_name.present?

      file_path = create_final_script_from_args(@task_id, @login_advanced_script_name, @login_advanced_script_args)
      auth_string += "--plugin=login_script:script=#{file_path} --session-check-url=\"#{@login_advanced_check_url}\" --session-check-pattern=\"#{@login_advanced_check_pattern}\" "
      @login_script_file_path = file_path

    end
    auth_string
  end

  private def create_final_script_from_args(id, login_advanced_script_name, script_args)
    template_path = "/sectools/scripts/#{login_advanced_script_name}"

    file = File.open(template_path, 'r')
    contents = file.read

    arg_map = JSON.parse(script_args)
    arg_map.each {
        |k,v|
      contents.gsub! "${#{k}}", v
    }

    file_path = "/sectools/scripts/#{id}#{File.extname(template_path)}"

    File.open(file_path, 'w') { |file| file.write(contents) }

    file_path
  end


  private def generate_shell_command
    cmd = "#{Constants::ARACHNI_BIN}arachni #{@target} --report-save-path=#{Constants::AFR_FILE_NAME_BASE}#{@task_id}.afr --scope-auto-redundant=2 "

    unless ENV['DEBUG']
      cmd += "--output-only-positives "
    end

    if @checks.present?
      cmd += "--checks=#{@checks} "
    end

    if @dom_depth_limit.present?
      cmd += "--scope-dom-depth-limit #{@dom_depth_limit} "
    end
    if @directory_depth_limit.present?
      cmd += "--scope-directory-depth-limit #{@directory_depth_limit} "
    end
    if @page_limit.present?
      cmd += "--scope-page-limit #{@page_limit} "
    end
    if @exclude_patterns.present?
      @exclude_patterns.split(",").each do |exc|
        cmd += "--scope-exclude-pattern " + exc + " "
      end
    end
    if @cookie_string.present?
      cmd += "--http-cookie-string='#{@cookie_string}' "
    end

    if @include_patterns.present?
      @include_patterns.split(",").each do |inc|
        cmd += "--scope-include-pattern " + inc + " "
      end
    end

    cmd += prepare_authentication

    @shell_command = cmd
  end

  def start_scan
    extract_task_variables(@variables_raw)
    generate_shell_command


    @scan_process = ShellExecutor.new
    @scan_process.execute_shell_async(@shell_command)
    $logger.debug "scan started with id: #{@task_id}"

  end

  def start_reporting
    @reporting_process = ShellExecutor.new
    @reporting_process.execute_shell_async("#{Constants::ARACHNI_BIN}arachni_reporter #{Constants::AFR_FILE_NAME_BASE}#{@task_id}.afr --reporter=json:outfile=#{Constants::AFR_FILE_NAME_BASE}#{@task_id}.json")
  end

  def is_scanning
    @scan_process != nil && @scan_process.is_running
  end

  def scan_exit_success
    @scan_process.get_exit_code == 0
  end

  def scan_finished
    @scan_process != nil && !@scan_process.is_running
  end

  def reporting_started
    @reporting_process != nil
  end

  def is_reporting
    @reporting_process != nil && @reporting_process.is_running
  end

  def report_exit_success
    @reporting_process.get_exit_code == 0
  end

  def get_report
    read_file_into_var("#{Constants::AFR_FILE_NAME_BASE}#{@task_id}.json")
  end


  def clean_up
    Dir.glob("/sectools/scripts/#{@task_id}*").each { |file| File.delete(file)}
    File.delete("#{Constants::AFR_FILE_NAME_BASE}#{@task_id}.afr") if File.exist?("#{Constants::AFR_FILE_NAME_BASE}#{@task_id}.afr")
    File.delete("#{Constants::AFR_FILE_NAME_BASE}#{@task_id}.json") if File.exist?("#{Constants::AFR_FILE_NAME_BASE}#{@task_id}.json")

  end

end
