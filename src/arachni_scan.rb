require 'securerandom'
require 'json'
require_relative "../lib/camunda_worker"


class ArachniScan
  attr_reader :raw_results
  attr_reader :results
  def initialize(scan_id, config, uuid_provider = SecureRandom)
    @scan_id = scan_id
    @config = config
    @uuid_provider = uuid_provider
    @scanner_url = "http://127.0.0.1:7331"
  end

  def start_scan(target)
    payload = {
      "url" => target,
      "checks" => '*'
    }
    CamundaWorker.http_post(@scanner_url,payload.to_json)
    $logger.warn "tried to post"
  end

  def scan_complete(scan_id)

  end

  def transform_results(raw_results)
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

  def import_results

    begin
      result_text_csv = File.open(@filename, 'r'){ |file| file.read }
    rescue => e
      puts "Could not read result file"
      puts e.message
    end

    # Replacing " with "" to ensure that they will always be in pairs
    # A unterminated string will cause the csv parser to fail.
    result_text_csv = result_text_csv.gsub(/\\"/, '""')

    CSV.parse(result_text_csv)
  end
end
