//
//  UIView+RZMinMaxAutoLayoutHelpers.h
//  RZIntrinsicContentSizeTextView
//
//  Created by Derek Ostrander on 3/20/15.
//  Copyright (c) 2015 Derek Ostrander. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (RZMinMaxAutoLayoutHelpers)

// getters
- (NSLayoutConstraint *)rztv_pinnedMinHeightConstraint;
- (NSLayoutConstraint *)rztv_pinnedMaxHeightConstraint;

// generators
- (NSLayoutConstraint *)rztv_pinMinHeightTo:(CGFloat)height;
- (NSLayoutConstraint *)rztv_pinMaxHeightTo:(CGFloat)height;

@end
