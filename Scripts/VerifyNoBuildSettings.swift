#!/usr/bin/env xcrun --sdk macosx swift

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

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
  "PRODUCT_BUNDLE_IDENTIFIER",
  "CODE_SIGN_ENTITLEMENTS",
  "CODE_SIGN_IDENTITY",
  "CODE_SIGN_STYLE",
  "DEVELOPMENT_TEAM",
  "PROVISIONING_PROFILE",
  "PROVISIONING_PROFILE_SPECIFIER",
  "INFOPLIST_FILE",
  "TEST_TARGET_NAME",
  "IBSC_MODULE"
]
let startTime = Date()
let xcodeprojPath = CommandLine.arguments[1]
print("Verifying no build settings for \"\(xcodeprojPath)\"")
guard let xcodeproj = try? String(contentsOf: URL(fileURLWithPath:xcodeprojPath), encoding: .utf8) else {
  reportError("Failed making xcodeproj from url")
  exit(EXIT_FAILURE)
}
var inBuildSettingsBlock = false
var inListBlock = false
var setting: String? = nil
var badLines = 0
let lines = xcodeproj.components(separatedBy: .newlines)
for (i, line) in lines.enumerated() {
  if inBuildSettingsBlock {
    if !inListBlock {
      setting = nil
    }
    if let _ = line.range(of:"\\}\\s*;", options: .regularExpression) {
      inBuildSettingsBlock = false
      continue
    }
    
    // Ignore allowed settings.
    if ignoreSettings.contains(where: line.contains) {
      continue
    }
    
    // Handle list settings.
    if inListBlock {
      setting! += line.trimmingCharacters(in: .whitespaces)
      if let _ = line.range(of:"\\)\\s*;", options: .regularExpression) {
        inListBlock = false
      } else {
        continue
      }
    } else if let _ = line.range(of:"\\w+\\s*=\\s*\\(", options: .regularExpression) {
      inListBlock = true
      setting = line.trimmingCharacters(in: .whitespaces)
      continue
    }
    
    // Produce error.
    badLines += 1
    reportError("Build settings aren't allowed inside project files. Please move it into the .xcconfig file.\n" +
                "  \(setting ?? line.trimmingCharacters(in: .whitespaces))",
                file: xcodeprojPath, line: i + 1)
  } else if let _ = line.range(of:"buildSettings\\s*=", options: .regularExpression) {
    inBuildSettingsBlock = true
  }
}
let timeInterval = Date().timeIntervalSince(startTime)
print("Verified no build settings. Process took \(Int(timeInterval * 1000)) ms.")
exit(badLines > 0 ? EXIT_FAILURE : EXIT_SUCCESS)
