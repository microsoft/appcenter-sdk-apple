#!/usr/bin/env xcrun --sdk macosx swift

// This script is meant to be called from an Xcode run script build phase
// It verifies there are no buildSettings embedded in the Xcode project
// as it is preferable to have build settings specified in .xcconfig files

import Darwin
import Foundation

func reportError(_ message: String, file: String = "", line: Int = 0) {
  let formatted = "\(file):\(line): error: \(message)\n"
  if let data = formatted.data(using: .utf8, allowLossyConversion: false) {
    FileHandle.standardError.write(data)
  } else {
    print("There was an error. Could not convert error message to printable string.")
  }
}

let ignoreSettings = [
  "CODE_SIGN_ENTITLEMENTS",
  "CODE_SIGN_IDENTITY",
  "CODE_SIGN_STYLE",
  "DEVELOPMENT_TEAM",
  "PROVISIONING_PROFILE",
  "PROVISIONING_PROFILE_SPECIFIER"
]
let startTime = Date()
let xcodeprojPath = CommandLine.arguments[1]
print("Verifying no build settings for \"\(xcodeprojPath)\"")
guard let xcodeproj = try? String(contentsOf: URL(fileURLWithPath:xcodeprojPath), encoding: .utf8) else {
  reportError("Failed making xcodeproj from url")
  exit(EXIT_FAILURE)
}
var inBuildSettingsBlock = false
var badLines = 0
let lines = xcodeproj.components(separatedBy: .newlines)
for (i, line) in lines.enumerated() {
  if inBuildSettingsBlock {
    if let _ = line.range(of:"\\u007d[:space:]*;", options: .regularExpression) {
      inBuildSettingsBlock = false
    } else if !ignoreSettings.contains(where: line.contains) {
      badLines += 1
      reportError("Build settings aren't allowed inside project files. Please move it into the .xcconfig file.\n" +
                  "  \(line.trimmingCharacters(in: .whitespaces))",
                  file: xcodeprojPath, line: i + 1)
    }
  } else {
    if let _ = line.range(of:"buildSettings[:space:]*=", options: .regularExpression) {
      inBuildSettingsBlock = true
    }
  }
}
let timeInterval = Date().timeIntervalSince(startTime)
print("Verified no build settings. Process took \(Int(timeInterval * 1000)) ms.")
exit(badLines > 0 ? EXIT_FAILURE : EXIT_SUCCESS)
