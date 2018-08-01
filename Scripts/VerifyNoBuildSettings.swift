#!/usr/bin/env xcrun --sdk macosx swift

// This script is meant to be called from an Xcode run script build phase
// It verifies there are no buildSettings embedded in the Xcode project
// as it is preferable to have build settings specified in .xcconfig files

import Darwin
import Foundation

func reportError(message: String) {
    print("error message was \(message)")
    let stderr = FileHandle.standardError
    if let data = message.data(using: String.Encoding.utf8, allowLossyConversion: false) {
        stderr.write(data)
    } else {
        print("there was an error.  Could not convert error message to printable string")
    }
}

public enum ProcessXcodeprojResult {
    case FoundBuildSettings([String])
    case Error(String)
    case OK(String)
}

public func processXcodeprojAt(url: URL) -> ProcessXcodeprojResult {
    let startTime = Date()
    guard let xcodeproj = try? String(contentsOf: url, encoding: String.Encoding.utf8) else {
        return .Error("failed making xcodeproj from url")
    }
    let lines = xcodeproj.components(separatedBy: CharacterSet.newlines)
    print ("found \(lines.count) lines")

    var badLines: [String] = []
    var inBuildSettingsBlock = false
    for nthLine in lines {
        if inBuildSettingsBlock {
            if let _ = nthLine.range(of:"\\u007d[:space:]*;", options: .regularExpression) {
                inBuildSettingsBlock = false
            } else if let _ = nthLine.range(of:"CODE_SIGN_IDENTITY") {

            } else {
                badLines.append(nthLine)
            }
        } else {
            if let _ = nthLine.range(of:"buildSettings[:space:]*=", options: .regularExpression) {
                inBuildSettingsBlock = true
            }
        }
    }

    let timeInterval = Date().timeIntervalSince(startTime)
    print ("process took \(timeInterval) seconds")
    if (badLines.count > 0) {
        return .FoundBuildSettings(badLines)
    }
    return .OK(":-)")
}
print("Verifying no buildSettings...")

let commandLineArgs = CommandLine.arguments
print("processArgs were \(commandLineArgs)")
let xcodeprojfilepath = commandLineArgs[1]
let myUrl = URL(fileURLWithPath:xcodeprojfilepath)
let result = processXcodeprojAt(url: myUrl)

switch result {
    case .Error(let str):
        reportError (message: "error verifying build settings: \(str)")
        exit(EXIT_FAILURE)
    case .FoundBuildSettings(let badLines):
        reportError (message: "found buildSettings:")
        for badLine in badLines {
            reportError (message: "    \(badLine)\n")
        }
        exit(EXIT_FAILURE)
    case .OK:
        print ("Verified no buildSettings")
        exit(EXIT_SUCCESS)
}
