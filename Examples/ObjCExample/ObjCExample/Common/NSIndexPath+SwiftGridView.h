//
//  NSIndexPath+SwiftGridView.h
//  ObjCExample
//
//  Created by Nathan Lampi on 10/19/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSIndexPath (SwiftGridView)

/**
 Init Swift Grid View Index Path
 
 - Parameter row: Row for the data grid
 - Parameter column: Column for the data grid
 - Paramter section: Section for the data grid
 */
- (instancetype)initForSGRow:(NSInteger)row atColumn:(NSInteger)column inSection:(NSInteger)section;

/// Swift Grid View Section
- (NSInteger)sgSection;

/// Swift Grid View Row
- (NSInteger)sgRow;

/// Swift Grid View Column
- (NSInteger)sgColumn;

@end

NS_ASSUME_NONNULL_END
