//
//  RZIntrinsicContentSizeTextView.m
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


#import "RZIntrinsicContentSizeTextView.h"
#import "UIView+RZAutoLayoutHelpers.h"
#import "UIView+RZAutoLayoutPriorityHelpers.h"
#import "UIView+RZAutoLayoutReplacementHelpers.h"

static const CGFloat kRZTextViewAnimationDuration = 0.2f;
static const CGFloat kRZTextViewDefaultHeightPriority = 999.0f;

@interface RZIntrinsicContentSizeTextView ()

// Placholder
@property (strong, nonatomic, readwrite) UILabel *placeholderLabel;

// Dynamic Min/Max constraints
@property (weak, nonatomic, readonly) NSLayoutConstraint *rztv_minHeightConstraint;
@property (weak, nonatomic, readonly) NSLayoutConstraint *rztv_maxHeightConstraint;

// Predicate helpers
+ (NSPredicate *)rztv_minConstraintPredicate;
+ (NSPredicate *)rztv_maxConstraintPredicate;

// Size Helpers
- (CGFloat)intrinsicContentHeight;

// Delegate helpers
- (UIView *)layoutView;
- (BOOL)shouldAnimateSizeChange;

// Scroll Helpers
- (BOOL)shouldScrollToBottom;
- (CGPoint)bottomOffset;

@end

@implementation RZIntrinsicContentSizeTextView

@synthesize rztv_minHeightConstraint = _rztv_minHeightConstraint;
@synthesize rztv_maxHeightConstraint = _rztv_maxHeightConstraint;

#pragma mark - Class

+ (NSPredicate *)rztv_minConstraintPredicate
{
    return [NSPredicate predicateWithFormat:@"%K == %@ AND %K == %@",
            NSStringFromSelector(@selector(firstAttribute)), @(NSLayoutAttributeHeight),
            NSStringFromSelector(@selector(relation)), @(NSLayoutRelationGreaterThanOrEqual)];
}

+ (NSPredicate *)rztv_maxConstraintPredicate
{
    return [NSPredicate predicateWithFormat:@"%K == %@ AND %K == %@",
            NSStringFromSelector(@selector(firstAttribute)), @(NSLayoutAttributeHeight),
            NSStringFromSelector(@selector(relation)), @(NSLayoutRelationLessThanOrEqual)];
}

#pragma mark - View Life Cycle

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    self = [super initWithFrame:frame textContainer:textContainer];
    if ( self != nil ) {
        [self configureIntrinsicTextView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ( self != nil ) {
        [self configureIntrinsicTextView];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidChangeNotification
                                                  object:nil];
}

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    [self configurePlaceholder];
    [self adjustHeightIfNeededAnimated:NO];
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self adjustHeightIfNeededAnimated:self.shouldAnimateSizeChange];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(CGRectGetWidth(self.bounds), self.intrinsicContentHeight);
}

#pragma mark - Setters

// custom setters
- (void)setHeightPriority:(CGFloat)heightPriority
{
    if ( _heightPriority != heightPriority ) {
        _heightPriority = heightPriority;

        [self rztv_replacePinnedHeightConstraintWithNewPinnedHeight:self.rztv_pinnedHeightConstraint.constant priority:self.heightPriority];
    }
}

