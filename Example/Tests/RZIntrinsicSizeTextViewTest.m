//
//  RZIntrinsicContentSizeTextViewTest.m
//  RZIntrinsicContentSizeTextView
//
//  Created by Derek Ostrander on 3/16/15.
//  Copyright (c) 2015 Derek Ostrander. All rights reserved.
//

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

#define PLACEHOLDER_SHOWING_TEST ( XCTAssertFalse(self.textView.placeholderLabel.hidden, @"Placeholder should be showing.") )
#define PLACEHOLDER_HIDDEN_TEST  ( XCTAssertTrue(self.textView.placeholderLabel.hidden, @"Placeholder should be hidden.") )

// Copied from .m file so we can expose this here
static const CGFloat kRZTextViewDefaultHeightPriority = 999.0f;

@interface RZIntrinsicContentSizeTextView (TestExtensions)

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

@interface RZIntrinsicContentSizeTextViewTest : XCTestCase <RZIntrinsicContentSizeTextViewSizeChangedDelegate>

@property (strong, nonatomic) RZIntrinsicContentSizeTextView *textView;
@property (strong, nonatomic) UIView *layoutView;
@property (assign, nonatomic) BOOL animate;

@end

@implementation RZIntrinsicContentSizeTextViewTest

- (void)setUp {
    [super setUp];
    self.textView = [[RZIntrinsicContentSizeTextView alloc] initWithFrame:CGRectMake(0, 0, 200, 30) textContainer:nil];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.layoutView = [[UIView alloc] initWithFrame:CGRectZero];
    self.animate = NO;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.textView = nil;
    self.layoutView = nil;
    self.animate = NO;
    [super tearDown];
}

- (void)testDefaults
{
    // expected values
    XCTAssertNil(self.textView.placeholder, @"Placeholder should be nil");
    XCTAssertNil(self.textView.attributedPlaceholder, @"Attributed Placeholder should be nil");
    XCTAssertNil(self.textView.sizeChangeDelegate, @"Size change delegate should be nil");
    XCTAssertNil(self.textView.delegate, @"Size change delegate should be nil");
    XCTAssertEqual(self.textView.heightPriority, kRZTextViewDefaultHeightPriority, @"Height priority should be equal to kRZTextViewDefaultHeightPriority");
    XCTAssertEqual(self.textView.heightPriority, self.textView.rz_pinnedHeightConstraint.priority, @"Height priority should be equal to the textview's height constraint priority");

    // actual view values vs expected
    XCTAssertEqual(self.textView.text.length, 0, @"There shouldn't be text in the textView");
    XCTAssertEqual(self.textView.placeholderLabel.text.length, 0, @"There shouldn't be text in the placeholderLabel");
    XCTAssertEqual(self.textView.placeholderLabel.attributedText.length, 0, @"There shouldn't be attributed text in the placeholderLabel");
    XCTAssertEqual(self.textView.placeholderLabel.textColor, [UIColor lightGrayColor], @"Placeholder text color should be light gray");
    XCTAssertTrue(self.textView.shouldAnimateSizeChange, @"Should animate size change by default");

    // constraint
    XCTAssertNotNil(self.textView.rz_pinnedHeightConstraint, @"Height constraint should NEVER be nil");
    XCTAssertEqual(self.textView.rz_pinnedHeightConstraint.priority, kRZTextViewDefaultHeightPriority, @"Height constraint should have a 999.0f priority");
    PLACEHOLDER_SHOWING_TEST;
}

- (void)testSizeChangeDelegateHelpers
{
    UIView *superview = [[UIView alloc] initWithFrame:CGRectZero];
    [self layoutViewTests:superview];

    self.textView.sizeChangeDelegate = self;
    XCTAssertEqual(self.textView.sizeChangeDelegate, self, @"SizeChangeDelegate should be self");
    XCTAssertEqual(self.textView.layoutView, self.layoutView, @"LayoutView should be the layoutView we specify");
    XCTAssertFalse(self.textView.shouldAnimateSizeChange, @"Shouldn't animate size change");
    self.animate = YES;
    XCTAssertTrue(self.textView.shouldAnimateSizeChange, @"Should animate size change");

    self.textView.sizeChangeDelegate = nil;
    [self layoutViewTests:superview];
}

