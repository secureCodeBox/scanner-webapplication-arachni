require 'test/unit'
require_relative '../src/arachni_configuration'

class ArachniConfigurationTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @config = ArachniConfiguration.new
    @config.arachni_scanner_target = 'localhost.com'
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_should_build_a_correct_payload_with_minimal_input
    assert_equal(
        @config.generate_payload,
        {
            :url => 'localhost.com',
            :scope => {
                :dom_depth_limit => 5
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
            }
        }
    )
  end
end