- (void)setPlaceholder:(NSString *)placeholder
{
    if ( ![_placeholder isEqualToString:placeholder] ) {
        _placeholder = placeholder.copy;
        self.placeholderLabel.text = _placeholder;
    }
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder
{
    if ( ![_attributedPlaceholder isEqualToAttributedString:attributedPlaceholder] ) {
        _attributedPlaceholder = attributedPlaceholder.copy;
        self.placeholderLabel.attributedText = _attributedPlaceholder;
    }
}

- (void)setPlaceholderTextColor:(UIColor *)placeholderTextColor
{
    if ( _placeholderTextColor != placeholderTextColor ) {
        _placeholderTextColor = placeholderTextColor;
        self.placeholderLabel.textColor = _placeholderTextColor;
    }
}

#pragma mark - Super Setter Overrides

- (void)setTextContainerInset:(UIEdgeInsets)textContainerInset
{
    [super setTextContainerInset:textContainerInset];
    [self adjustPlaceholderPosition];
    [self scrollToBottom];
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    [self adjustPlaceholderForTextChange];
    [self adjustHeightIfNeededAnimated:self.shouldAnimateSizeChange];
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    self.placeholderLabel.font = font;
}

#pragma mark - Getters

- (NSLayoutConstraint *)rztv_pinnedHeightConstraint
{
    NSLayoutConstraint *rztv_pinnedHeightConstraint = super.rztv_pinnedHeightConstraint;

    // create a height constraint if there isn't one created already
    if ( !rztv_pinnedHeightConstraint ) {
        rztv_pinnedHeightConstraint = [self rztv_pinHeightTo:0.0f priority:self.heightPriority];
    }

    return rztv_pinnedHeightConstraint;
}

// we need these to be dynamic so we have to iterate through these each time we
// have to look it up. So lookup the min/max sparingly
- (NSLayoutConstraint *)rztv_maxHeightConstraint
{
    _rztv_maxHeightConstraint = nil;
    for (NSLayoutConstraint *constraint in [self.constraints filteredArrayUsingPredicate:[[self class] rztv_maxConstraintPredicate]]) {
        if( _rztv_maxHeightConstraint == nil || constraint.constant < _rztv_maxHeightConstraint.constant ) {
            _rztv_maxHeightConstraint = constraint;
        }
    }

    return _rztv_maxHeightConstraint;
}

- (NSLayoutConstraint *)rztv_minHeightConstraint
{
    _rztv_minHeightConstraint = nil;
    for (NSLayoutConstraint *constraint in [self.constraints filteredArrayUsingPredicate:[[self class] rztv_minConstraintPredicate]]) {
            if ( _rztv_minHeightConstraint == nil || constraint.constant > _rztv_minHeightConstraint.constant ) {
            _rztv_minHeightConstraint = constraint;
        }
    }

    return _rztv_minHeightConstraint;
}

#pragma mark - Config

- (void)configureIntrinsicTextView
{
    [self configureDefaults];
    [self configurePlaceholder];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textViewTextDidChange:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:nil];
}

- (void)configureDefaults
{
    _heightPriority = kRZTextViewDefaultHeightPriority;
    _placeholder = nil;
    _attributedPlaceholder = nil;
    _placeholderTextColor = [UIColor lightGrayColor];
    self.layoutManager.allowsNonContiguousLayout = NO;
}

- (void)configurePlaceholder
{
    _placeholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.placeholderLabel.textColor = self.placeholderTextColor;
    self.placeholderLabel.text = self.placeholder;
    self.placeholderLabel.attributedText = self.attributedPlaceholder;
    self.placeholderLabel.font = self.font;
    [self addSubview:self.placeholderLabel];

    // set the constraints, we will update them later
    [self.placeholderLabel rztv_pinLeftSpaceToSuperviewWithPadding:0.0f];
    [self.placeholderLabel rztv_pinTopSpaceToSuperviewWithPadding:0.0f];

    // this will set the placeholder position to the beginning of the document.
    [self adjustPlaceholderPosition];
}

#pragma mark - Intrinsic Size Helpers

// Gets the height of the content that is currently in the TextView
- (CGFloat)intrinsicContentHeight
{
    CGSize sizeThatFits = [self sizeThatFits:CGSizeMake(CGRectGetWidth(self.frame),
                                                        CGFLOAT_MAX)];
    CGFloat newHeight = sizeThatFits.height;

    // store the constraints to avoid extra lookups
    NSLayoutConstraint *rztv_maxHeightConstraint = self.rztv_maxHeightConstraint;
    NSLayoutConstraint *rztv_minHeightConstraint = self.rztv_minHeightConstraint;

    // Consider the min/max height constraints when calculating the height
    if ( rztv_maxHeightConstraint ) {
        newHeight = fmin(newHeight, rztv_maxHeightConstraint.constant);
    }

    if ( rztv_minHeightConstraint ) {
        newHeight = fmax(newHeight, rztv_minHeightConstraint.constant);
    }

    // at the very least we want it the size of the font plus insets
    CGFloat minimum = fmin(self.textContainerInset.top + self.textContainerInset.bottom + self.font.lineHeight, rztv_maxHeightConstraint.constant);

    return fmax(newHeight, minimum);
}

