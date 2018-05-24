
class EnvironmentCredentialStore

  def get_microservice_pw
    ENV['MICROS_CAMUNDA_PW']
  end

end