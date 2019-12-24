#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

source $(dirname "$0")/../build-ios-framework.sh

OTHER_LDFLAGS = $(OTHER_LDFLAGS) -framework AuthenticationServices
rm -r "${WORK_DIR}"
