Pod::Spec.new do |s|
  s.name = "SwiftGridView"
  s.version = "0.7.8"
  s.summary = "A Swift based iOS Data Grid component."
  s.description = <<-DESC
			Swift UICollectionView based data grid component for fast implementation of advanced table / datagrid layouts. Supports iOS10+.
                       DESC

  s.homepage = "https://github.com/nlampi/SwiftGridView"
  s.license = 'MIT'
  s.author = { "Nathan Lampi" => "nate@nathanlampi.com" }
  s.source = { 
    :git => "https://github.com/nlampi/SwiftGridView.git", 
    :tag => s.version.to_s 
  }

  s.swift_version = '5.0'
  s.platform = :ios, '12.0'
  s.requires_arc = true

  s.source_files = 'Sources/**/*.swift'

  s.frameworks = 'UIKit'
end
