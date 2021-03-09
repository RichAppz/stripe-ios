Pod::Spec.new do |s|
  s.name = 'AppClip-Stripe'
  s.version = '21.3.2'
  s.license = 'MIT'
  s.summary = 'AppClip-Stripe for ApplePay ONLY'
  s.homepage = 'https://richappz.com'
  s.source = { :git => 'git@github.com:RichAppz/stripe-ios.git', :commit => "0d6761feefccff1f7d8b7c7788ceb8e9cd1314ea" }
  s.authors = { 'Rich Mucha' => 'rich@richappz.com' }
  
  s.ios.deployment_target = '13.0'
  
  s.source_files = 'Stripe/*.swift'
  s.ios.resource_bundle = { 'Stripe' => 'Stripe/Resources/**/*.{lproj,json,png}' }
  s.swift_versions = '5.0'
  
  s.static_framework = true

end 
