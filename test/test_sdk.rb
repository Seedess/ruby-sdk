require 'minitest/autorun'
require_relative '../lib/seedess'

class SeedessTest < Minitest::Test
  def fake(status, body, calls)
    lambda do |method, url, headers, payload|
      calls << { method: method, url: url, headers: headers, body: payload }
      [status, body.nil? ? '' : JSON.generate(body)]
    end
  end

  def test_create_stream
    calls = []
    client = Seedess::Client.new('key_test', transport: fake(201, { 'ok' => true, 'id' => 'demo', 'publicToken' => 'pk_1' }, calls))
    stream = client.create_stream(url: 'https://origin/master.m3u8', id: 'demo')

    assert_equal 'demo', stream['id']
    assert_equal 'POST', calls[0][:method]
    assert_equal 'https://seedess.com/api/v1/streams', calls[0][:url]
    assert_equal 'Bearer key_test', calls[0][:headers]['authorization']
    assert_equal 'demo', JSON.parse(calls[0][:body])['id']
  end

  def test_path_encoding
    calls = []
    client = Seedess::Client.new('key_test', transport: fake(200, { 'ok' => true }, calls))
    client.get_stream('a/b')
    assert_equal 'https://seedess.com/api/v1/streams/a%2Fb', calls[0][:url]
  end

  def test_disable_and_enable_peers
    calls = []
    client = Seedess::Client.new('key_test', transport: fake(200, { 'ok' => true }, calls))
    client.disable_peers('demo')
    client.enable_peers('demo')
    assert_equal 'https://seedess.com/api/v1/streams/demo/kill', calls[0][:url]
    assert_equal 'https://seedess.com/api/v1/streams/demo/revive', calls[1][:url]
  end

  def test_telemetry_has_no_api_key
    calls = []
    client = Seedess::Client.new('key_test', transport: fake(204, nil, calls))
    client.send_telemetry(session_id: 's', stream_id: 'demo', p2p_bytes: 10)
    refute calls[0][:headers].key?('authorization')
  end

  def test_error_envelope
    calls = []
    client = Seedess::Client.new('key_test', transport: fake(429, { 'ok' => false, 'error' => { 'code' => 'QUOTA_EXCEEDED', 'message' => 'Limit reached' } }, calls))
    error = assert_raises(Seedess::Error) { client.create_stream(url: 'https://origin') }
    assert_equal 429, error.status
    assert_equal 'QUOTA_EXCEEDED', error.code
    assert_equal 'Limit reached', error.message
  end

  def test_rejects_public_token
    assert_raises(ArgumentError) { Seedess::Client.new('pk_stream') }
  end
end
