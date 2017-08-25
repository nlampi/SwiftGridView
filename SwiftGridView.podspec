Pod::Spec.new do |s|
  s.name = "SwiftGridView"
  s.version = "0.5.1"
  s.summary = "A Swift based iOS Data Grid component."
  s.description = <<-DESC
			Swift UICollectionView based data grid component for fast implementation of  Currently only supports iOS9+ and Swift 3.0
                       DESC

  s.homepage = "https://github.com/nlampi/SwiftGridView"
  s.license = 'MIT'
  s.author = { "Nathan Lampi" => "nate@nathanlampi.com" }
  s.source = { 
    :git => "https://github.com/nlampi/SwiftGridView.git", 
    :tag => s.version.to_s 
  }

  s.platform = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Source/**/*.swift'

  s.frameworks = 'UIKit'
end
