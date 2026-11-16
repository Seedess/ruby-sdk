require 'json'
require 'net/http'
require 'uri'

module Seedess
  class Error < StandardError
    attr_reader :status, :code, :body

    def initialize(status, code, message, body = nil)
      super(message)
      @status = status
      @code = code
      @body = body
    end
  end

  class Client
    DEFAULT_BASE_URL = 'https://seedess.com'.freeze

    def initialize(api_key, base_url: DEFAULT_BASE_URL, transport: nil)
      unless api_key.is_a?(String) && api_key.start_with?('key_')
        raise ArgumentError, 'Seedess: api_key must be a server API key (key_…)'
      end

      @api_key = api_key
      @base_url = base_url.sub(%r{/+\z}, '')
      @transport = transport || method(:http_transport)
    end

    def request(method, path, body = nil, auth: true)
      url = "#{@base_url}#{path.start_with?('/') ? path : "/#{path}"}"
      headers = { 'accept' => 'application/json' }
      payload = nil
      unless body.nil?
        headers['content-type'] = 'application/json'
        payload = JSON.generate(body)
      end
      headers['authorization'] = "Bearer #{@api_key}" if auth

      status, raw = @transport.call(method, url, headers, payload)
      data = nil
      unless raw.nil? || raw.empty?
        begin
          data = JSON.parse(raw)
        rescue JSON::ParserError
          data = { 'error' => { 'code' => 'invalid_json', 'message' => raw[0, 200] } }
        end
      end

      unless status >= 200 && status < 300
        error = data.is_a?(Hash) && data['error'].is_a?(Hash) ? data['error'] : {}
        raise Error.new(
          status,
          error['code'] || 'http_error',
          error['message'] || "HTTP #{status}",
          data
        )
      end
      data
    end

    def create_stream(url:, id: nil, title: nil, live: nil)
      body = { 'url' => url }
      body['id'] = id unless id.nil?
      body['title'] = title unless title.nil?
      body['live'] = live unless live.nil?
      request('POST', '/api/v1/streams', body)
    end

    def get_stream(id)
      request('GET', "/api/v1/streams/#{escape(id)}")
    end

    def list_streams
      request('GET', '/api/v1/streams')
    end

    def refresh_stream(id)
      request('POST', "/api/v1/streams/#{escape(id)}/refresh")
    end

    def disable_peers(id)
      request('POST', "/api/v1/streams/#{escape(id)}/kill")
    end

    def enable_peers(id)
      request('POST', "/api/v1/streams/#{escape(id)}/revive")
    end

    def get_metrics(id)
      request('GET', "/api/v1/streams/#{escape(id)}/metrics")
    end

    def send_telemetry(session_id:, stream_id:, cdn_bytes: 0, p2p_bytes: 0, hash_failures: 0,
                       fallbacks: 0, rebuffers: 0, peak_peers: 0)
      request(
        'POST',
        '/api/v1/telemetry',
        {
          'sessionId' => session_id,
          'streamId' => stream_id,
          'cdnBytes' => cdn_bytes,
          'p2pBytes' => p2p_bytes,
          'hashFailures' => hash_failures,
          'fallbacks' => fallbacks,
          'rebuffers' => rebuffers,
          'peakPeers' => peak_peers
        },
        auth: false
      )
    end

    private

    def escape(value)
      URI.encode_www_form_component(value.to_s).gsub('+', '%20')
    end

    def http_transport(method, url, headers, payload)
      uri = URI.parse(url)
      request = Net::HTTPGenericRequest.new(method, !payload.nil?, true, uri.request_uri)
      headers.each { |name, value| request[name] = value }
      request.body = payload unless payload.nil?
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 30, read_timeout: 30) do |http|
        http.request(request)
      end
      [response.code.to_i, response.body.to_s]
    end
  end
end
