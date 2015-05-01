//
//  RZViewController.m
//  RZIntrinsicContentSizeTextView
//
//  Created by Derek Ostrander on 03/16/2015.
//  Copyright (c) 2014 Derek Ostrander. All rights reserved.
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

#import "RZViewController.h"

#import "RZIntrinsicContentSizeTextView.h"

@interface RZViewController () <RZIntrinsicContentSizeTextViewSizeChangedDelegate>

@property (strong, nonatomic, readwrite) RZIntrinsicContentSizeTextView *textView;

@property (strong, nonatomic) NSLayoutConstraint *bottomConstraint;

@end

@implementation RZViewController

#pragma mark - Object Lifecycle

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor lightGrayColor];

    // add textview to view
    self.textView =  [[RZIntrinsicContentSizeTextView alloc] initWithFrame:CGRectZero];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.textView];

    // set textview attributes
    self.textView.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    self.textView.sizeChangeDelegate = self;

    // set placeholder attributes
    self.textView.placeholder = @"Hey hey hey";
    self.textView.placeholderTextColor = [UIColor redColor];

    // Pin the textview to the bottom of the view
    NSDictionary *views = NSDictionaryOfVariableBindings(_textView,self.view);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_textView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.textView
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0f
                                                          constant:0.0f];
    [self.view addConstraint:self.bottomConstraint];

    // set min/max constraints
    NSLayoutConstraint *minHeightConstraint = [NSLayoutConstraint constraintWithItem:self.textView
                                                                           attribute:NSLayoutAttributeHeight
                                                                           relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0f
                                                                            constant:40.0f];
    [self.textView addConstraint:minHeightConstraint];

    NSLayoutConstraint *maxHeightConstraint = [NSLayoutConstraint constraintWithItem:self.textView
                                                                           attribute:NSLayoutAttributeHeight
                                                                           relatedBy:NSLayoutRelationLessThanOrEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0f
                                                                            constant:100.0f];
    [self.textView addConstraint:maxHeightConstraint];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moveKeyboard:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moveKeyboard:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

}

#pragma mark - UIKeyboard Notifications

- (void)moveKeyboard:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat keyboardEndPoint = CGRectGetMinY([keyboardInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue]);
    CGFloat keyboardTotalHeight = CGRectGetHeight([keyboardInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue]);
    CGFloat duration = [keyboardInfo[UIKeyboardAnimationCurveUserInfoKey] floatValue];
    UIViewAnimationOptions animationOptions = [keyboardInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16;

    self.bottomConstraint.constant = ( keyboardEndPoint != CGRectGetHeight([UIScreen mainScreen].bounds) ) ? keyboardTotalHeight : 0.0f;
    [self.view setNeedsLayout];

    [UIView animateWithDuration:duration delay:0.0f options:animationOptions animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

#pragma mark - RZIntrinsicContentSizeTextViewSizeChangedDelegate

- (BOOL)intrinsicTextView:(RZIntrinsicContentSizeTextView *)textView shouldAnimateToSize:(CGSize)toSize
{
    return YES;
}

- (UIView *)intrinsicTextViewLayoutView:(RZIntrinsicContentSizeTextView *)textView
{
    return self.view;
}

@end
