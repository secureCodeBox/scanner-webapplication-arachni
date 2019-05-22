require 'json'
require 'rest-client'
require 'ruby-scanner-scaffolding'

require_relative "./arachni_scan"
require_relative "./arachni_configuration"

class ArachniWorker < CamundaWorker
  attr_accessor :errored

  def initialize(camunda_url, topic, variables, task_lock_duration = 3600000, poll_interval = 5)
    super(camunda_url, topic, variables, task_lock_duration = 3600000, poll_interval = 5)

    @errored = false
  end

  def work(job_id, targets)
    configs = targets.map {|target|
      ArachniConfiguration.from_target job_id, target
    }

    scans = configs.map { |config|
      scan = ArachniScan.new(config)
      scan.start
      if scan.errored
        @errored = true
      end
      scan
    }

    {
        findings: scans.flat_map{|scan| scan.results},
        rawFindings: scans.map{|scan| scan.raw_results.to_json}.to_json,
        scannerId: @worker_id.to_s,
        scannerType: 'arachni'
    }
  end

  def healthy?
    begin
      response = RestClient::Request.execute(
          method: :get,
          url: 'http://127.0.0.1:7331/scans',
          timeout: 2
      )
      response.code == 200
    rescue
      return false
    end
  end
end
