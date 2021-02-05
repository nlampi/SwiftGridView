//
//  NSIndexPath+SwiftGridView.m
//  ObjCExample
//
//  Created by Nathan Lampi on 10/19/20.
//

#import "NSIndexPath+SwiftGridView.h"

@implementation NSIndexPath (SwiftGridView)

/**
 Init Swift Grid View Index Path
 
 - Parameter row: Row for the data grid
 - Parameter column: Column for the data grid
 - Paramter section: Section for the data grid
 */
- (instancetype)initForSGRow:(NSInteger)row atColumn:(NSInteger)column inSection:(NSInteger)section {
    NSUInteger indexArr[] = {section, column, row};
    
    return [self initWithIndexes:indexArr length:3];
}

/// Swift Grid View Section
- (NSInteger)sgSection {
    
    return [self indexAtPosition:0];
}

/// Swift Grid View Row
- (NSInteger)sgRow {
    
    return [self indexAtPosition:2];
}

/// Swift Grid View Column
- (NSInteger)sgColumn {
    
    return [self indexAtPosition:1];
}

@end
