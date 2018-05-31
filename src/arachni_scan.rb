require 'securerandom'
require 'json'
require 'logger'

$logger = Logger.new(STDOUT)

class ArachniScan
  attr_reader :raw_results
  attr_reader :results
  def initialize(scan_id, config, uuid_provider = SecureRandom)
    @scan_id = scan_id
    @config = config
    @uuid_provider = uuid_provider
    @scanner_url = 'http://127.0.0.1:7331/scans'
  end

  def start
    scan_id = start_scan
    $logger.info "running scan for #{target}"
    perform_scan(scan_id)
    $logger.info "retrieving scan results for #{target}"
    get_scan_report(scan_id)
    $logger.info "cleaning up scan reports"
    remove_scan(scan_id)
  end

  def start_scan
    begin
      response = RestClient::Request.execute(
        method: :post,
        url: @scanner_url,
        payload: @config.generate_payload.to_json
      )
      id = JSON.parse(response)
      return id["id"]
    rescue => err
      $logger.warn err
    end
  end

  def perform_scan(scan_instance_id)
    loop do
      begin
        request = RestClient::Request.execute(
          method: :get,
          url: "#{@scanner_url}/#{scan_instance_id}",
          timeout: 10
        )
        response = JSON.parse(request)
        $logger.debug "Checking status of scan #{scan_instance_id} : currently busy : #{response['busy']}"
      rescue => err
        $logger.warn err
      end
      break if !response['busy']
      sleep 10
    end
  end

  def get_scan_report(scan_instance_id)
    begin
      report = RestClient::Request.execute(
        method: :get,
        url: "#{@scanner_url}/#{scan_instance_id}/report.json",
        timeout: 2
      )
      @raw_results = report
      # @results = transform_results(@raw_results)
    rescue => err
      $logger.warn err
    end
  end

  def remove_scan(scan_instance_id)
    begin
      $logger.debug "deleting scan #{scan_instance_id.to_str}"
      RestClient::Request.execute(
        method: :delete,
        url: "#{@scanner_url}/#{scan_instance_id}",
        timeout: 2
      )
    rescue => err
      $logger.warn err
    end
  end

  def transform_results(raw_results)
    # TODO implement transformation
    # example result : http://www.arachni-scanner.com/reports/report.json
    raw_results.select do |row|
      row.length == 7 && !row[6].empty?
    end.map do |row|
      {
        id: @uuid_provider.uuid,
        name: row[6],
        description: '',
        osi_layer: 'APPLICATION',
        reference: {
            id: row[3],
            source: row[3]
        },
        severity: 'INFORMATIONAL',
        location: "#{row[0]}:#{row[2]}#{row[5]}",
        attributes: {
          http_method: row[4],
          hostname: row[0],
          path: row[5],
          ip_address: row[1],
          port: row[2].to_i
        }
      }
    end
  end

end
