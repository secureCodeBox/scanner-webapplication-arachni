require 'test/unit'
require_relative '../src/arachni_configuration'

class ArachniConfigurationTest < Test::Unit::TestCase

  def test_should_build_a_correct_payload_with_minimal_input

    config = ArachniConfiguration.new
    config.arachni_scanner_target = 'localhost.com'
    config.arachni_dom_depth_limit = 10
    config.arachni_page_limit = 22
    config.arachni_dir_depth_limit = 62
    config.arachni_exclude_patterns = ['foo', 'bar']
    config.arachni_include_patterns = ['baz', 'bang', 'boom']
    config.arachni_cookie_string = 'foo=bar; bar=foo'

    assert_equal(
        config.generate_payload,
        {
            :url => 'localhost.com',
            :scope => {
                :dom_depth_limit => 10,
                :directory_depth_limit => 62,
                :page_limit => 22

            },
            :http => {
                :cookie_string => 'foo=bar; bar=foo'
            },
            :checks => '*',
            :audit => {
                :exclude_vector_patterns => ['foo', 'bar'],
                :include_vector_patterns => ['baz', 'bang', 'boom'],
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
    )
  end
end