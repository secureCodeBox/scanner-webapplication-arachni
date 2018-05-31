require 'securerandom'
require 'json'
require 'logger'

require_relative './arachni_result_transformer'

$logger = Logger.new(STDOUT)

class ArachniScan
  attr_reader :raw_results
  attr_reader :results

  def initialize(scan_id, config)
    @scan_id = scan_id
    @config = config
    @scanner_url = 'http://127.0.0.1:7331/scans'
    @transformer = ArachniResultTransformer.new
  end

  def start
    scan_id = start_scan
    $logger.info "Running scan for #{@config.arachni_scanner_target}"
    perform_scan(scan_id)
    $logger.info "Retrieving scan results for #{@config.arachni_scanner_target}"
    get_scan_report(scan_id)
    $logger.info "Cleaning up scan reports"
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
      $logger.info "Job ID #{id}"
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
      break unless response['busy']
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
      @raw_results = JSON.parse(report)
      @results = @transformer.transform(@raw_results)
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
end
