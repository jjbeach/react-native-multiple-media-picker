# react-native-multiple-media-picker
A multiple media picker for React Native. (Please note that this library is still in an experimental stage and currently only works for iOS.)

![alt text](https://cloud.githubusercontent.com/assets/4034956/15001931/254805de-119c-11e6-9f68-d815ccc712cd.gif "Demo gif")

## Features
* Multiple selection.
* Fullscreen preview
* Switching albums.
* Supports images, live photos and videos.
* Selected assets.
* Customizable.

## Getting started
### 1. Install package

`$ npm install react-native-multiple-media-picker --save`

or

`$ yarn add react-native-multiple-media-picker`


### 2. Setup native dependencies (iOS)

In your React Native project, navigate to `ios` folder and add the following line to your Podfile
```ruby
pod 'BSImagePicker', :git => 'https://github.com/jjbeach/BSImagePicker'
```

### 3. Configure your app's .xcworkspace

#### Swift

Since this library is based on a Swift package, your React Native app's .xcworkspace will need to be compatible with Swift.

If your .xcworkspace is not already configured to work with Swift, then the simplest way to do this is the following

##### 1. Create a Swift file
From Xcode, just go to:
* File → New → File… (or CMD+N)
* Select Swift File
* Name your file Dummy or whatever you want
* In the Group dropdown, make sure to select your project and your app as the target
##### 2. Create Bridging Header 
Xcode will ask if you want to create a bridging header. Click create. If you accidentally press “Don’t Create", go to File > New > File. Select Header File, and name it your_app_name-Bridging-Header

## Usage
```javascript
import MultipleMediaPicker from 'react-native-multiple-media-picker';

// TODO: What to do with the module?
MultipleMediaPicker;
```

## Credits
BSImagePicker is an excellent Swift package from Joakim Gyllström (mikaoj). Huge shoutout to him for this library 🙌🏻💯

