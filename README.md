[![Build Status](https://www.bitrise.io/app/e5b1a2ef546331fb.svg?token=Orwi_AVAExLTuN1ZAzvbFQ&branch=develop)](https://www.bitrise.io/app/e5b1a2ef546331fb)
[![codecov](https://codecov.io/gh/Microsoft/mobile-center-sdk-ios/branch/develop/graph/badge.svg?token=6dlCB5riVi)](https://codecov.io/gh/Microsoft/mobile-center-sdk-ios)
[![CocoaPods](https://img.shields.io/cocoapods/v/MobileCenter.svg)](https://cocoapods.org/pods/MobileCenter)
[![CocoaPods](https://img.shields.io/cocoapods/dt/MobileCenter.svg)](https://cocoapods.org/pods/MobileCenter)
[![license](https://img.shields.io/badge/license-MIT%20License-00AAAA.svg)](https://github.com/Microsoft/mobile-center-sdk-ios/blob/master/LICENSE)

# Mobile Center SDK for iOS

Mobile Center is mission control for mobile apps.
Get faster release cycles, higher-quality apps, and the insights to build what users want.

The Mobile Center SDK uses a modular architecture so you can use any or all of the following services: 

1. **Mobile Center Analytics**: Mobile Center Analytics helps you understand user behavior and customer engagement to improve your app. The SDK automatically captures session count, device properties like model, OS version, etc. You can define your own custom events to measure things that matter to you. All the information captured is available in the Mobile Center portal for you to analyze the data.

2. **Mobile Center Crashes**: Mobile Center Crashes will automatically generate a crash log every time your app crashes. The log is first written to the device's storage and when the user starts the app again, the crash report will be sent to Mobile Center. Collecting crashes works for both beta and live apps, i.e. those submitted to the App Store. Crash logs contain valuable information for you to help fix the crash.

3. **Mobile Center Distribute**: Mobile Center Distribute will let your users install a new version of the app when you distribute it via the Mobile Center. With a new version of the app available, the SDK will present an update dialog to the users to either download or postpone the new version. Once they choose to update, the SDK will start to update your application. This feature will NOT work if your app is deployed to the app store.

4. **Mobile Center Push**: Mobile Center Push enables you to send push notifications to users of your app from the Mobile Center portal. You can also segment your user base based on a set of properties and send them targeted notifications.

## 1. Get started
It is super easy to use Mobile Center. Have a look at our [get started documentation](https://docs.microsoft.com/en-us/mobile-center/sdk/getting-started/ios) and onboard your app within minutes. Our [detailed documentation](https://docs.microsoft.com/en-us/mobile-center/sdk/) is available as well.

## 2. Contributing

We are looking forward to your contributions via pull requests.

To contribute to the SDK, you need a machine that runs macOS and the latest stable Xcode release. In addition, the SDK workspace requires [Jazzy](https://github.com/realm/jazzy) to generate documentation. 

### 2.1 Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

### 2.2 Contributor License

You must sign a [Contributor License Agreement](https://cla.microsoft.com/) before submitting your pull request. To complete the Contributor License Agreement (CLA), you will need to submit a request via the [form](https://cla.microsoft.com/) and then electronically sign the CLA when you receive the email containing the link to the document. You need to sign the CLA only once to cover submission to any Microsoft OSS project. 

## 3. Contact

### 3.1 Intercom

If you have further questions, want to provide feedback or you are running into issues, log in to the [Mobile Center portal](https://mobile.azure.com) and use the blue Intercom button on the bottom right to start a conversation with us.

### 3.2 Twitter
We're on Twitter as [@mobilecenter](https://www.twitter.com/mobilecenter).
