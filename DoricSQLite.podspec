Pod::Spec.new do |s|
    s.name             = 'DoricSQLite'
    s.version          = '0.1.11'
    s.summary          = 'Doric extension for SQLite3'
  
  
    s.description      = <<-DESC
    Support use sqlite3 storage in Doric.
                         DESC
  
    s.homepage         = 'https://github.com/doric-pub'
    s.license          = { :type => 'Apache-2.0', :file => 'LICENSE' }
    s.author           = { 'pengfeizhou' => 'pengfeizhou@foxmail.com' }
    s.source           = { :git => 'https://github.com/doric-pub/DoricSQLite.git', :tag => s.version.to_s }
  
    s.ios.deployment_target = '9.0'
  
    s.source_files = 'iOS/Pod/Classes/**/*'
    s.public_header_files = 'iOS/Pod/Classes/**/*.h'
    s.dependency 'DoricCore'
    s.library = 'sqlite3'
end
