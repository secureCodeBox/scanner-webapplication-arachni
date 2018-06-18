require 'json'

require_relative "../lib/camunda_worker"

require_relative "./arachni_scan"
require_relative "./arachni_configuration"

class ArachniWorker < CamundaWorker
  def work(job_id, targets)
    configs = targets.map {|target|
      ArachniConfiguration.from_target target
    }

    scans = configs.map { |config|
      scan = ArachniScan.new(job_id, config)
      scan.start
      scan
    }

    {
        findings: scans.flat_map{|scan| scan.results},
        rawFindings: scans.map{|scan| scan.raw_results.to_s}.join(','),
        scannerId: @worker_id.to_s,
        scannerType: 'arachni'
    }
  end
end
