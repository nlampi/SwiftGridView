
<p align="center">
    <img src="https://raw.githubusercontent.com/nlampi/SwiftGridView/master/docs/SwiftGridViewLogo@2x.png" width=420 />
</p>
<p>
    &nbsp;
</p>
<p align="center">
    <a href="https://github.com/nlampi/SwiftGridView/releases">
        <img src="https://img.shields.io/github/release/nlampi/SwiftGridView.svg?style=flat"
            alt="Releases">
    </a>
    <a href="https://github.com/apple/swift-package-manager">
        <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg"
            alt="Swift Package Manager" />
    </a>
    <a href="https://cocoapods.org/pods/SwiftGridView">
        <img src="https://img.shields.io/cocoapods/v/SwiftGridView.svg?style=flat"
            alt="CocoaPods Compatible">
    </a>
    <a href="https://cocoapods.org/pods/SwiftGridView">
        <img src="https://img.shields.io/cocoapods/l/SwiftGridView.svg?style=flat"
            alt="License">
    </a>
    <a href="https://cocoadocs.org/docsets/SwiftGridView">
        <img src="https://img.shields.io/cocoapods/p/SwiftGridView.svg?style=flat"
            alt="Platform">
    </a>
</p>

----------------

Swift based data grid component based on `UICollectionView`. `SwiftGridView` allows for quick and easy data grids that are fully customizable with powerful built in functionality.

## Features

Swift Grid View supports many of the expected features for a data grid in an easy to use package. 

#### DataGrid Cell Types
- Headers and Footers
- Section Headers and Footers
- Row Cells

<img src="https://nlampi.github.io/SwiftGridView/BasicDemo.gif" width=600 />


#### Cell Selection
- Full Row or Single Cell Selection
- Multi selection
- Header or Footer Selection

<img src="https://nlampi.github.io/SwiftGridView/SelectionDemo.gif" width=600 />


#### Additional Functionality
- Sticky section headers
- Frozen Columns and Rows
- Grouped Headers
- Pinch to expand size (experimental)

<img src="https://nlampi.github.io/SwiftGridView/FrozenColRowDemo.gif" width=600 />


## Requirements

- Xcode 10.0+
- iOS 12.0+

## Installation 

### Swift Package Manager

SwiftGridView is easily installed and managed using SPM. 

1. In Xcode navigate to **File** → **Swift Packages** → **Add Package Dependency...**
2. Paste the repo URL (`https://github.com/nlampi/SwiftGridView.git`) and click **Next**
3. For the **Rules** either choose **Up to Next Major** for stable compatible releases or **Branch** `master` to remain up to date with the latest
4. Click **Finish**


### CocoaPods

For installation with [CocoaPods](https://cocoapods.org), add the pod information to your `Podfile`:

```ruby
pod 'SwiftGridView', '~> 0.7'
```

## Usage

For detailed examples of how to utilize, see the [example projects](./Examples). 

## Documentation

Full documentation can be [found here](https://nlampi.github.io/SwiftGridView). Documentation generated using [jazzy](https://github.com/realm/jazzy).

## License

Copyright 2016 - 2022 Nathan Lampi

SwiftGridView is released under the [MIT license](./LICENSE).
