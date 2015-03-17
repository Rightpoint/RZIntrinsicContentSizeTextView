#
# Be sure to run `pod lib lint RZIntrinsicContentSizeTextView.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "RZIntrinsicContentSizeTextView"
  s.version          = "0.1.0"
  s.summary          = "RZIntrinsicContentSizeTextView is a UITextView that grows dynamically in height."
  s.homepage         = "https://github.com/Raizlabs/RZIntrinsicContentSizeTextView.git"
  s.license          = 'MIT'
  s.author           = { "Derek Ostrander" => "derek@raizlabs.com" }
  s.source           = { :git => "https://github.com/Raizlabs/RZIntrinsicContentSizeTextView.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/**/*'

  s.public_header_files = 'Pod/Classes/**/*.h'
  s.dependency 'RZUtils/Categories/UIView'
end
