Pod::Spec.new do |spec|
  spec.name = 'Store'
  spec.version = '1.0.0'
  spec.summary = 'Core Data framework and toolbox 🤖'
  spec.license = { :type => 'MIT' }
  spec.homepage = 'https://github.com/swifteroid/store'
  spec.authors = { 'Ian Bytchek' => 'ianbytchek@gmail.com' }

  spec.platform = :osx, '10.10'

  spec.source = { :git => 'https://github.com/swifteroid/store.git', :tag => "#{spec.version}" }
  spec.source_files = 'source/**/*.{swift,h,m}'
  spec.exclude_files = 'source/{Test,Testing}/**/*'
  spec.swift_version = '5.2'

  spec.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS[config=Release]' => '-suppress-warnings' }
end