# Contributing to Visual Studio App Center SDK for iOS and macOS

Welcome, and thank you for your interest in contributing to VS App Center SDK for iOS and macOS!
The goal of this document is to provide a high-level overview of how you can get involved.

To contribute to the SDK, please

* Install Xcode 11 on your Mac.
* Install [Jazzy](https://github.com/realm/jazzy) to be able to generate documentation.
* Install `clang-format` for code formatting via [Homebrew](https://brew.sh) using the command `brew install clang-format`.

## Sending a pull request

Small pull requests are much easier to review and more likely to get merged. Make sure the PR does only one thing, otherwise please split it.

Please make sure the following is done when submitting a pull request:

### Workflow and validation

1. Fork the repository and create your branch from `develop`.
1. Run `git submodule update --init --recursive` before opening the solution.
1. Use Xcode 11 or above to edit and compile the SDK.
1. Make sure that there are no lint errors: run `gradlew assemble lint` command.
1. Make sure all tests have passed and your code is covered.
1. If your change includes a fix or feature related to the changelog of the next release, you have to update the **CHANGELOG.md**.
1. After creating a pull request, sign the CLA, if you haven't already.

### Code formatting

1. Make sure you name all the classes in upper camel case and have `MSAC`.
1. Use blank line in-between methods.
1. No newlines within methods except in front of a comment.
1. Use `{}` even if you have single operation in block.

All Objective-C files follow LLVM coding style (with a few exceptions) and are formatted accordingly. To format your changes, make sure you have the `clang-format` tool. It can be installed with [Homebrew](https://brew.sh) using the command `brew install clang-format`. Once you have installed `clang-format`, run `./clang-format-changed-files.sh` from the repository root - this will format all files that have changes against the remote `develop` branch (it will also perform a `git fetch`).

### Comments

1. Use capital letter in the beginning of each comment and dot at the end.
1. Provide documentation for each public class, method and property.

## Thank You!

Your contributions to open source, large or small, constantly make projects better. Thank you for taking the time to contribute.
