class ArachniConfiguration
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
  attr_accessor :arachni_login_advanced_script_type
  attr_accessor :arachni_login_advanced_script
  attr_accessor :arachni_login_advanced_script_name
  attr_accessor :arachni_login_advanced_script_args
  attr_accessor :arachni_login_advanced_check_url
  attr_accessor :arachni_login_advanced_check_pattern

  def generate_payload
    {
        :url => self.arachni_scanner_target,
        :scope => {
            :dom_depth_limit => self.arachni_dom_depth_limit,
            :directory_depth_limit => self.arachni_dir_depth_limit,
            :page_limit => self.arachni_page_limit,
            :extend_paths => self.arachni_extend_paths
        },
        :http => {
          :cookie_string => self.arachni_cookie_string
        },
        :checks => '*',
        :audit => {
            :include_vector_patterns => self.arachni_include_patterns,
            :exclude_vector_patterns => self.arachni_exclude_patterns,
            :parameter_values => true,
            :links => true,
            :forms => true,
            :cookies => true,
            :jsons => true,
            :xmls => true,
            :ui_forms => true,
            :ui_inputs => true
        }
    }
  end
end