- (void)testIntrinsicContentHeight
{
    self.textView.text = nil;
    XCTAssertEqual(self.textView.intrinsicContentHeight, 30, @"Should be 30");
    NSLayoutConstraint *min = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:35.0f];
    [self.textView addConstraint:min];
    XCTAssertEqual(self.textView.rz_minHeightConstraint, min, @"The minimum constraint we just added should be the same as the one we find in the textview");

    // Only min
    XCTAssertEqual(self.textView.intrinsicContentHeight, min.constant, @"Textview should be set to the minimum constraint");
    self.textView.text = kRZLongText;
    XCTAssertGreaterThan(self.textView.intrinsicContentHeight, min.constant, @"Textview with text should be higher then minimum constraint");
    self.textView.text = nil;
    XCTAssertEqual(self.textView.intrinsicContentHeight, min.constant, @"Textview should be set to the minimum constraint");

    [self.textView removeConstraint:min];
    XCTAssertEqual(self.textView.intrinsicContentHeight, 30, @"Should be 30");

    // Only max
    NSLayoutConstraint *max = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:40.0f];
    [self.textView addConstraint:max];
    XCTAssertEqual(self.textView.rz_maxHeightConstraint, max, @"The maximum constraint we just added should be the same as the one we find in the textview");

    // Only max
    self.textView.text = nil;
    XCTAssertLessThan(self.textView.intrinsicContentHeight, max.constant, @"Intrinsic Height should be less than maximum");
    XCTAssertLessThan(CGRectGetHeight(self.textView.bounds), max.constant, @"TextView should be less than maximum");

    self.textView.text = kRZLongText;
    XCTAssertEqual(self.textView.intrinsicContentHeight, max.constant, @"Intrinsic Height should be set to maximum constraint");

    self.textView.text = nil;
    XCTAssertLessThan(self.textView.intrinsicContentHeight, max.constant, @"Intrinsic Height should be less than maximum");
    XCTAssertLessThan(CGRectGetHeight(self.textView.bounds), max.constant, @"TextView should be less than maximum");
    [self.textView removeConstraint:max];

    self.textView.text = kRZLongText;
    XCTAssertGreaterThan(self.textView.intrinsicContentHeight, max.constant, @"Intrinsic height should now be more thna old max");
}

- (void)testHeightPriority
{
    XCTAssertEqual(self.textView.heightPriority, kRZTextViewDefaultHeightPriority, @"Height priority should be equal to the textview's height constraint priority");
    XCTAssertEqual(self.textView.rz_pinnedHeightConstraint.priority, kRZTextViewDefaultHeightPriority, @"Pinned Height priority should be equal to the textview's height constraint priority");
    XCTAssertEqual(self.textView.heightPriority, self.textView.rz_pinnedHeightConstraint.priority, @"Height priority should be equal to the textview's height constraint priority");

    self.textView.heightPriority = UILayoutPriorityDefaultLow;

    XCTAssertEqual(self.textView.heightPriority, UILayoutPriorityDefaultLow, @"Height priority should be low");
    XCTAssertEqual(self.textView.rz_pinnedHeightConstraint.priority, UILayoutPriorityDefaultLow, @"Pinned Height priority should be low");
    XCTAssertEqual(self.textView.heightPriority, self.textView.rz_pinnedHeightConstraint.priority, @"Pinned height constraint priority should same as height priority");
}

- (void)testPlaceholder
{
    XCTAssertEqual(self.textView.placeholderLabel.text, self.textView.placeholder, @"PlaceholderLabel.text and placeholder should be the same");

    NSString *placeholder = @"RZIntrinsicContentSizeTextView";
    self.textView.placeholder = placeholder;

    XCTAssertEqual(self.textView.placeholder, placeholder, @"Should actually set the placeholder variable");
    XCTAssertEqual(self.textView.placeholderLabel.text, placeholder, @"PlaceholderLabel.text should be RZIntrinsicContentSizeTextView");
    XCTAssertEqual(self.textView.placeholderLabel.text, self.textView.placeholder, @"PlaceholderLabel.text and placeholder should be the same");

    UIFont *font = [UIFont boldSystemFontOfSize:14.5f];
    self.textView.font = font;
    XCTAssertEqual(self.textView.font, font, @"Should actually set textView font");
    XCTAssertEqual(self.textView.placeholderLabel.font, font, @"Should sent placeholderFont too");
}

- (void)testPlaceholderTextColor
{
    // make sure they are synced before settings
    XCTAssertEqual(self.textView.placeholderLabel.textColor, self.textView.placeholderTextColor, @"PlaceholderLabel.textColor and placeholderTextColor should be the same");

    UIColor *placeholderTextColor = [UIColor redColor];
    self.textView.placeholderTextColor = placeholderTextColor;

    XCTAssertEqual(self.textView.placeholderTextColor, placeholderTextColor, @"Should actually set placeholderTextColor variable");
    XCTAssertEqual(self.textView.placeholderLabel.textColor, placeholderTextColor, @"PlaceholderLabel.textColor should equal the new textColor");
    XCTAssertEqual(self.textView.placeholderLabel.textColor, self.textView.placeholderTextColor, @"Textcolor should be synced");
}

