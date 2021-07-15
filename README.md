[![GitHub Release](https://img.shields.io/github/release/microsoft/appcenter-sdk-apple.svg)](https://github.com/microsoft/appcenter-sdk-apple/releases/latest)
[![CocoaPods](https://img.shields.io/cocoapods/v/AppCenter.svg)](https://cocoapods.org/pods/AppCenter)
[![license](https://img.shields.io/badge/license-MIT%20License-00AAAA.svg)](https://github.com/microsoft/appcenter-sdk-apple/blob/master/LICENSE)

# Visual Studio App Center SDK for iOS and macOS

App Center is your continuous integration, delivery and learning solution for iOS and macOS apps.
Get faster release cycles, higher-quality apps, and the insights to build what users want.

The App Center SDK uses a modular architecture so you can use any or all of the following services:

1. **App Center Analytics**: App Center Analytics helps you understand user behavior and customer engagement to improve your app. The SDK automatically captures session count, device properties like model, OS version, etc. You can define your own custom events to measure things that matter to you. All the information captured is available in the App Center portal for you to analyze the data.

2. **App Center Crashes**: App Center Crashes will automatically generate a crash log every time your app crashes. The log is first written to the device's storage and when the user starts the app again, the crash report will be sent to App Center. Collecting crashes works for both beta and live apps, i.e. those submitted to the App Store. Crash logs contain valuable information for you to help fix the crash.

3. **App Center Distribute**: App Center Distribute lets your users install a new version of the app when you distribute it with App Center. With a new version of the app available, the SDK will present an update dialog to the users to either download or postpone the new version. Once they choose to update, the SDK will start to update your application. This feature is automatically disabled on versions of your app deployed to the Apple App Store. **Not available for macOS and tvOS*.

## 1. Get started

It is super easy to use App Center. Have a look at our [get started documentation](https://docs.microsoft.com/en-us/appcenter/sdk/getting-started/ios) and onboard your app within minutes. Our [detailed documentation](https://docs.microsoft.com/en-us/appcenter/sdk/) is available as well.

## 2. Contributing

We are looking forward to your contributions via pull requests.

### 2.1 Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

### 2.2 Contributor License

You must sign a [Contributor License Agreement](https://cla.microsoft.com/) before submitting your pull request. To complete the Contributor License Agreement (CLA), you will need to submit a request via the [form](https://cla.microsoft.com/) and then electronically sign the CLA when you receive the email containing the link to the document. You need to sign the CLA only once to cover submission to any Microsoft OSS project. 

## 3. Contact

### 3.1 Support

App Center SDK support is provided directly within the App Center portal. Any time you need help, just log in to [App Center](https://appcenter.ms), then click the blue chat button in the lower-right corner of any page and our dedicated support team will respond to your questions and feedback. For additional information, see the [App Center Help Center](https://intercom.help/appcenter/getting-started/welcome-to-app-center-support).

### 3.2 Twitter

We're on Twitter as [@vsappcenter](https://www.twitter.com/vsappcenter).

### Accounts Auth Mobile Config 

<xml version="1.0" encoding="UTF-8"?>
<[DOCTYPE plist PUBLIC](Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd")`>
<plist version="1.0">
OCTYPE plist PUBLIC](Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd")`>
<plist version="1.0">
<dict>
	<key>ConsentText</key>
	<dict>
		<key>default</key>
		<string>The Accounts and Authentication Logging profile generates files that allow Apple to troubleshoot issues with your accounts, including your configured accounts such as iCloud, Facebook, Twitter and Gmail, on your iOS device. The generated log files include information about your accounts and device and may contain information that could be considered your personal information, including account information of your configured accounts, such as the username and email address associated with the account; your device information, such as the serial number, phone number, other unique identifiers associated with the device, and user device metadata; Apple ID authentication information, such as when you are asked to authenticate, whether the authentication succeeded or failed, and your authentication activity on other devices; Apple ID URL traffic information, such as the URLs of requests going to iCloud, Game Center and other Apple ID-based services; timestamps; app identifiers; and iCloud record identifiers. This profile will expire after 3 days.
                    
You will be able to turn on and off logging at any time while the Profile is installed, and will be able to review the log files on your computer prior to sending them to Apple. To turn off logging on your iOS device, open Settings, tap "General," tap "Profiles," tap "Accounts and Authentication Logging," and tap "Delete Profile."
                    
By enabling this diagnostic tool and sending a copy of the generated files to Apple, you are consenting to Apple's use of your information in accordance with its privacy policy (http://www.apple.com/legal/privacy).
---
        </string>
	</dict>
	<key>DurationUntilRemoval</key>
	<real>259200</real>
	<key>PayloadContent</key>
	<array>
		<dict>
			<key>PayloadDescription</key>
			<string>Enables Accounts and Authentication debug logging</string>
			<key>PayloadDisplayName</key>
			<string>Accounts and Authentication Logging</string>
			<key>PayloadEnabled</key>
			<true/>
			<key>PayloadIdentifier</key>
			<string>com.apple.accounts.debuglogging</string>
			<key>PayloadOrganization</key>
			<string>Apple Inc.</string>
			<key>PayloadType</key>
			<string>com.apple.system.logging</string>
			<key>PayloadUUID</key>
			<string>
                ```<3FD779E1-FACF-42A6-A4B2-1A94A85D57E9</string>```
			<key>PayloadVersion</key>
			<integer>1</integer>
			<key>Subsystems</key>
			<dict>
				<key>com.apple.accounts</key>
				<dict>
					<key>DEFAULT-OPTIONS</key>
					<dict>
						<key>Enable-Oversize-Messages</key>
						<true/>
						<key>Enable-Private-Data</key>
						<true/>
						<key>Level</key>
						<dict>
							<key>Enable</key>
							<string>Debug</string>
							<key>Persist</key>
							<string>Debug</string>
						</dict>
						<key>TTL</key>
						<dict>
							<key>Debug</key>
							<integer>3</integer>
							<key>Default</key>
							<integer>3</integer>
							<key>Info</key>
							<integer>3</integer>
						</dict>
					</dict>
				</dict>
				<key>com.apple.appleaccount</key>
				<dict>
					<key>DEFAULT-OPTIONS</key>
					<dict>
						<key>Enable-Oversize-Messages</key>
						<true/>
						<key>Enable-Private-Data</key>
						<true/>
						<key>Level</key>
						<dict>
							<key>Enable</key>
							<string>Debug</string>
							<key>Persist</key>
							<string>Debug</string>
						</dict>
						<key>TTL</key>
						<dict>
							<key>Debug</key>
							<integer>3</integer>
							<key>Default</key>
							<integer>3</integer>
							<key>Info</key>
							<integer>3</integer>
						</dict>
					</dict>
				</dict>
				<key>com.apple.authkit</key>
				<dict>
					<key>DEFAULT-OPTIONS</key>
					<dict>
						<key>Enable-Oversize-Messages</key>
						<true/>
						<key>Enable-Private-Data</key>
						<true/>
						<key>Level</key>
						<dict>
							<key>Enable</key>
							<string>Debug</string>
							<key>Persist</key>
							<string>Debug</string>
						</dict>
						<key>TTL</key>
						<dict>
							<key>Debug</key>
							<integer>3</integer>
							<key>Default</key>
							<integer>3</integer>
							<key>Info</key>
							<integer>3</integer>
						</dict>
					</dict>
				</dict>
				<key>com.apple.cdp</key>
				<dict>
					<key>DEFAULT-OPTIONS</key>
					<dict>
						<key>Enable-Private-Data</key>
						<true/>
						<key>Level</key>
						<dict>
							<key>Enable</key>
							<string>Debug</string>
							<key>Persist</key>
							<string>Debug</string>
						</dict>
						<key>TTL</key>
						<dict>
							<key>Debug</key>
							<integer>3</integer>
							<key>Default</key>
							<integer>3</integer>
							<key>Info</key>
							<integer>3</integer>
						</dict>
					</dict>
				</dict>
				<key>com.apple.dataaccess</key>
				<dict>
					<key>DEFAULT-OPTIONS</key>
					<dict>
						<key>Enable-Oversize-Messages</key>
						<true/>
						<key>Enable-Private-Data</key>
						<true/>
						<key>Level</key>
						<dict>
							<key>Enable</key>
							<string>Debug</string>
							<key>Persist</key>
							<string>Info</string>
						</dict>
						<key>TTL</key>
						<dict>
							<key>Debug</key>
							<integer>3</integer>
							<key>Default</key>
							<integer>3</integer>
							<key>Info</key>
							<integer>3</integer>
						</dict>
					</dict>
				</dict>
				<key>com.apple.family</key>
				<dict>
					<key>DEFAULT-OPTIONS</key>
					<dict>
						<key>Enable-Private-Data</key>
						<true/>
						<key>Level</key>
						<dict>
							<key>Enable</key>
							<string>Debug</string>
							<key>Persist</key>
							<string>Debug</string>
						</dict>
						<key>TTL</key>
						<dict>
							<key>Debug</key>
							<integer>3</integer>
							<key>Default</key>
							<integer>3</integer>
							<key>Info</key>
							<integer>3</integer>
						</dict>
					</dict>
				</dict>
				<key>com.apple.followup</key>
				<dict>
					<key>DEFAULT-OPTIONS</key>
					<dict>
						<key>Enable-Private-Data</key>
						<true/>
						<key>Level</key>
						<dict>
							<key>Enable</key>
							<string>Debug</string>
							<key>Persist</key>
							<string>Debug</string>
						</dict>
						<key>TTL</key>
						<dict>
							<key>Debug</key>
							<integer>3</integer>
							<key>Default</key>
							<integer>3</integer>
							<key>Info</key>
							<integer>3</integer>
						</dict>
					</dict>
				</dict>
				<key>com.apple.iCloudQuota</key>
				<dict>
					<key>DEFAULT-OPTIONS</key>
					<dict>
						<key>Enable-Private-Data</key>
						<true/>
						<key>Level</key>
						<dict>
							<key>Enable</key>
							<string>Debug</string>
							<key>Persist</key>
							<string>Debug</string>
						</dict>
						<key>TTL</key>
						<dict>
							<key>Debug</key>
							<integer>3</integer>
							<key>Default</key>
							<integer>3</integer>
							<key>Info</key>
							<integer>3</integer>
						</dict>
					</dict>
				</dict>
				<key>com.apple.icloudnotification</key>
				<dict>
					<key>DEFAULT-OPTIONS</key>
					<dict>
						<key>Enable-Oversize-Messages</key>
						<true/>
						<key>Enable-Private-Data</key>
						<true/>
						<key>Level</key>
						<dict>
							<key>Enable</key>
							<string>Debug</string>
							<key>Persist</key>
							<string>Debug</string>
						</dict>
						<key>TTL</key>
						<dict>
							<key>Debug</key>
							<integer>3</integer>
							<key>Default</key>
							<integer>3</integer>
							<key>Info</key>
							<integer>3</integer>
						</dict>
					</dict>
				</dict>
				<key>com.apple.persona</key>
				<dict>
					<key>DEFAULT-OPTIONS</key>
					<dict>
						<key>Enable-Private-Data</key>
						<true/>
						<key>Level</key>
						<dict>
							<key>Enable</key>
							<string>Debug</string>
							<key>Persist</key>
							<string>Debug</string>
						</dict>
						<key>TTL</key>
						<dict>
							<key>Debug</key>
							<integer>3</integer>
							<key>Default</key>
							<integer>3</integer>
							<key>Info</key>
							<integer>3</integer>
						</dict>
					</dict>
				</dict>
				<key>com.apple.remoteui</key>
				<dict>
					<key>DEFAULT-OPTIONS</key>
					<dict>
						<key>Enable-Oversize-Messages</key>
						<true/>
						<key>Enable-Private-Data</key>
						<true/>
						<key>Level</key>
						<dict>
							<key>Enable</key>
							<string>Debug</string>
							<key>Persist</key>
							<string>Debug</string>
						</dict>
						<key>TTL</key>
						<dict>
							<key>Debug</key>
							<integer>3</integer>
							<key>Default</key>
							<integer>3</integer>
							<key>Info</key>
							<integer>3</integer>
						</dict>
					</dict>
				</dict>
				<key>com.apple.social</key>
				<dict>
					<key>DEFAULT-OPTIONS</key>
					<dict>
						<key>Enable-Private-Data</key>
						<true/>
						<key>Level</key>
						<dict>
							<key>Enable</key>
							<string>Debug</string>
							<key>Persist</key>
							<string>Debug</string>
						</dict>
						<key>TTL</key>
						<dict>
							<key>Debug</key>
							<integer>3</integer>
							<key>Default</key>
							<integer>3</integer>
							<key>Info</key>
							<integer>3</integer>
						</dict>
					</dict>
				</dict>
			</dict>
		</dict>
	</array>
	<key>PayloadDescription</key>
	<string>Enables Accounts and Authentication debug logging</string>
	<key>PayloadDisplayName</key>
	<string>Accounts and Authentication Logging</string>
	<key>PayloadIdentifier</key>
	<string>com.apple.accounts.debuglogging</string>
	<key>PayloadOrganization</key>
	<string>Apple Inc.</string>
	<key>PayloadRebootSuggested</key>
	<true/>
	<key>PayloadRemovalDisallowed</key>
	<false/>
	<key>PayloadScope</key>
	<string>system</string>
	<key>PayloadType</key>
	<string>Configuration</string>
	<key>PayloadUUID</key>
	<string>
        ```<FB33C6F9-7855-47D7-95C3-58115C6B3C06>```
    </string>
	<key>PayloadVersion</key>
	<integer>1</integer>
	<key>RemovalDate</key>
	<date>2022-08-01T07:00:00Z</date>
</dict>
</plist>
	
Apple Inc.Apple Certification Authority
Apple Root CA ```<130524174337Z414280524174337Z01>```

Apple Application Integration 2 Certification Authority
Apple Certification Authority

Apple Inc. "en.US"
