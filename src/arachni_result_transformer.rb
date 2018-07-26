require 'securerandom'
require 'json'

class ArachniResultTransformer
  def initialize(uuid_provider = SecureRandom)
    @uuid_provider = uuid_provider;
  end

  def transform(result, timedOut)
    findings = result["issues"].map do |issue|
      if issue['cwe']
        reference = {
            id: "CWE-#{issue['cwe']}",
            source: issue['cwe_url'] ? issue['cwe_url'] : ''
        }
      else
        reference = {}
      end

      {
          id: @uuid_provider.uuid,
          name: issue['name'],
          description: issue['description'],
          osi_layer: 'APPLICATION',
          reference: reference,
          severity: issue['severity'].upcase,
          location: issue['request']['url'],
          hint: issue['remedy_guidance'] ? issue['remedy_guidance'] : '',
          attributes: {}
      }
    end

    if timedOut
      findings.push({
       id: @uuid_provider.uuid,
       name: "Arachni Scan timed out and could no be finished.",
       description: "Arachni Scan didnt send any new requests for 5 minutes. This probably means that arachni encountered some internal errors it could not handle.",
       osi_layer: 'NOT_APPLICABLE',
       severity: "MEDIUM",
       category: "ScanError",
       hint: "This could be related to a misconfiguration. But could also be related to internal instabilities of the arachni platform.",
       attributes: {}
       })
    end

    findings
  end
end