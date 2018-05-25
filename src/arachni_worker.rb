require 'json'

require_relative "../lib/camunda_worker"

require_relative "./arachni_scan"
require_relative "./arachni_configuration"

class ArachniWorker < CamundaWorker
  def work(job_id, targets)
    configs = targets.map {|process_target|
      config = ArachniConfiguration.new
      config.arachni_target = process_target.dig('location')
      # config.arachni_ports = process_target.dig('attributes', 'arachni_PORTS')
      config
    }

    scans = configs.map { |config|
      scan = ArachniScan.new(job_id, config)
      scan.start_scan
      scan
    }

    {
        findings: scans.flat_map{|scan| scan.results},
        raw_findings: scans.map{|scan| scan.raw_results},
        scannerId: @worker_id.to_s,
        scannerType: 'arachni'
    }
  end
end
