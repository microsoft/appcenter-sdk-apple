---
name: Problem report
about: Report a problem using the SDK
title: ''
labels: support
assignees: ''

---

<!--
    Thanks for your interest in using the App Center SDK for Apple platforms.
    If your issue is not related to using our Apple SDK but rather about the product experience like the portal or CI,
    please create an issue on https://github.com/Microsoft/appcenter instead.
-->

### **Description**

Please describe the issue you are facing using the SDK.

### **Repro Steps**

Please list the steps used to reproduce your issue.

1.
2.

### **Details**

1. Which SDK version are you using?
    - e.g. 4.1.1
2. Which OS version did you experience the issue on?
    - e.g. iOS 14
3. Which Xcode version did you build the app with?
    - e.g. Xcode 12.4
5. Which Cocoapods version are you using (run `pod --version`)?
    - e.g. 1.10.1
6. What device version did you see this error on?  Were you using an emulator or a physical device?
    - e.g. iPhone 12 physical device, iPhone 11 emulator
7. What language are you using?
    - [ ] Objective C
    - [ ] Swift
8. What third party libraries are you using?
9. Please enable verbose logging for your app using `MSAppCenter.setLogLevel(.verbose)` before your call to `MSAppCenter.start(...)` for Swift, or `[MSAppCenter setLogLevel:MSLogLevelVerbose]` before `[MSAppCenter start: ...]` for Objective C and include the logs here:
