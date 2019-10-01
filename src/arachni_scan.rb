require 'securerandom'
require 'json'
require 'logger'

require_relative './arachni_result_transformer'

$logger = Logger.new(STDOUT)

class ScanTimeOutError < StandardError

end

class ArachniScan
  attr_reader :raw_results
  attr_reader :results
  attr_reader :errored

  def initialize(config)
    @config = config
    @scanner_url = 'http://127.0.0.1:7331/scans'
    @transformer = ArachniResultTransformer.new
    @errored = false
  end

  def start
    @scan_id = start_scan
    $logger.info "Running scan for #{@config.arachni_scanner_target}"
    begin
      wait_for_scan
      $logger.info "Retrieving scan results for #{@config.arachni_scanner_target}"
      get_scan_report
    rescue ScanTimeOutError => err
      $logger.warn "Scan #{@scan_id} timed out! Sending unfinished report to engine."
      get_scan_report(timed_out: true)
      @errored = true
    end

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

      $logger.debug "Starting scan returned #{response.code} code."

      id = JSON.parse(response)["id"]
      $logger.info "Started job with ID '#{id}'"
      id

    rescue => err
      $logger.warn err
      raise CamundaIncident.new("Failed to start arachni scan.", "This is most likely related to a error in the configuration. Check the arachni logs for more details.")
    end
  end

  def wait_for_scan
    last_request_count = 0
    last_request_count_change =Time.new
    timed_out_request_count = 0

    loop do
      response = nil

      begin
        request = RestClient::Request.execute(
            method: :get,
            url: "#{@scanner_url}/#{@scan_id}/summary",
            timeout: 5
        )
        $logger.debug "Status endpoint returned #{request.code}"
        response = JSON.parse(request)
        $logger.debug "Checking status of scan '#{@scan_id}': currently busy: #{response['busy']}"
      rescue RestClient::Exceptions::ReadTimeout
        timed_out_request_count += 1

        $logger.warn "Request to poll for current results timed out."

        if timed_out_request_count > 10
          $logger.warn "Polling for results timed out repeatably."
          raise ScanTimeOutError.new
        end
      rescue => err
        $logger.warn err
      end

      unless response.nil?
        current_request_count = response['statistics']['http']['request_count']
        found_pages = response['statistics']['found_pages']
        audited_pages = response['statistics']['audited_pages']
        current_page = response['statistics']['current_page']

        burst_average_response_time = response['statistics']['http']['burst_average_response_time']
        total_average_response_time = response['statistics']['http']['total_average_response_time']

        burst_responses_per_second = response['statistics']['http']['burst_responses_per_second']
        total_responses_per_second = response['statistics']['http']['total_responses_per_second']

        $logger.info "Request made:  #{current_request_count}"
        $logger.info "Pages found:   #{found_pages}"
        $logger.info "Pages audited: #{audited_pages}"
        $logger.info "Current Page:  #{current_page}"
        $logger.info "Burst Avg. Response Time: #{burst_average_response_time}s, Total Avg. Response Time: #{total_average_response_time}s"
        $logger.info "Burst Requests: #{burst_responses_per_second}/s, Total Requests per Second: #{total_responses_per_second}/s"

        if current_request_count == last_request_count
          if Time.now > last_request_count_change + (5 * 60)
            $logger.warn("Arachni request count hasn't updated in 5 min. It's probably stuck...")
            raise ScanTimeOutError.new
          end
        else
          last_request_count = current_request_count
          last_request_count_change = Time.new
        end

        # Resetting timed out count as the current request succeed
        timed_out_request_count = 0

        break unless response['busy']
      end

      sleep 2
    end
  end

  def get_scan_report(timed_out: false)
    begin
      report = RestClient::Request.execute(
          method: :get,
          url: "#{@scanner_url}/#{@scan_id}/report.json",
          timeout: 60
      )
      @raw_results = JSON.parse(report)
      @results = @transformer.transform(@raw_results, timed_out: timed_out)
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
