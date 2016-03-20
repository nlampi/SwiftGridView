SwiftGridView
============

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/SwiftGridView.svg?style=flat)](http://cocoapods.org/pods/SwiftGridView)
[![License](https://img.shields.io/cocoapods/l/SwiftGridView.svg?style=flat)](http://cocoapods.org/pods/SwiftGridView)
[![Platform](https://img.shields.io/cocoapods/p/SwiftGridView.svg?style=flat)](http://cocoadocs.org/docsets/SwiftGridView)

Swift based data grid component. Currently under development and not truly production ready. If there is interest I will continue to develop the component and build up a guide for using beyond the included example. Currently this project is iOS9+ compatible only. I have not tested this in an Objective-C project, so if you have any issues, please let me know.

![Demo](http://giant.gfycat.com/IllAmbitiousBackswimmer.gif)

## Installation with CocoaPods

Since the project is written in swift it is required to include 'use_frameworks!'
```ruby
pod 'SwiftGridView', '~> 0.1'

use_frameworks!
```

Then to complete the install run the following:
```bash
$ pod install
```

## Features

Currently the Swift Grid View supports a lot of the expected features for a data grid, but it may not cover all requirements.

#### Cell Types
- Header
- Footer
- Section Headers
- Section Footers
- Standard Cells

#### Cell Selection
- Row Selection
- Cell Selection
- Multi selection 
- Header/Footer selection

#### Additional Functionality
- Sticky section headers
- Frozen Columns

## Usage

For an example of how to utilize, see the example project. It is pretty similar to any other view type with required data source and delegate methods.

## License

SwiftGridView is released under the MIT license. See LICENSE for details.
