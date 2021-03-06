require "login_service/version"

module LoginService
  class Error < StandardError; end
  
  class << self
    attr_accessor :configuration

    def configure &blk
      self.configuration ||= LoginService::Configuration.new.tap(&blk)
    end
  end

  class Configuration
    attr_accessor :host, :api_key

    def initialize(options={})
      self.host = options['host']
      self.api_key = options['api_key']
    end
  end

  class Service
    attr_reader :host, :url, :response_data, :response_status

    def initialize
      @host  = LoginService.configuration.host
      @api_key = LoginService.configuration.api_key
      @errors = []
    end

    def response
      execute

      return self
    end

    def errors
      @errors ||= []
    end

    def valid?
      errors.empty?
    end

    # def errors_hash
    #   { errors: errors }
    # end

    # def success_hash
    #   {}
    # end

    def request path, request_type, &blck
      url = @host+path
      url = URI(url)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = false
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      if request_type == 'POST'
        request = Net::HTTP::Post.new(url)
      else
        request = Net::HTTP::Get.new(url)
      end
      request["Authorization"] = @api_key
      request["content-type"] = 'application/json'
      yield(http, request)
    end

    def execute
      validate
      if valid?
        case request_type 
        when 'GET'
          process_get_request
        when 'POST'
          process_post_request
        else
          raise 'Invalid request type'
        end
      end
    end

    def validate
    end

    def process_post_request
      request(service_path, request_type) do |http, request|
        request.body = payload.to_json
        process_request http, request
      end
    end

    def process_get_request
      request(service_path, request_type) do |http, request|
        process_request http, request
      end
    end

    def process_request http, request
      response = http.request(request)
      @response_status = response.code.to_i
      process_response(response.body)
    end

    def request_type
      raise 'Define request type in base class'
    end

    def service_path
      raise 'Define service path of API in base class'
    end
  end
end

require "login_service/sign_up"
require "login_service/verify_token"
