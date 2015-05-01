//
//  UIView+RZAutoLayoutHelpers.m
//  Pods
//
//  Created by Derek Ostrander on 3/16/15.

//  Copyright (c) 2015 Raizlabs and other contributors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "UIView+RZAutoLayoutHelpers.h"

@implementation UIView (RZAutoLayoutHelpers)

# pragma mark - Helpers

- (BOOL)rztv_constraintIsWithSuperview:(NSLayoutConstraint *)constraint
{
    return ((constraint.firstItem == self && constraint.secondItem == self.superview) ||
            (constraint.firstItem == self.superview && constraint.secondItem == self));
}

+ (UIView *)rztv_commonAncestorForViews:(NSArray *)views
{
    NSParameterAssert([views count] > 0);

    if ( [views count] == 1 ) {
        return [views firstObject];
    }

    // First, build a list of view hierarchies, where each element is a list containing the hierarhcy all the way up from each view to the top
    NSMutableArray *viewHierarchies = [[NSMutableArray alloc] initWithCapacity:[views count]];
    for ( UIView *view in views ) {
        NSMutableArray *viewHierarchy = [NSMutableArray array];

        UIView *viewCursor = view;
        while ( viewCursor != nil ) {
            [viewHierarchy addObject:viewCursor];
            viewCursor = [viewCursor superview];
        }

        [viewHierarchies addObject:viewHierarchy];
    }

    // Next, iterate through the view hierarchies. Find the first element that they all have in common. Note that this is n^2, but is quite unlikely this will ever hamper performance because view hierarchies should generally be quite shallow.
    UIView *candidateCommonAncestor = nil;
    NSArray *firstViewHierarchy = [viewHierarchies firstObject];
    NSArray *otherViewHierarchies = [viewHierarchies subarrayWithRange:NSMakeRange(1, [viewHierarchies count] - 1)];

    for ( UIView *view in firstViewHierarchy ) {
        BOOL commonAncestorMatches = YES;

        for ( NSArray *otherViewHierarchy in otherViewHierarchies ) {
            if ( [otherViewHierarchy containsObject:view] == NO ) {
                commonAncestorMatches = NO;
                break;
            }
        }

        if ( commonAncestorMatches ) {
            candidateCommonAncestor = view;
            break;
        }
    }

    return candidateCommonAncestor;
}

# pragma mark - Constraint Accessors

- (NSLayoutConstraint *)rztv_pinnedHeightConstraint
{
    __block NSLayoutConstraint *constraint = nil;
    [self.constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *c, NSUInteger idx, BOOL *stop) {
        if (c.firstItem == self &&
            c.firstAttribute == NSLayoutAttributeHeight &&
            c.secondAttribute == NSLayoutAttributeNotAnAttribute &&
            c.relation == NSLayoutRelationEqual)
        {
            constraint = c;
            *stop = YES;
        }
    }];
    return constraint;
}

- (NSLayoutConstraint*)rztv_pinnedTopConstraint
{
    if (self.superview == nil) return nil;

    __block NSLayoutConstraint *constraint = nil;
    [[[self superview] constraints] enumerateObjectsUsingBlock:^(NSLayoutConstraint *c, NSUInteger idx, BOOL *stop) {
        if ([self rztv_constraintIsWithSuperview:c] &&
            c.firstAttribute == NSLayoutAttributeTop &&
            c.secondAttribute == NSLayoutAttributeTop &&
            c.relation == NSLayoutRelationEqual)
        {
            constraint = c;
            *stop = YES;
        }
    }];
    return constraint;
}

- (NSLayoutConstraint*)rztv_pinnedLeftConstraint
{
    if (self.superview == nil) return nil;

    __block NSLayoutConstraint *constraint = nil;
    [[[self superview] constraints] enumerateObjectsUsingBlock:^(NSLayoutConstraint *c, NSUInteger idx, BOOL *stop) {
        if ([self rztv_constraintIsWithSuperview:c] &&
            (c.firstAttribute == NSLayoutAttributeLeft || c.firstAttribute == NSLayoutAttributeLeading) &&
            (c.secondAttribute == NSLayoutAttributeLeft || c.secondAttribute == NSLayoutAttributeLeading) &&
            c.relation == NSLayoutRelationEqual)
        {
            constraint = c;
            *stop = YES;
        }
    }];
    return constraint;
}

- (NSLayoutConstraint*)rztv_pinnedRightConstraint
{
    if (self.superview == nil) return nil;

    __block NSLayoutConstraint *constraint = nil;
    [[[self superview] constraints] enumerateObjectsUsingBlock:^(NSLayoutConstraint *c, NSUInteger idx, BOOL *stop) {
        if ([self rztv_constraintIsWithSuperview:c] &&
            (c.firstAttribute == NSLayoutAttributeRight  || c.firstAttribute == NSLayoutAttributeTrailing) &&
            (c.secondAttribute == NSLayoutAttributeRight || c.secondAttribute == NSLayoutAttributeTrailing) &&
            c.relation == NSLayoutRelationEqual)
        {
            constraint = c;
            *stop = YES;
        }
    }];
    return constraint;
}

- (NSLayoutConstraint*)rztv_pinnedBottomConstraint
{
    if (self.superview == nil) return nil;

    __block NSLayoutConstraint *constraint = nil;
    [[[self superview] constraints] enumerateObjectsUsingBlock:^(NSLayoutConstraint *c, NSUInteger idx, BOOL *stop) {
        if ([self rztv_constraintIsWithSuperview:c] &&
            c.firstAttribute == NSLayoutAttributeBottom &&
            c.secondAttribute == NSLayoutAttributeBottom &&
            c.relation == NSLayoutRelationEqual)
        {
            constraint = c;
            *stop = YES;
        }
    }];
    return constraint;
}

- (NSLayoutConstraint *)rztv_pinHeightTo:(CGFloat)height
{
    NSLayoutConstraint *h = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0f
                                                          constant:height];
    [self addConstraint:h];

    return h;
}

- (NSLayoutConstraint *)rztv_pinTopSpaceToSuperviewWithPadding:(CGFloat)padding
{
    NSAssert(self.superview != nil, @"Must have superview");

    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.superview
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0f
                                                          constant:padding];
    [self.superview addConstraint:c];

    return c;
}

- (NSLayoutConstraint *)rztv_pinLeftSpaceToSuperviewWithPadding:(CGFloat)padding
{
    NSAssert(self.superview != nil, @"Must have superview");

    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.superview
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0f
                                                          constant:padding];
    [self.superview addConstraint:c];

    return c;
}

- (NSLayoutConstraint *)rztv_pinBottomSpaceToSuperviewWithPadding:(CGFloat)padding
{
    NSAssert(self.superview != nil, @"Must have superview");

    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.superview
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0f
                                                          constant:-padding];
    [self.superview addConstraint:c];

    return c;
}

- (NSLayoutConstraint *)rztv_pinRightSpaceToSuperviewWithPadding:(CGFloat)padding
{
    NSAssert(self.superview != nil, @"Must have superview");

    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeRight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.superview
                                                         attribute:NSLayoutAttributeRight
                                                        multiplier:1.0f
                                                          constant:-padding];
    [self.superview addConstraint:c];

    return c;
}

@end
