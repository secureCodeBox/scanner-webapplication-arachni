require 'singleton'
require_relative './aws-s3-store.rb'
require_relative './environment-store.rb'

class CredentialsService
  include Singleton


  def initialize
    @store_type = ENV['CREDENTIAL_STORE']
    if @store_type == 's3'
      $logger.info('Using AWS S3 Credential Store')
      @cred_store = AWSS3CredentialStore.new
    else
      $logger.info('Using Environment Variable Credential Store')
      @cred_store = EnvironmentCredentialStore.new
    end
  end


  def get_microservice_pw
    @cred_store.get_microservice_pw
  end

end


