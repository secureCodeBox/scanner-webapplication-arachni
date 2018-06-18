require 'securerandom'
require 'json'
require 'logger'

require_relative './arachni_result_transformer'

$logger = Logger.new(STDOUT)

class ArachniScan
  attr_reader :raw_results
  attr_reader :results

  def initialize(config)
    @config = config
    @scanner_url = 'http://127.0.0.1:7331/scans'
    @transformer = ArachniResultTransformer.new
  end

  def start
    @scan_id = start_scan
    $logger.info "Running scan for #{@config.arachni_scanner_target}"
    wait_for_scan
    $logger.info "Retrieving scan results for #{@config.arachni_scanner_target}"
    get_scan_report
    $logger.info "Cleaning up scan report for #{@config.arachni_scanner_target}"
    remove_scan
  end

  def start_scan
    begin
      response = RestClient::Request.execute(
          method: :post,
          url: @scanner_url,
          payload: @config.generate_payload.to_json
      )
      id = JSON.parse(response)["id"]
      $logger.info "Started job with ID '#{id}'"
      id
    rescue => err
      $logger.warn err
    end
  end

  def wait_for_scan
    loop do
      begin
        request = RestClient::Request.execute(
            method: :get,
            url: "#{@scanner_url}/#{@scan_id}",
            timeout: 2
        )
        response = JSON.parse(request)
        $logger.debug "Checking status of scan '#{@scan_id}': currently busy: #{response['busy']}"
      rescue => err
        $logger.warn err
      end
      break unless response['busy']
      sleep 2
    end
  end

  def get_scan_report
    begin
      report = RestClient::Request.execute(
          method: :get,
          url: "#{@scanner_url}/#{@scan_id}/report.json",
          timeout: 2
      )
      @raw_results = JSON.parse(report)
      @results = @transformer.transform(@raw_results)
    rescue => err
      $logger.warn err
    end
  end

  def remove_scan
    begin
      $logger.debug "Deleting scan #{@scan_id}"
      RestClient::Request.execute(
          method: :delete,
          url: "#{@scanner_url}/#{@scan_id}",
          timeout: 2
      )
    rescue => err
      $logger.warn err
    end
  end
end