- (void)testAttributedPlaceholder
{
    XCTAssertEqual(self.textView.placeholderLabel.attributedText, self.textView.attributedPlaceholder, @"PlaceholderLabel.attributedText and attributedPlaceholder should be the same");

    NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"This is cool"
                                                                                attributes:@{
                                                                                             NSForegroundColorAttributeName : [UIColor blueColor]
                                                                                             }];
    self.textView.attributedPlaceholder = attributedPlaceholder;

    XCTAssertEqual(self.textView.attributedPlaceholder, attributedPlaceholder, @"Should actually set attributedPlaceholder");
    XCTAssert([self.textView.placeholderLabel.attributedText isEqualToAttributedString:attributedPlaceholder], @"Should set the placeholderLabel.attributedText");
    XCTAssert([self.textView.placeholderLabel.attributedText isEqualToAttributedString:self.textView.placeholderLabel.attributedText], @"PlaceholderLabel.attributedText and attributedPlaceholder should be the same");
}

- (void)testRemoveConstraint
{
    XCTAssertNil(self.textView.rz_minHeightConstraint, @"Min height constraint shoulnd't have been set yet");
    XCTAssertNil(self.textView.rz_maxHeightConstraint, @"Max height constraint shoulnd't have been set yet");

    NSLayoutConstraint *minConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:30.0f];
    NSLayoutConstraint *maxConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:90.0f];

    [self.textView addConstraints:@[minConstraint, maxConstraint]];

    XCTAssertEqual(self.textView.rz_minHeightConstraint, minConstraint, @"Min constraint should have been set");
    XCTAssertEqual(self.textView.rz_maxHeightConstraint, maxConstraint, @"Max constraint should have been set");

    [self.textView removeConstraint:minConstraint];
    XCTAssertNil(self.textView.rz_minHeightConstraint, @"Min height constraint should be niled");

    [self.textView removeConstraint:maxConstraint];
    XCTAssertNil(self.textView.rz_maxHeightConstraint, @"Max height constraint should be niled");
}

- (void)testRemoveConstraints
{
    XCTAssertNil(self.textView.rz_minHeightConstraint, @"Min height constraint shoulnd't have been set yet");
    XCTAssertNil(self.textView.rz_maxHeightConstraint, @"Max height constraint shoulnd't have been set yet");

    NSLayoutConstraint *minConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:30.0f];
    NSLayoutConstraint *maxConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:90.0f];

    [self.textView addConstraints:@[minConstraint, maxConstraint]];

    XCTAssertEqual(self.textView.rz_minHeightConstraint, minConstraint, @"Min constraint should have been set");
    XCTAssertEqual(self.textView.rz_maxHeightConstraint, maxConstraint, @"Max constraint should have been set");

    [self.textView removeConstraints:@[minConstraint, maxConstraint]];
    XCTAssertNil(self.textView.rz_minHeightConstraint, @"Min height constraint should be niled");
    XCTAssertNil(self.textView.rz_maxHeightConstraint, @"Max height constraint should be niled");
}

- (void)testAdjustPlaceholderHidden
{
    XCTAssertFalse(self.textView.placeholderLabel.hidden, @"Placeholder label should be shown");
    self.textView.text = nil;
    XCTAssertFalse(self.textView.placeholderLabel.hidden, @"Placeholder label should be shown");
    self.textView.text = @"";
    XCTAssertFalse(self.textView.placeholderLabel.hidden, @"Placeholder label should be shown");
    [self.textView insertText:@""];
    XCTAssertFalse(self.textView.placeholderLabel.hidden, @"Placeholder label should be shown");

    self.textView.text = nil;
    XCTAssertFalse(self.textView.placeholderLabel.hidden, @"Placeholder label should be shown");
    self.textView.text = @"Hey";
    XCTAssertTrue(self.textView.placeholderLabel.hidden, @"Placeholder label should be hidden");

    self.textView.text = nil;
    XCTAssertFalse(self.textView.placeholderLabel.hidden, @"Placeholder label should be shown");
    [self.textView insertText:@"H"];
    XCTAssertTrue(self.textView.placeholderLabel.hidden, @"Placeholder label should be hidden");

    [self.textView deleteBackward];
    XCTAssertFalse(self.textView.placeholderLabel.hidden, @"Placeholder label should be shown");
}

#pragma mark - RZIntrinsicContentSizeTextViewSizeChangedDelegate

- (UIView *)intrinsicTextViewLayoutView:(RZIntrinsicContentSizeTextView *)textView
{
    return self.layoutView;
}

- (BOOL)intrinsicTextView:(RZIntrinsicContentSizeTextView *)textView shouldAnimateToSize:(CGSize)toSize
{
    return self.animate;
}

- (void)layoutViewTests:(UIView *)superview
{
    XCTAssertEqual(self.textView.layoutView, self.textView, @"Textview's layoutview should be self");
    [superview addSubview:self.textView];
    XCTAssertEqual(self.textView.layoutView, superview, @"Textview's layoutView should be superview");
    [self.textView removeFromSuperview];
    XCTAssertEqual(self.textView.layoutView, self.textView, @"Textview's layoutview should be self");
}

@end