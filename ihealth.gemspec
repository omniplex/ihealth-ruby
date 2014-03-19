Gem::Specification.new do |s|
  s.name        = 'ihealth'
  s.version     = '2.2.5'
  s.summary     = "Interface to F5s iHealth API"
  s.summary     = "An abstraction layer to provide functionality to F5's iHealth reporting interface"
  s.author      = 'Dave B. Greene'
  s.email       = 'omniplex@omniplex.net'
  s.files       = ["lib/ihealth.rb"]
  s.homepage    = 'https://github.com/omniplex/ihealth-ruby'
  s.license     = 'GPLv3'
  s.required_ruby_version = '>= 1.9.2'
  s.requirements = 'A valid support account with F5'
  s.description = <<-EOF
  This library provides an interface to F5's iHealth API system.
  EOF
 
end
