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
- (NSLayoutConstraint *)rz_pinnedMinHeightConstraint;
- (NSLayoutConstraint *)rz_pinnedMaxHeightConstraint;

// generators
- (NSLayoutConstraint *)rz_pinMinHeightTo:(CGFloat)height;
- (NSLayoutConstraint *)rz_pinMaxHeightTo:(CGFloat)height;

@end
