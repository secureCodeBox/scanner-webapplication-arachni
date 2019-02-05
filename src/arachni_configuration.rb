require('pathname')

def is_set(val)
  if val.nil?
    false
  elsif val.is_a?(String)
    val != ''
  elsif val.is_a?(Array)
    val.length != 0
  end
end

class ArachniConfiguration
  attr_accessor :job_id

  attr_accessor :scripts_directory

  attr_accessor :arachni_scanner_target
  attr_accessor :arachni_dom_depth_limit
  attr_accessor :arachni_dir_depth_limit
  attr_accessor :arachni_page_limit
  attr_accessor :arachni_exclude_patterns
  attr_accessor :arachni_include_patterns
  attr_accessor :arachni_scan_methods
  attr_accessor :arachni_authentication
  attr_accessor :arachni_cookie_string
  attr_accessor :arachni_extend_paths
  attr_accessor :arachni_login_url
  attr_accessor :arachni_login_credentials
  attr_accessor :arachni_login_check
  attr_accessor :arachni_login_script_filename
  attr_accessor :arachni_requests_per_second
  attr_accessor :arachni_pool_size
  attr_accessor :arachni_request_concurrency
  attr_accessor :arachni_login_script_args

  def self.from_target(job_id, target, scripts_directory = "/securecodebox/static/")
    config = ArachniConfiguration.new

    config.scripts_directory = scripts_directory

    config.job_id = job_id
    config.arachni_scanner_target = target.dig('location')

    config.arachni_dom_depth_limit = target.dig('attributes', 'ARACHNI_DOM_DEPTH_LIMIT')
    config.arachni_dir_depth_limit = target.dig('attributes', 'ARACHNI_DIR_DEPTH_LIMIT')
    config.arachni_page_limit = target.dig('attributes', 'ARACHNI_PAGE_LIMIT')
    config.arachni_exclude_patterns = target.dig('attributes', 'ARACHNI_EXCLUDE_PATTERNS')
    config.arachni_include_patterns = target.dig('attributes', 'ARACHNI_INCLUDE_PATTERNS')
    config.arachni_scan_methods = target.dig('attributes', 'ARACHNI_SCAN_METHODS')
    config.arachni_authentication = target.dig('attributes', 'ARACHNI_AUTHENTICATION')
    config.arachni_cookie_string = target.dig('attributes', 'ARACHNI_COOKIE_STRING')
    config.arachni_extend_paths = target.dig('attributes', 'ARACHNI_EXTEND_PATH')

    config.arachni_login_url = target.dig('attributes', 'ARACHNI_LOGIN_URL')
    config.arachni_login_credentials = target.dig('attributes', 'ARACHNI_LOGIN_CREDENTIALS')
    config.arachni_login_check = target.dig('attributes', 'ARACHNI_LOGIN_CHECK')

    config.arachni_login_script_filename = target.dig('attributes', 'ARACHNI_LOGIN_SCRIPT_FILENAME')
    config.arachni_login_script_args = target.dig('attributes', 'ARACHNI_LOGIN_SCRIPT_ARGS')
    config.arachni_requests_per_second = target.dig('attributes', 'ARACHNI_REQUESTS_PER_SECOND')
    config.arachni_pool_size = target.dig('attributes','ARACHNI_POOL_SIZE')
    config.arachni_request_concurrency = target.dig('attributes','ARACHNI_REQUEST_CONCURRENCY')


    config
  end

  def generate_payload
    plugins = {}

    if is_set(self.arachni_login_url) or is_set(self.arachni_login_credentials) or is_set(self.arachni_login_check)
      plugins[:autologin] = {
          :url => self.arachni_login_url,
          :parameters => self.arachni_login_credentials,
          :check => self.arachni_login_check
      }
    elsif is_set(self.arachni_login_script_filename)
      # Load script from the script templates directory and copy the edited static to the tmp directory
      script_file = Pathname.new(self.arachni_login_script_filename)

      template_path = "#{self.scripts_directory}#{script_file.basename}"

      template = ""
      File.open(template_path, 'r'){ |file| template = file.read }

      unless self.arachni_login_script_args.nil?
        self.arachni_login_script_args.each {
            |k,v|
          template.gsub! "${#{k}}", v
        }
      end

      File.open(self.file_path, 'w') { |file| file.write(template) }

      plugins[:login_script] = {
          :script => self.file_path
      }
    end

    unless is_set(self.arachni_scan_methods) or self.arachni_scan_methods != ""
      self.arachni_scan_methods = "*"
    end

    plugins[:rate_limiter] = {
        :requests_per_second => self.arachni_requests_per_second
    }

    {
        :url => self.arachni_scanner_target,
        :browser_cluster => {
          :pool_size => self.arachni_pool_size
        },
        :scope => {
            :dom_depth_limit => self.arachni_dom_depth_limit,
            :directory_depth_limit => self.arachni_dir_depth_limit,
            :page_limit => self.arachni_page_limit,
            :extend_paths => self.arachni_extend_paths,
            :include_path_patterns => self.arachni_include_patterns,
            :exclude_path_patterns => self.arachni_exclude_patterns,
        },
        :http => {
          :cookie_string => self.arachni_cookie_string,
          :request_concurrency => self.arachni_request_concurrency
        },
        :checks => self.arachni_scan_methods,
        :audit => {
            :parameter_values => true,
            :links => true,
            :forms => true,
            :cookies => true,
            :jsons => true,
            :xmls => true,
            :ui_forms => true,
            :ui_inputs => true
        },
        :plugins => plugins
    }
  end

  def file_path
    template_file = Pathname.new(self.arachni_login_script_filename)

    "/tmp/#{self.job_id}#{template_file.extname}"
  end
end
