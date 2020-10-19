//
//  ViewController.m
//  ObjCExample
//
//  Created by Nathan Lampi on 10/19/20.
//

#import "ViewController.h"
@import SwiftGridView;
#import "ObjCExample-Swift.h"
#import "NSIndexPath+SwiftGridView.h"

@interface ViewController () <SwiftGridViewDelegate, SwiftGridViewDataSource>

@property (nonatomic, weak) IBOutlet SwiftGridView *dataGridView;

@property (nonatomic, readwrite) NSInteger sectionCount;
@property (nonatomic, readwrite) NSInteger frozenColumns;
@property (nonatomic, readwrite) NSInteger columnCount;
@property (nonatomic, readwrite) NSInteger rowCountIncrease;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sectionCount = 5;
    self.frozenColumns = 1;
    self.columnCount = 10;
    self.rowCountIncrease = 15;
    
    self.dataGridView.allowsSelection = true;
    self.dataGridView.allowsMultipleSelection = true;
    self.dataGridView.rowSelectionEnabled = true;
    self.dataGridView.isDirectionalLockEnabled = false;
    self.dataGridView.bounces = true;
    self.dataGridView.stickySectionHeaders = true;
    self.dataGridView.showsHorizontalScrollIndicator = true;
    self.dataGridView.showsVerticalScrollIndicator = true;
    self.dataGridView.alwaysBounceHorizontal = false;
    self.dataGridView.alwaysBounceVertical = false;
    self.dataGridView.pinchExpandEnabled = true;
    
    // Register Basic Cell types
    [self.dataGridView registerClass:[BasicTextCell class] forCellReuseIdentifier:[BasicTextCell reuseIdentifier]];
    
    // Register Basic View for Header supplementary views
    
    [self.dataGridView registerClass:[BasicTextReusableView class] forSupplementaryViewOfKind:@"SwiftGridElementKindHeader" withReuseIdentifier:[BasicTextReusableView reuseIdentifier]];
    
    // Register Section header Views
    [self.dataGridView registerClass:[BasicTextReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[BasicTextReusableView reuseIdentifier]];
    
    // Register Footer views
    [self.dataGridView registerClass:[BasicTextReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[BasicTextReusableView reuseIdentifier]];
    [self.dataGridView registerClass:[BasicTextReusableView class] forSupplementaryViewOfKind:@"SwiftGridElementKindFooter" withReuseIdentifier:[BasicTextReusableView reuseIdentifier]];
}


// MARK: - SwiftGridViewDataSource


- (NSInteger)numberOfSectionsInDataGridView:(SwiftGridView *)dataGridView {
    
    return self.sectionCount;
}

- (NSInteger)numberOfColumnsInDataGridView:(SwiftGridView *)dataGridView {
    
    return self.columnCount;
}

- (NSInteger)dataGridView:(SwiftGridView *)dataGridView numberOfRowsInSection:(NSInteger)section {
    
    return section + self.rowCountIncrease;
}

- (NSInteger)dataGridView:(SwiftGridView *)dataGridView numberOfFrozenRowsInSection:(NSInteger)section {
    
    if(section < 1) {
        
        return 2;
    }
    
    return 0;
}

// Cells
- (SwiftGridCell *)dataGridView:(SwiftGridView *)dataGridView cellAtIndexPath:(NSIndexPath *)indexPath {
    BasicTextCell *textCell = (BasicTextCell *) [dataGridView dequeueReusableCellWithReuseIdentifier:[BasicTextCell reuseIdentifier] forIndexPath:indexPath];
    
    CGFloat r = (147.0 / 255.0);// + CGFloat(indexPath.sgSection) * 10) / 255;
    CGFloat g = (173.0 / 255.0);// + CGFloat(indexPath.sgRow) * 2) / 255;
    CGFloat b = (207.0 / 255.0);// + CGFloat(indexPath.sgColumn) * 2) / 255;

    textCell.backgroundView.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
    
    textCell.textLabel.text = [NSString stringWithFormat:@"%ld, %ld, %ld", indexPath.sgSection, indexPath.sgColumn, indexPath.sgRow];
    
    return (SwiftGridCell *)textCell;
}

// Header / Footer Views
- (SwiftGridReusableView *)dataGridView:(SwiftGridView *)dataGridView gridHeaderViewForColumn:(NSInteger)column {
    BasicTextReusableView *view = (BasicTextReusableView *)[dataGridView dequeueReusableSupplementaryViewOfKind:@"SwiftGridElementKindHeader" withReuseIdentifier:[BasicTextReusableView reuseIdentifier] atColumn:column];
    
    CGFloat r = (159.0 / 255.0);// + CGFloat(column) * 3) / 255
    CGFloat g = (159.0 / 255.0);// + CGFloat(column) * 3) / 255
    CGFloat b = (160.0 / 255.0);// + CGFloat(column) * 3) / 255
    
    view.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0]; // No BG View!
    
    view.textLabel.text = [NSString stringWithFormat:@"HCol: %ld", column];
    
    return (SwiftGridReusableView *)view;
}

- (SwiftGridReusableView *)dataGridView:(SwiftGridView *)dataGridView gridFooterViewForColumn:(NSInteger)column {
    BasicTextReusableView *view = (BasicTextReusableView *)[dataGridView dequeueReusableSupplementaryViewOfKind:@"SwiftGridElementKindFooter" withReuseIdentifier:[BasicTextReusableView reuseIdentifier] atColumn:column];
    
    CGFloat r = (104.0 / 255.0);// + CGFloat(column) * 3) / 255
    CGFloat g = (153.0 / 255.0);// + CGFloat(column) * 3) / 255
    CGFloat b = (71.0 / 255.0);// + CGFloat(column) * 3) / 255
    
    view.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0]; // No BG View!
    
    view.textLabel.text = [NSString stringWithFormat:@"FCol: %ld", column];
    
    return (SwiftGridReusableView *)view;
}

