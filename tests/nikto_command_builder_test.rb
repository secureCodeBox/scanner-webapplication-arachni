require 'test/unit'
require_relative '../src/nikto_command_builder'
require_relative '../src/nikto_configuration'

class NiktoCommandBuilderTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @config = NiktoConfiguration.new
    @config.nikto_target = 'localhost'
    @config.nikto_ports = ''
    @config.nikto_parameter = ''

    @filename = '/tmp/report-49bf7fd3-8512-4d73-a28f-608e493cd726.csv'
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_should_build_a_correct_cmd_with_minimal_input
    cmd = NiktoCommandBuilder.new(@config, @filename)

    assert_equal(
        cmd.build,
        'perl /sectools/nikto-master/program/nikto.pl -F csv -o /tmp/report-49bf7fd3-8512-4d73-a28f-608e493cd726.csv -h localhost'
    )
  end

  def test_should_build_a_correct_cmd_with_ports_specified
    @config.nikto_ports = '8080'
    cmd = NiktoCommandBuilder.new(@config, @filename)

    assert_equal(
        cmd.build,
        'perl /sectools/nikto-master/program/nikto.pl -F csv -o /tmp/report-49bf7fd3-8512-4d73-a28f-608e493cd726.csv -h localhost -p 8080'
    )
  end

  def test_should_build_a_correct_cmd_with_additional_parameters_specified
    @config.nikto_parameter = '-nossl'
    cmd = NiktoCommandBuilder.new(@config, @filename)

    assert_equal(
        cmd.build,
        'perl /sectools/nikto-master/program/nikto.pl -F csv -o /tmp/report-49bf7fd3-8512-4d73-a28f-608e493cd726.csv -h localhost -nossl'
    )
  end
end