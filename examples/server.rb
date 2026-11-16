#!/usr/bin/env ruby
# Full working Seedess example for Ruby.
#
#   SEEDESS_API_KEY=key_... ruby examples/server.rb
#   open http://localhost:8787

require 'json'
require 'webrick'
require_relative '../lib/seedess'

ORIGIN = 'https://seedess.com'

api_key = ENV['SEEDESS_API_KEY']
abort 'Set SEEDESS_API_KEY (a server key, key_...) before running this example.' if api_key.nil? || api_key.empty?

stream_url = ENV.fetch('SEEDESS_STREAM_URL', 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8')
stream_id = ENV.fetch('SEEDESS_STREAM_ID', 'sdk-example')
base_url = ENV.fetch('SEEDESS_API_BASE', ORIGIN)
port = Integer(ENV.fetch('PORT', '8787'))

seedess = Seedess::Client.new(api_key, base_url: base_url)
cached = nil
mutex = Mutex.new

def handoff(seedess, stream_url, stream_id, cached, mutex)
  mutex.synchronize do
    return cached if cached

    stream = seedess.create_stream(url: stream_url, id: stream_id, title: 'Seedess Ruby SDK example')
    token = stream['publicToken']
    playback = stream['playback']
    {
      'ok' => true,
      'stream' => stream['id'],
      'token' => token,
      'playback' => {
        'master' => ORIGIN + playback['master'],
        'signaling' => ORIGIN + playback['signaling'],
        'config' => "#{ORIGIN}/signaling/config?token=#{CGI.escape(token)}"
      }
    }
  end
end

server = WEBrick::HTTPServer.new(
  Port: port,
  BindAddress: '127.0.0.1',
  Logger: WEBrick::Log.new($stdout, WEBrick::Log::INFO),
  AccessLog: []
)

server.mount_proc('/api/seedess') do |_req, res|
  begin
    payload = handoff(seedess, stream_url, stream_id, cached, mutex)
    cached = payload if cached.nil?
    res['content-type'] = 'application/json'
    res.body = JSON.generate(payload)
  rescue Seedess::Error => e
    res.status = 500
    res['content-type'] = 'application/json'
    res.body = JSON.generate('ok' => false, 'error' => "#{e.status} #{e.code}: #{e.message}")
  end
end

server.mount_proc('/') do |_req, res|
  res['content-type'] = 'text/html; charset=utf-8'
  res.body = File.read(File.join(__dir__, 'public', 'index.html'))
end

trap('INT') { server.shutdown }
puts "Seedess example on http://localhost:#{port}"
puts 'The first /api/seedess request creates the stream.'
server.start
