Pod::Spec.new do |s|
  s.name             = "SwiftGridView"
  s.version          = "0.3.2"
  s.summary          = "A Swift based iOS implementation of a Data Grid component."
  s.description      = <<-DESC
			Swift UICollectionView based data grid component. Currently only supports iOS9+ and Swift 3.0
                       DESC

  s.homepage         = "https://github.com/nlampi/SwiftGridView"
  s.license          = 'MIT'
  s.author           = { "Nathan Lampi" => "nate@nathanlampi.com" }
  s.source           = { :git => "https://github.com/nlampi/SwiftGridView.git", :tag => s.version.to_s }

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'SwiftGridView/**/*'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
end
