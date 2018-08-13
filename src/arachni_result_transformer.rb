require 'securerandom'
require 'json'

class ArachniResultTransformer
  def initialize(uuid_provider = SecureRandom)
    @uuid_provider = uuid_provider;
  end

  def transform(result, timed_out: false)
    findings = result["issues"].map do |issue|
      if issue.dig('cwe')
        reference = {
            id: "CWE-#{issue.dig('cwe')}",
            source: issue.dig('cwe_url') ? issue.dig('cwe_url') : ''
        }
      else
        reference = {}
      end

      {
          id: @uuid_provider.uuid,
          name: issue.dig('name'),
          description: issue.dig('description'),
          category: issue.dig('check','name'),
          osi_layer: 'APPLICATION',
          reference: reference,
          severity: issue.dig('severity').upcase,
          location: issue.dig('request', 'url'),
          hint: issue.dig('remedy_guidance') ? issue.dig('remedy_guidance') : '',
          attributes: {
              ARACHNI_REQUEST: {
                 URL: issue.dig('request', 'url'),
                 PARAMETER: issue.dig('request', 'parameters'),
                 HEADERS: issue.dig('request', 'headers'),
                 BODY: issue.dig('request', 'body'),
                 METHOD: issue.dig('request', 'method')
              },
              ARACHNI_RESPONSE: {
                 URL: issue.dig('response', 'url'),
                 PARAMETER: issue.dig('response', 'parameters'),
                 HEADERS: issue.dig('response', 'headers'),
                 BODY: issue.dig('response', 'body'),
                 STATUS: issue.dig('response', 'code')
              }
          }
      }
    end

    if timed_out
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