// Section Header / Footer Views
- (SwiftGridReusableView *)dataGridView:(SwiftGridView *)dataGridView sectionHeaderCellAtIndexPath:(NSIndexPath *)indexPath {
    BasicTextReusableView *view = (BasicTextReusableView *)[dataGridView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[BasicTextReusableView reuseIdentifier] forIndexPath:indexPath];
    
    CGFloat r = (71.0 / 255.0);// + CGFloat(column) * 3) / 255
    CGFloat g = (101.0 / 255.0);// + CGFloat(column) * 3) / 255
    CGFloat b = (198.0 / 255.0);// + CGFloat(column) * 3) / 255
    
    view.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0]; // No BG View!
    
    view.textLabel.text = [NSString stringWithFormat:@"%ld, %ld, %ld", indexPath.sgSection, indexPath.sgColumn, indexPath.sgRow];
    
    return (SwiftGridReusableView *)view;
}

- (SwiftGridReusableView *)dataGridView:(SwiftGridView *)dataGridView sectionFooterCellAtIndexPath:(NSIndexPath *)indexPath {
    BasicTextReusableView *view = (BasicTextReusableView *)[dataGridView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[BasicTextReusableView reuseIdentifier] forIndexPath:indexPath];
    
    CGFloat r = (196.0 / 255.0);// + CGFloat(column) * 3) / 255
    CGFloat g = (102.0 / 255.0);// + CGFloat(column) * 3) / 255
    CGFloat b = (137.0 / 255.0);// + CGFloat(column) * 3) / 255
    
    view.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0]; // No BG View!
    
    view.textLabel.text = [NSString stringWithFormat:@"%ld, %ld, %ld", indexPath.sgSection, indexPath.sgColumn, indexPath.sgRow];
    
    return (SwiftGridReusableView *)view;
}

// Frozen Columns
- (NSInteger)numberOfFrozenColumnsInDataGridView:(SwiftGridView *)dataGridView {
    
    return self.frozenColumns;
}


// MARK: - SwiftGridViewDelegate
- (void)dataGridView:(SwiftGridView *)dataGridView didSelectHeaderAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Selected header indexPath: %ld, %ld, %ld)", indexPath.sgSection, indexPath.sgColumn, indexPath.sgRow);
}

- (void)dataGridView:(SwiftGridView *)dataGridView didDeselectHeaderAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Deselected header indexPath: %ld, %ld, %ld)", indexPath.sgSection, indexPath.sgColumn, indexPath.sgRow);
}

- (void)dataGridView:(SwiftGridView *)dataGridView didSelectFooterAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Selected footer indexPath: %ld, %ld, %ld)", indexPath.sgSection, indexPath.sgColumn, indexPath.sgRow);
}

- (void)dataGridView:(SwiftGridView *)dataGridView didDeselectFooterAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Deselected footer indexPath: %ld, %ld, %ld)", indexPath.sgSection, indexPath.sgColumn, indexPath.sgRow);
}

- (void)dataGridView:(SwiftGridView *)dataGridView didSelectCellAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Selected indexPath: %ld, %ld, %ld)", indexPath.sgSection, indexPath.sgColumn, indexPath.sgRow);
}

- (void)dataGridView:(SwiftGridView *)dataGridView didDeselectCellAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Deselected indexPath: %ld, %ld, %ld)", indexPath.sgSection, indexPath.sgColumn, indexPath.sgRow);
}

- (void)dataGridView:(SwiftGridView *)dataGridView didSelectSectionHeaderAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Selected section header indexPath: %ld, %ld, %ld)", indexPath.sgSection, indexPath.sgColumn, indexPath.sgRow);
}

- (void)dataGridView:(SwiftGridView *)dataGridView didDeselectSectionHeaderAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Deselected section header indexPath: %ld, %ld, %ld)", indexPath.sgSection, indexPath.sgColumn, indexPath.sgRow);
}

- (void)dataGridView:(SwiftGridView *)dataGridView didSelectSectionFooterAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Selected section footer indexPath: %ld, %ld, %ld)", indexPath.sgSection, indexPath.sgColumn, indexPath.sgRow);
}

- (void)dataGridView:(SwiftGridView *)dataGridView didDeselectSectionFooterAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Deselected section footer indexPath: %ld, %ld, %ld)", indexPath.sgSection, indexPath.sgColumn, indexPath.sgRow);
}

- (CGFloat)dataGridView:(SwiftGridView *)dataGridView heightOfRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 55.0;
}

- (CGFloat)dataGridView:(SwiftGridView *)dataGridView widthOfColumnAtIndex:(NSInteger)columnIndex {
    
    return 150.0 + 25.0 * columnIndex;
}

- (CGFloat)heightForGridHeaderInDataGridView:(SwiftGridView *)dataGridView {
    
    return 75.0;
}

- (CGFloat)heightForGridFooterInDataGridView:(SwiftGridView *)dataGridView {
    
    return 55.0;
}

- (CGFloat)dataGridView:(SwiftGridView *)dataGridView heightOfHeaderInSection:(NSInteger)section {
    
    return 75.0;
}

- (CGFloat)dataGridView:(SwiftGridView *)dataGridView heightOfFooterInSection:(NSInteger)section {
    
    return 75.0;
}

@end
