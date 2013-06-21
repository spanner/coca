$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "coca/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "coca"
  s.version     = Coca::VERSION
  s.authors     = ["William Ross"]
  s.email       = ["will@spanner.org"]
  s.homepage    = "github.com/spanner/coca"
  s.summary     = "Lightweight, simple SSO for rails."
  s.description = "Coca is a chainable, devise-based scheme for delegation of authentication. It works through a standard JSON API so the packet that you pass down on auth is completely configurable. See coca-rbac for a similarly transparent RBAC implementation."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 3.2.13"
  s.add_dependency "jquery-rails"
  s.add_dependency "devise"
  s.add_dependency "rocket_pants"
  s.add_dependency "signed_json"

  s.add_development_dependency "mysql2"
end
