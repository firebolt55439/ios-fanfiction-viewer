//
//  MasterViewCellTableViewCell.m
//  Fanfiction
//
//  Created by Sumer Kohli on 12/19/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "MasterViewCellTableViewCell.h"

@implementation MasterViewCellTableViewCell

@synthesize titleLabel = _titleLabel;
@synthesize detailLabel = _detailLabel;
@synthesize imageView = _imageView;

- (void)awakeFromNib {
    // Initialization code
    self.descriptionLabel.adjustsFontSizeToFitWidth = YES;
    self.descriptionLabel.minimumScaleFactor = 0.5f;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
