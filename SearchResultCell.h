//
//  SearchResultCell.h
//  StoreSearch
//
//  Created by Nguyen Duy Khanh on 3/19/16.
//  Copyright © 2016 Nguyen Duy Khanh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchResultCell : UITableViewCell

@property (nonatomic,weak) IBOutlet UILabel *nameLabel;
@property (nonatomic,weak) IBOutlet UILabel *artistNameLabel;
@property (nonatomic,weak) IBOutlet UIImageView *artworkImageView;

@end
