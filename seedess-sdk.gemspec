Gem::Specification.new do |spec|
  spec.name          = 'seedess-sdk'
  spec.version       = '0.1.0'
  spec.authors       = ['Seedess']
  spec.email         = ['hello@seedess.com']
  spec.summary       = 'Official Seedess SDK for Ruby.'
  spec.description   = 'Create streams, mint playback tokens and read offload metrics.'
  spec.homepage      = 'https://seedess.com/docs/libraries/'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.6'
  spec.files         = Dir['lib/**/*.rb'] + ['README.md', 'LICENSE']
  spec.require_paths = ['lib']
  spec.metadata = {
    'source_code_uri' => 'https://github.com/Seedess/ruby-sdk',
    'documentation_uri' => 'https://seedess.com/docs/'
  }
end
