require 'aws-sdk'


# TODO WIP not functional
class AWSS3CredentialStore

  def initialize
    # init credentials here
  end
  def get_microservice_pw
    s3 = Aws::S3::Client.new
    file = s3.get_object(bucket:'bucket-name', key:'object-key')
    content = JSON.parse(file)
    content.dig('MICROS_CAMUNDA_PW')
  end
end