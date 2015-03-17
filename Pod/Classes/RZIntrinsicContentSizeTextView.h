//
//  RZIntrinsicContentSizeTextView.h
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

@import UIKit;

@protocol RZIntrinsicContentSizeTextViewSizeChangedDelegate;

/**
 *  This is a UITextView subclass that will grow and shrink with it's intrinsicContentSize.
 */
IB_DESIGNABLE
@interface RZIntrinsicContentSizeTextView : UITextView

/**
 *  Priority for the height constraint of the UITextView.
 *  @note this may have to be changed if you have other constraints being placed on textview 
 *  that the height constraint will need to give or vice versa.
 *  @default is 999.0f
 */
@property (assign, nonatomic, readwrite) IBInspectable CGFloat heightPriority;

/**
 *  Set this to have placeholder text
 */
@property (copy, nonatomic, readwrite) IBInspectable NSString *placeholder;

/**
 *  Custom textcolor of the placeholder
 */
@property (strong, nonatomic, readwrite) IBInspectable UIColor *placeholderTextColor;

/**
 *  Set this to have attributed placeholder text
 */
@property (copy, nonatomic, readwrite) NSAttributedString *attributedPlaceholder;

/**
 *  Delegate to have more fine tuned control for if/when/how it should change it's size.
 *  @note in many instances you won't have to use this.
 */
@property (weak, nonatomic, readwrite) id<RZIntrinsicContentSizeTextViewSizeChangedDelegate> sizeChangeDelegate;

@end

@protocol RZIntrinsicContentSizeTextViewSizeChangedDelegate <NSObject>

@optional

/**
 *  @param textView The textview that is about to change size
 *  @param toSize   The size it is projected to change to
 *
 *  @return Whether or not the textview should animate it's size change. (Default is YES)
 *  @note this defaults to YES
 */
- (BOOL)intrinsicTextView:(RZIntrinsicContentSizeTextView *)textView shouldAnimateToSize:(CGSize)toSize;

/**
 *  The view that is called during layoutIfNeeded to animate correctly.
 *  @note this is only needed if you are seeing clipping during your animations
 *
 *  @param textView The textview that is about to change size
 *
 *  @return The view that gets called for layoutIfNeeded
 *  @note this defaults to the intrinsicTextView's superview
 */
- (UIView *)intrinsicTextViewLayoutView:(RZIntrinsicContentSizeTextView *)textView;

// TODO: Implement these
///**
// *  @param textView The textview that is about to change size
// *  @param toSize   The size it is projected to change to
// *
// *  @return Whether or not the textview should change to it's new size
// *  @note this defaults to YES
// */
//- (BOOL)intrinsicTextView:(RZIntrinsicContentSizeTextView *)textView shouldChangeToSize:(CGSize)toSize;
//
///**
// *  Called before the size change
// *
// *  @param textView The textview that is about to change size
// *  @param toSize   The size it is projected to change to
// */
//- (void)intrinsicTextView:(RZIntrinsicContentSizeTextView *)textView willChangeToSize:(CGSize)toSize;
//
///**
// *  Called after the size change
// *
// *  @param textView The textview that is about to change size
// *  @param toSize   The size it is projected to change to
// */
//- (void)intrinsicTextView:(RZIntrinsicContentSizeTextView *)textView didChangeToSize:(CGSize)toSize;

@end
