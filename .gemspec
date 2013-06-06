Gem::Specification.new do |s|
  s.name        = 'app-up'
  s.version     = '0.0.1'
  s.summary     = "A gem for distributing Andriod and iOS apps"
  s.description = "A gem for distributing Andriod and iOS apps and generating links in ruby"
  s.authors     = ["Alex Barlow"]
  s.email       = 'alexb@madebymany.co.uk'
  s.files       = ["lib/app-up.rb", "lib/image_57x57.png", "lib/image_512x512.png"]
  s.executables << 'app-up'
  s.add_runtime_dependency "thor"
  s.add_runtime_dependency "fog"
  s.add_runtime_dependency "activesupport"
end
