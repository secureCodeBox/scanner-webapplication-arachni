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
            "ARACHNI_COOKIE_STRING" => 'foo=bar; bar=foo',
            "ARACHNI_EXTEND_PATH" => ['http://foobar.com', 'http://foobar.com/foo/bar'],
            "ARACHNI_LOGIN_URL" => '',
            "ARACHNI_LOGIN_CREDENTIALS" => '',
            "ARACHNI_LOGIN_SCRIPT_FILENAME" => '',
            "ARACHNI_REQUESTS_PER_SECOND" => 20,
            "ARACHNI_POOL_SIZE" => 6,
            "ARACHNI_REQUEST_CONCURRENCY" => 20,
            "ARACHNI_LOGIN_CHECK" => ''
        }
    }
    config = ArachniConfiguration.from_target "49bf7fd3-8512-4d73-a28f-608e493cd726", target

    assert_equal(
        config.generate_payload,
        {
            :url => 'localhost.com',
            :browser_cluster => {
                :pool_size => 6
            },
            :scope => {
                :dom_depth_limit => 10,
                :directory_depth_limit => 62,
                :page_limit => 22,
                :extend_paths => ['http://foobar.com', 'http://foobar.com/foo/bar'],
                :include_path_patterns => ['baz', 'bang', 'boom'],
                :exclude_path_patterns => ['foo', 'bar']
            },
            :http => {
                :cookie_string => 'foo=bar; bar=foo',
                :request_concurrency => 20
            },
            :checks => ['*'],
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
                :rate_limiter => {
                    :requests_per_second => 20
                }
            }
        }
    )
  end
  
  def test_should_include_attack_methods_if_configured
    target = {
        "location" => 'localhost.com',
        "name" => 'unused',
        "attributes" => {
            "ARACHNI_DOM_DEPTH_LIMIT" => 10,
            "ARACHNI_DIR_DEPTH_LIMIT" => 62,
            "ARACHNI_PAGE_LIMIT" => 22,
            "ARACHNI_INCLUDE_PATTERNS" => ['baz', 'bang', 'boom'],
            "ARACHNI_EXCLUDE_PATTERNS" => ['foo', 'bar'],
            "ARACHNI_SCAN_METHODS" => [
                'xss',
                'xss_path',
                'xss_tag',
                'xss_script_context',
                'xss_event',
                'xss_dom',
                'xss_dom_script_context'
            ],
            "ARACHNI_COOKIE_STRING" => 'foo=bar; bar=foo',
            "ARACHNI_EXTEND_PATH" => ['http://foobar.com', 'http://foobar.com/foo/bar'],
            "ARACHNI_LOGIN_URL" => '',
            "ARACHNI_LOGIN_CREDENTIALS" => '',
            "ARACHNI_LOGIN_SCRIPT_FILENAME" => '',
            "ARACHNI_REQUESTS_PER_SECOND" => 20,
            "ARACHNI_POOL_SIZE" => 6,
            "ARACHNI_REQUEST_CONCURRENCY" => 20,
            "ARACHNI_LOGIN_CHECK" => ''
        }
    }
    config = ArachniConfiguration.from_target "49bf7fd3-8512-4d73-a28f-608e493cd726", target

    assert_equal(
        config.generate_payload,
        {
            :url => 'localhost.com',
            :browser_cluster => {
                :pool_size => 6
            },
            :scope => {
                :dom_depth_limit => 10,
                :directory_depth_limit => 62,
                :page_limit => 22,
                :extend_paths => ['http://foobar.com', 'http://foobar.com/foo/bar'],
                :include_path_patterns => ['baz', 'bang', 'boom'],
                :exclude_path_patterns => ['foo', 'bar']
            },
            :http => {
                :cookie_string => 'foo=bar; bar=foo',
                :request_concurrency => 20
            },
            :checks => [
                'xss',
                'xss_path',
                'xss_tag',
                'xss_script_context',
                'xss_event',
                'xss_dom',
                'xss_dom_script_context'
            ],
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
                :rate_limiter => {
                    :requests_per_second => 20
                }
            }
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
            "ARACHNI_SCAN_METHODS" => [],
            "ARACHNI_COOKIE_STRING" => '',
            "ARACHNI_EXTEND_PATH" => [],
            "ARACHNI_LOGIN_URL" => 'http://foobar.com/login',
            "ARACHNI_LOGIN_CREDENTIALS" => 'username=simon&password=123456',
            "ARACHNI_LOGIN_CHECK" => 'Login Successful!',
            "ARACHNI_LOGIN_SCRIPT_FILENAME" => '',
            "ARACHNI_REQUESTS_PER_SECOND" => 20,
            "ARACHNI_POOL_SIZE" => 6,
            "ARACHNI_REQUEST_CONCURRENCY" => 20
        }
    }
    config = ArachniConfiguration.from_target "49bf7fd3-8512-4d73-a28f-608e493cd726", target

    assert_equal(
        config.generate_payload,
        {
            :url => 'localhost.com',
            :browser_cluster => {
                :pool_size => 6
            },
            :scope => {
                :dom_depth_limit => 10,
                :directory_depth_limit => 62,
                :page_limit => 22,
                :extend_paths => [],
                :include_path_patterns => [],
                :exclude_path_patterns => []
            },
            :http => {
                :cookie_string => '',
                :request_concurrency => 20
            },
            :checks => ['*'],
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
                },
                :rate_limiter => {
                    :requests_per_second => 20
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
            "ARACHNI_SCAN_METHODS" => [],
            "ARACHNI_COOKIE_STRING" => '',
            "ARACHNI_EXTEND_PATH" => [],
            "ARACHNI_LOGIN_URL" => '',
            "ARACHNI_LOGIN_CREDENTIALS" => '',
            "ARACHNI_LOGIN_CHECK" => '',
            "ARACHNI_REQUESTS_PER_SECOND" => 20,
            "ARACHNI_POOL_SIZE" => 6,
            "ARACHNI_REQUEST_CONCURRENCY" => 20,
            "ARACHNI_LOGIN_SCRIPT_FILENAME" => 'login.js',
            "ARACHNI_LOGIN_SCRIPT_ARGS" => {
                "FOO_BAR" => 'something'
            }
        }
    }
    scripts_dir = Pathname.new(__FILE__).join("../static/")

    config = ArachniConfiguration.from_target "49bf7fd3-8512-4d73-a28f-608e493cd726", target, scripts_dir

    assert_equal(
        config.generate_payload,
        {
            :url => 'localhost.com',
            :browser_cluster => {
                :pool_size => 6
            },
            :scope => {
                :dom_depth_limit => 10,
                :directory_depth_limit => 62,
                :page_limit => 22,
                :extend_paths => [],
                :include_path_patterns => [],
                :exclude_path_patterns => []
            },
            :http => {
                :cookie_string => '',
                :request_concurrency => 20
            },
            :checks => ['*'],
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
                    :script => '/tmp/49bf7fd3-8512-4d73-a28f-608e493cd726.js'
                },
                :rate_limiter => {
                    :requests_per_second => 20
                }
            }
        }
    )

    actual_file_contents = File.open("/tmp/49bf7fd3-8512-4d73-a28f-608e493cd726.js", 'r') {|file| actualFileContents = file.read}

    shouldBe = <<EOM
let foo = "something";

console.log(foo);
EOM

    assert_not_equal(actual_file_contents, "")
    assert_equal(shouldBe, actual_file_contents)
  end

  def teardown
    begin
      File.delete("/tmp/49bf7fd3-8512-4d73-a28f-608e493cd726.js")
    rescue
      # ignored
    end
  end
end