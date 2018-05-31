require 'securerandom'
require 'json'

class ArachniResultTransformer
  def initialize(uuid_provider = SecureRandom)
    @uuid_provider = uuid_provider;
  end

  def transform(result)
    result["issues"].map do |issue|
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
  end
end