//
//  SearchResultCell.m
//  StoreSearch
//
//  Created by Nguyen Duy Khanh on 3/19/16.
//  Copyright © 2016 Nguyen Duy Khanh. All rights reserved.
//

#import "SearchResultCell.h"

@implementation SearchResultCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    UIView *selectedView = [[UIView alloc]initWithFrame:CGRectZero];
    
    selectedView.backgroundColor = [UIColor colorWithRed:20/255.0f green:160/255.0f blue:160/255.0f alpha:1.0f];
    self.selectedBackgroundView = selectedView;

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
