require 'test/unit'
require_relative '../src/nikto_scan'
require_relative '../src/nikto_configuration'

class MockExecutionService
  def initialize(return_value)
    @return_value = return_value
  end

  def execute(command)
    File.open("/tmp/report-12345678.csv", 'w') { |file| file.write(@return_value) }
  end
end

class FakeUuidProvider
  def uuid
    '49bf7fd3-8512-4d73-a28f-608e493cd726'
  end
end

class NiktoScanTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @config = NiktoConfiguration.new
    @config.nikto_target = 'localhost'
    @config.nikto_ports = '8080'
    @config.nikto_parameter = ''
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_small_result
    large_result = <<EOM
"Nikto - v2.1.5/2.1.5"
"Nikto - v2.1.5/2.1.5"
"localhost","127.0.0.1","8080","","","",""
"localhost","127.0.0.1","8080","OSVDB-0","OPTIONS","/","Allowed HTTP Methods: GET, HEAD, POST, PUT, DELETE, OPTIONS "
EOM

    @nikto_scan = NiktoScan.new('12345678', @config, MockExecutionService.new(large_result), FakeUuidProvider.new)
    assert_equal([
                     {
                         id: '49bf7fd3-8512-4d73-a28f-608e493cd726',
                         name: 'Allowed HTTP Methods: GET, HEAD, POST, PUT, DELETE, OPTIONS ',
                         description: '',
                         osi_layer: 'APPLICATION',
                         reference: {
                             id: 'OSVDB-0',
                             source:  'OSVDB-0',
                         },
                         severity: 'INFORMATIONAL',
                         location: "localhost:8080/",
                         attributes: {
                             http_method: 'OPTIONS',
                             hostname: 'localhost',
                             path: '/',
                             ip_address: '127.0.0.1',
                             port: 8080
                         }
                     }
                 ], @nikto_scan.start)
  end

  def test_large_result
    large_result = <<EOM
"Nikto - v2.1.5/2.1.5"
"Nikto - v2.1.5/2.1.5"
"localhost","127.0.0.1","8080","","","",""
"localhost","127.0.0.1","8080","OSVDB-0","OPTIONS","/","Allowed HTTP Methods: GET, HEAD, POST, PUT, DELETE, OPTIONS "
"localhost","127.0.0.1","8080","OSVDB-397","GET","/","HTTP method ('Allow' Header): 'PUT' method could allow clients to save files on the web server."
"localhost","127.0.0.1","8080","OSVDB-3092","GET","/test.html","/test.html: This might be interesting..."
EOM

    @nikto_scan = NiktoScan.new('12345678', @config, MockExecutionService.new(large_result), FakeUuidProvider.new)
    assert_equal([
                     {
                         id: '49bf7fd3-8512-4d73-a28f-608e493cd726',
                         name: 'Allowed HTTP Methods: GET, HEAD, POST, PUT, DELETE, OPTIONS ',
                         description: '',
                         osi_layer: 'APPLICATION',
                         reference: {
                             id: 'OSVDB-0',
                             source: 'OSVDB-0',
                         },
                         severity: 'INFORMATIONAL',
                         location: "localhost:8080/",
                         attributes: {
                             http_method: 'OPTIONS',
                             hostname: 'localhost',
                             path: '/',
                             ip_address: '127.0.0.1',
                             port: 8080
                         }
                     },
                     {
                         id: '49bf7fd3-8512-4d73-a28f-608e493cd726',
                         name: 'HTTP method (\'Allow\' Header): \'PUT\' method could allow clients to save files on the web server.',
                         description: '',
                         osi_layer: 'APPLICATION',
                         reference: {
                             id: 'OSVDB-397',
                             source:  'OSVDB-397',
                         },
                         severity: 'INFORMATIONAL',
                         location: "localhost:8080/",
                         attributes: {
                             http_method: 'GET',
                             hostname: 'localhost',
                             path: '/',
                             ip_address: '127.0.0.1',
                             port: 8080
                         }
                     },
                     {
                         id: '49bf7fd3-8512-4d73-a28f-608e493cd726',
                         name: '/test.html: This might be interesting...',
                         description: '',
                         osi_layer: 'APPLICATION',
                         reference: {
                             id: 'OSVDB-3092',
                             source:  'OSVDB-3092',
                         },
                         severity: 'INFORMATIONAL',
                         location: "localhost:8080/test.html",
                         attributes: {
                             http_method: 'GET',
                             hostname: 'localhost',
                             path: '/test.html',
                             ip_address: '127.0.0.1',
                             port: 8080
                         }
                     }
                 ], @nikto_scan.start)

  end
end