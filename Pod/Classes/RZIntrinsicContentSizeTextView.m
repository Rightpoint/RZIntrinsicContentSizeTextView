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

// Semi-Dynamic Min/Max constraints
@property (weak, nonatomic, readonly) NSLayoutConstraint *rz_minHeightConstraint;
@property (weak, nonatomic, readonly) NSLayoutConstraint *rz_maxHeightConstraint;

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

@synthesize rz_minHeightConstraint = _rz_minHeightConstraint;
@synthesize rz_maxHeightConstraint = _rz_maxHeightConstraint;

#pragma mark - View Life Cycle

- (id)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    self = [super initWithFrame:frame textContainer:textContainer];
    if ( self ) {
        [self configureIntrinsicTextView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ( self ) {
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

        [self rz_replacePinnedHeightConstraintWithNewPinnedHeight:self.intrinsicContentHeight priority:self.heightPriority];
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

#pragma mark - Constraint Overrides

- (void)removeConstraint:(NSLayoutConstraint *)constraint
{
    if ( constraint == self.rz_minHeightConstraint ) {
        _rz_minHeightConstraint = nil;
    }

    if ( constraint == self.rz_maxHeightConstraint ) {
        _rz_maxHeightConstraint = nil;
    }

    [super removeConstraint:constraint];
}

- (void)removeConstraints:(NSArray *)constraints
{
    if ( _rz_minHeightConstraint && [constraints containsObject:self.rz_minHeightConstraint] ) {
        _rz_minHeightConstraint = nil;
    }

    if ( _rz_maxHeightConstraint && [constraints containsObject:self.rz_maxHeightConstraint] ) {
        _rz_maxHeightConstraint = nil;
    }

    [super removeConstraints:constraints];
}

#pragma mark - Getters

- (NSLayoutConstraint *)rz_pinnedHeightConstraint
{
    NSLayoutConstraint *rz_pinnedHeightConstraint = super.rz_pinnedHeightConstraint;

    // create a height constraint if there isn't one created already
    if ( !rz_pinnedHeightConstraint ) {
        rz_pinnedHeightConstraint = [self rz_pinHeightTo:self.intrinsicContentHeight priority:self.heightPriority];
    }

    return rz_pinnedHeightConstraint;
}

// min/max constraints need to be dynamic incase they externally get removed
// however if more are added they are not taken into account, might want to change this in the future
- (NSLayoutConstraint *)rz_maxHeightConstraint
{
    if ( !_rz_maxHeightConstraint ) {
        _rz_maxHeightConstraint = [self constraintForFirstAttribute:NSLayoutAttributeHeight relation:NSLayoutRelationLessThanOrEqual];
    }

    return _rz_maxHeightConstraint;
}

- (NSLayoutConstraint *)rz_minHeightConstraint
{
    if ( !_rz_minHeightConstraint ) {
        _rz_minHeightConstraint = [self constraintForFirstAttribute:NSLayoutAttributeHeight relation:NSLayoutRelationGreaterThanOrEqual];
    }

    return _rz_minHeightConstraint;
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
    [self.placeholderLabel rz_pinLeftSpaceToSuperviewWithPadding:0.0f];
    [self.placeholderLabel rz_pinTopSpaceToSuperviewWithPadding:0.0f];

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

    // Consider the min/max height constraints when calculating the height
    if ( self.rz_maxHeightConstraint ) {
        newHeight = fminf(newHeight, self.rz_maxHeightConstraint.constant);
    }

    if ( self.rz_minHeightConstraint ) {
        newHeight = fmaxf(newHeight, self.rz_minHeightConstraint.constant);
    }

    // at the very least we want it the size of the font plus insets
    CGFloat minimum = self.textContainerInset.top + self.textContainerInset.bottom + self.font.lineHeight;

    return fmaxf(newHeight, minimum);
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
    BOOL intrinsicHeightChanged = intrinsicHeight != self.rz_pinnedHeightConstraint.constant;
    BOOL isShrinking = intrinsicHeight < self.rz_pinnedHeightConstraint.constant;
    BOOL isIgnoringGrowingConstraint = self.rz_pinnedHeightConstraint.constant > CGRectGetHeight(self.bounds);

    if ( intrinsicHeightChanged &&
        ( !isIgnoringGrowingConstraint  || isShrinking ) ) {

        self.rz_pinnedHeightConstraint.constant = intrinsicHeight;

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
        self.placeholderLabel.rz_pinnedLeftConstraint.constant = CGRectGetMinX(startRect);
        self.placeholderLabel.rz_pinnedTopConstraint.constant = CGRectGetMinY(startRect);
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
    return CGPointMake(0.0f, self.contentSize.height - CGRectGetHeight(self.bounds) + fabsf(self.textContainerInset.top - self.textContainerInset.bottom));
}

- (void)scrollToBottom
{
    [self setContentOffset:self.bottomOffset animated:NO];
}

#pragma mark - Private

- (NSLayoutConstraint *)constraintForFirstAttribute:(NSLayoutAttribute)attribute relation:(NSLayoutRelation)relation
{
    for (NSLayoutConstraint *constraint in self.constraints) {
        if ( constraint.firstAttribute == attribute && constraint.relation  == relation ) {
            return constraint;
        }
    }
    
    return nil;
}

@end
