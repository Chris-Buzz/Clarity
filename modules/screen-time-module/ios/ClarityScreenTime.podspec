require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

Pod::Spec.new do |s|
  s.name         = "ClarityScreenTime"
  s.version      = package['version']
  s.summary      = package['description']
  s.homepage     = package['homepage']
  s.license      = package['license']
  s.authors      = package['author']

  s.platforms    = { :ios => "15.0" }
  s.source       = { :git => "https://github.com/clarity/screen-time-module.git", :tag => "#{s.version}" }

  s.source_files = "*.{h,m,mm,swift}"

  s.dependency "React-Core"

  s.frameworks = "FamilyControls", "ManagedSettings", "DeviceActivity"

  s.swift_version = "5.0"
end