#pragma mark - Delegate Helpers

- (BOOL)shouldAnimateSizeChange
{
    return ( ![self.sizeChangeDelegate respondsToSelector:@selector(intrinsicTextView:shouldAnimateToSize:)] ||
            [self.sizeChangeDelegate intrinsicTextView:self shouldAnimateToSize:self.intrinsicContentSize] );
}

- (UIView *)layoutView
{
    UIView *layoutView = self.superview ?: self;
    if ( [self.sizeChangeDelegate respondsToSelector:@selector(intrinsicTextViewLayoutView:)] ) {
        layoutView = [self.sizeChangeDelegate intrinsicTextViewLayoutView:self];
    }

    return layoutView;
}

#pragma mark - UITextViewNotifications

- (void)textViewTextDidChange:(NSNotification *)notification
{
    // in case there are other textviews showing
    if ( notification.object == self ) {
        [self adjustHeightIfNeededAnimated:self.shouldAnimateSizeChange];
        [self adjustPlaceholderForTextChange];
    }
}

#pragma mark - Adjusters

// Checks the height of the textview and adjusts if needed.
- (void)adjustHeightIfNeededAnimated:(BOOL)animated
{
    CGFloat intrinsicHeight = self.intrinsicContentHeight;
    BOOL intrinsicHeightChanged = intrinsicHeight != self.rztv_pinnedHeightConstraint.constant;
    BOOL isShrinking = intrinsicHeight < self.rztv_pinnedHeightConstraint.constant;
    BOOL isIgnoringGrowingConstraint = self.rztv_pinnedHeightConstraint.constant > CGRectGetHeight(self.bounds);

    if ( intrinsicHeightChanged &&
        ( !isIgnoringGrowingConstraint  || isShrinking ) ) {

        self.rztv_pinnedHeightConstraint.constant = intrinsicHeight;

        [self setNeedsLayout];

        void(^adjustHeightBlock)() = ^{
            [self.layoutView layoutIfNeeded];

            // This probably should scroll to the selected caret range to be more accurate
            // however this works because we only force the scroll when we are changing
            // the size of the textview. Once we are at the max size we allow
            // the native implementation take care of scrolling.
            // TODO: Change to scroll to caret range
            if ( self.shouldScrollToBottom ) {
                [self scrollToBottom];
            }
        };

        if ( animated ) {
            [UIView animateWithDuration:kRZTextViewAnimationDuration
                             animations:adjustHeightBlock];
        }
        else {
            adjustHeightBlock();
        }
    }
}

// Adjusts whether the placeholder is hidden or not
- (void)adjustPlaceholderForTextChange
{
    self.placeholderLabel.hidden = self.text.length > 0;
}

- (void)adjustPlaceholderPosition
{
    // Set the start point to the beginning of the document.
    // This is the best way to get the cursor starting point
    // which is where to place the placeholder view
    CGRect startRect = [self firstRectForRange:[self textRangeFromPosition:self.beginningOfDocument toPosition:self.beginningOfDocument]];

    if ( !CGRectIsNull(startRect) ) {
        self.placeholderLabel.rztv_pinnedLeftConstraint.constant = CGRectGetMinX(startRect);
        self.placeholderLabel.rztv_pinnedTopConstraint.constant = CGRectGetMinY(startRect);
    }
}

#pragma mark - Scroll Helpers

// Only force the scroll when it is still growing and we don't have a large bottom offset.
// Once we have to scroll over the size of the font it will start clipping
// so allow for the UITextView underlying scrollview scroll itself
- (BOOL)shouldScrollToBottom
{
    return self.bottomOffset.y < self.font.lineHeight;
}

- (CGPoint)bottomOffset
{
    return CGPointMake(0.0f, self.contentSize.height - CGRectGetHeight(self.bounds) + fabs(self.textContainerInset.top - self.textContainerInset.bottom));
}

- (void)scrollToBottom
{
    [self setContentOffset:self.bottomOffset animated:NO];
}

@end
