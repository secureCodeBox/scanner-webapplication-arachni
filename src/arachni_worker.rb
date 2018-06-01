require 'json'

require_relative "../lib/camunda_worker"

require_relative "./arachni_scan"
require_relative "./arachni_configuration"

class ArachniWorker < CamundaWorker
  def work(job_id, targets)
    configs = targets.map {|target|
      config = ArachniConfiguration.new

      config.arachni_scanner_target = target.dig('location')

      config.arachni_dom_depth_limit = target.dig('attributes', 'ARACHNI_DOM_DEPTH_LIMIT')
      config.arachni_dir_depth_limit = target.dig('attributes', 'ARACHNI_DIR_DEPTH_LIMIT')
      config.arachni_page_limit = target.dig('attributes', 'ARACHNI_PAGE_LIMIT')
      config.arachni_exclude_patterns = target.dig('attributes', 'ARACHNI_EXCLUDE_PATTERNS')
      config.arachni_include_patterns = target.dig('attributes', 'ARACHNI_INCLUDE_PATTERNS')
      config.arachni_scan_methods = target.dig('attributes', 'ARACHNI_SCAN_METHODS')
      config.arachni_authentication = target.dig('attributes', 'ARACHNI_AUTHENTICATION')
      config.arachni_cookie_string = target.dig('attributes', 'ARACHNI_COOKIE_STRING')
      config.arachni_login_url = target.dig('attributes', 'ARACHNI_LOGIN_URL')
      config.arachni_login_credentials = target.dig('attributes', 'ARACHNI_LOGIN_CREDENTIALS')
      config.arachni_login_check = target.dig('attributes', 'ARACHNI_LOGIN_CHECK')
      config.arachni_login_advanced_script_type = target.dig('attributes', 'ARACHNI_LOGIN_ADVANCED_SCRIPT_TYPE')
      config.arachni_login_advanced_script = target.dig('attributes', 'ARACHNI_LOGIN_ADVANCED_SCRIPT')
      config.arachni_login_advanced_script_name = target.dig('attributes', 'ARACHNI_LOGIN_ADVANCED_SCRIPT_NAME')
      config.arachni_login_advanced_script_args = target.dig('attributes', 'ARACHNI_LOGIN_ADVANCED_SCRIPT_ARGS')
      config.arachni_login_advanced_check_url = target.dig('attributes', 'ARACHNI_LOGIN_ADVANCED_CHECK_URL')
      config.arachni_login_advanced_check_pattern = target.dig('attributes', 'ARACHNI_LOGIN_ADVANCED_CHECK_PATTERN')

      config
    }

    scans = configs.map { |config|
      scan = ArachniScan.new(job_id, config)
      scan.start
      scan
    }

    {
        findings: scans.flat_map{|scan| scan.results},
        rawFindings: scans.map{|scan| scan.raw_results.to_s}.join(','),
        scannerId: @worker_id.to_s,
        scannerType: 'arachni'
    }
  end
end
