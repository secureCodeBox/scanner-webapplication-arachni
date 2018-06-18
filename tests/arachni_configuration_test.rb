require 'test/unit'
require_relative '../src/arachni_configuration'


class ArachniConfigurationTest < Test::Unit::TestCase

  def test_should_build_a_correct_payload_with_minimal_input
    target = {
        "location" => 'localhost.com',
        "name" => 'unused',
        "attributes" => {
            "ARACHNI_DOM_DEPTH_LIMIT" => 10,
            "ARACHNI_DIR_DEPTH_LIMIT" => 62,
            "ARACHNI_PAGE_LIMIT" => 22,
            "ARACHNI_INCLUDE_PATTERNS" => ['baz', 'bang', 'boom'],
            "ARACHNI_EXCLUDE_PATTERNS" => ['foo', 'bar'],
            "ARACHNI_SCAN_METHODS" => '', # Unused atm
            "ARACHNI_COOKIE_STRING" => 'foo=bar; bar=foo',
            "ARACHNI_EXTEND_PATH" => ['http://foobar.com', 'http://foobar.com/foo/bar'],
            "ARACHNI_LOGIN_URL" => '',
            "ARACHNI_LOGIN_CREDENTIALS" => '',
            "ARACHNI_LOGIN_CHECK" => '',
            "ARACHNI_LOGIN_SCRIPT_FILENAME" => ''
        }
    }
    config = ArachniConfiguration.from_target target

    assert_equal(
        config.generate_payload,
        {
            :url => 'localhost.com',
            :scope => {
                :dom_depth_limit => 10,
                :directory_depth_limit => 62,
                :page_limit => 22,
                :extend_paths => ['http://foobar.com', 'http://foobar.com/foo/bar'],
                :include_path_patterns => ['baz', 'bang', 'boom'],
                :exclude_path_patterns =>  ['foo', 'bar']
            },
            :http => {
                :cookie_string => 'foo=bar; bar=foo'
            },
            :checks => '*',
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
            :plugins => {}
        }
    )
  end

  def test_should_build_a_correct_payload_with_autologin_plugin
    target = {
        "location" => 'localhost.com',
        "name" => 'unused',
        "attributes" => {
            "ARACHNI_DOM_DEPTH_LIMIT" => 10,
            "ARACHNI_DIR_DEPTH_LIMIT" => 62,
            "ARACHNI_PAGE_LIMIT" => 22,
            "ARACHNI_INCLUDE_PATTERNS" => [],
            "ARACHNI_EXCLUDE_PATTERNS" => [],
            "ARACHNI_SCAN_METHODS" => '', # Unused atm
            "ARACHNI_COOKIE_STRING" => '',
            "ARACHNI_EXTEND_PATH" => [],
            "ARACHNI_LOGIN_URL" => 'http://foobar.com/login',
            "ARACHNI_LOGIN_CREDENTIALS" => 'username=simon&password=123456',
            "ARACHNI_LOGIN_CHECK" => 'Login Successful!',
            "ARACHNI_LOGIN_SCRIPT_FILENAME" => ''
        }
    }
    config = ArachniConfiguration.from_target target

    assert_equal(
        config.generate_payload,
        {
            :url => 'localhost.com',
            :scope => {
                :dom_depth_limit => 10,
                :directory_depth_limit => 62,
                :page_limit => 22,
                :extend_paths => [],
                :include_path_patterns => [],
                :exclude_path_patterns => []
            },
            :http => {
                :cookie_string => ''
            },
            :checks => '*',
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
            :plugins => {
                :autologin => {
                    :url => 'http://foobar.com/login',
                    :parameters => 'username=simon&password=123456',
                    :check => 'Login Successful!'
                }
            }
        }
    )
    end

  def test_should_build_a_correct_payload_with_login_script_plugin
    target = {
        "location" => 'localhost.com',
        "name" => 'unused',
        "attributes" => {
            "ARACHNI_DOM_DEPTH_LIMIT" => 10,
            "ARACHNI_DIR_DEPTH_LIMIT" => 62,
            "ARACHNI_PAGE_LIMIT" => 22,
            "ARACHNI_INCLUDE_PATTERNS" => [],
            "ARACHNI_EXCLUDE_PATTERNS" => [],
            "ARACHNI_SCAN_METHODS" => '', # Unused atm
            "ARACHNI_COOKIE_STRING" => '',
            "ARACHNI_EXTEND_PATH" => [],
            "ARACHNI_LOGIN_URL" => '',
            "ARACHNI_LOGIN_CREDENTIALS" => '',
            "ARACHNI_LOGIN_CHECK" => '',
            "ARACHNI_LOGIN_SCRIPT_FILENAME" => 'login.rb'
        }
    }
    config = ArachniConfiguration.from_target target

    assert_equal(
        config.generate_payload,
        {
            :url => 'localhost.com',
            :scope => {
                :dom_depth_limit => 10,
                :directory_depth_limit => 62,
                :page_limit => 22,
                :extend_paths => [],
                :include_path_patterns => [],
                :exclude_path_patterns => []
            },
            :http => {
                :cookie_string => ''
            },
            :checks => '*',
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
            :plugins => {
                :login_script => {
                    :script => '/securecodebox/scripts/login.rb'
                }
            }
        }
    )
  end
end