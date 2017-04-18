# RZIntrinsicContentSizeTextView

<!--[![CI Status](http://img.shields.io/travis/Derek Ostrander/RZIntrinsicContentSizeTextView.svg?style=flat)](https://travis-ci.org/Derek Ostrander/RZIntrinsicContentSizeTextView)
[![Version](https://img.shields.io/cocoapods/v/RZIntrinsicContentSizeTextView.svg?style=flat)](http://cocoadocs.org/docsets/RZIntrinsicContentSizeTextView)
[![License](https://img.shields.io/cocoapods/l/RZIntrinsicContentSizeTextView.svg?style=flat)](http://cocoadocs.org/docsets/RZIntrinsicContentSizeTextView)
[![Platform](https://img.shields.io/cocoapods/p/RZIntrinsicContentSizeTextView.svg?style=flat)](http://cocoadocs.org/docsets/RZIntrinsicContentSizeTextView)
-->
RZIntrinsicContentSizeTextView is a convenient UITextView subclass that has all the features you wish were in UITextView: a placeholder and the ability to dynamically grow based on its content size.

This is ideal for the many messaging applications where the user is typing into a textview that will start off small, but will then need to grow in height and/or width as needed.

## Installation

RZIntrinsicContentSizeTextView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod 'RZIntrinsicContentSizeTextView'
    
## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first. 

## Basic Overview
-----------------
### Placeholder

The placeholder interface is similar to that of a UITextField.   

	.placeholder text of the placeholder label  
	.placeholderTextColor textColor of the placeholder label   
	.atributedPlaceholer attributedString for the placeholder label.

If you need more fine grained control over how the placeholder looks you can use the `.attributedPlaceholder`  
**Note:** the size of the textview does not take into account a different font then the `.font` property. For the time being it is encouraged that these two fonts be equal

### Size Changing

You should be able to drag and drop this in a xib or initialize it progromatically and have it work. As long as it has a width specified either directly or by it's layout. This will take into account the minimum and maximum constraints when determining the height, to neither get to small nor too large.

	.heightPriority the priority on the height constraint of the textview. Default is 999.0f

**Note:** the height priority may need to be altered if you have other constraints outside of the textview that will effect it's height.


By default the textview will try and animate by setting it's height and calling `layoutIfNeeded` on it's superview. However, if you need to override this you can use the `.sizeChangeDelegate` of protocol `RZIntrinsicContentSizeTextViewSizeChangedDelegate`

#### RZIntrinsicContentSizeTextViewSizeChangedDelegate

```objc	
// Determine's whether or not the textview should animate it's size change
- (BOOL)intrinsicTextView:shouldAnimateToSize:

// The UIView that is going to get layoutIfNeeded called on it
- (UIView *)intrinsicTextViewLayoutView:
```

If you don't want to animate any animations you can do this by returning false from `intrinsicTextView:shouldAnimateToSize`  

```objc
- (BOOL)intrinsicTextView:(RZIntrinsicContentSizeTextView *)textView shouldAnimateToSize:(CGSize)toSize
{
    return NO;
}
```
	
If you need to change the view that is calling layoutIfNeeded

```objc
- (UIView *)intrinsicTextViewLayoutView:(RZIntrinsicContentSizeTextView *)textView
{
    return self.view;
}
```

This should only be used if the text view wants to animate and is getting odd animations. The most common case for this is when the text view is in a container. You will need to call `layoutIfNeeded` on the container's superview during the animation so the container will also animate its layout changing.
	
	
## Basic Use
-------------

This is the basic use case code. Where the textview is pinned to the bottom of the view and has a minimum of 40.0f height and maximum of 100.0f

```objc
// add textview to view
self.textView =  [[RZIntrinsicContentSizeTextView alloc] initWithFrame:CGRectZero];
self.textView.translatesAutoresizingMaskIntoConstraints = NO;
[self.view addSubview:self.textView];

// set textview attributes
self.textView.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];

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
```
	

## Author

[Derek Ostrander](https://github.com/dostrander), djostran@gmail.com, [@_derko](http://twitter.com/_derko)

## Contributors

[John Stricker](https://github.com/jatraiz), john.stricker@raizlabs.com


## License

RZIntrinsicContentSizeTextView is available under the MIT license. See the LICENSE file for more info.
