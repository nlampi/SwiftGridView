#!/bin/bash
# Copyright (c) Nathan Lampi
#
# This code is licensed under the MIT License
# See the LICENSE file in the root directory

command -v jazzy >/dev/null 2>&1 || {
    echo "jazzy is required (https://github.com/realm/jazzy)" >&2;
    exit 1;
}

# Document via jazzy

jazzy \
    --clean \
    --author 'Nathan Lampi' \
    --author_url https://nathanlampi.com \
    --source-host github \
    --source-host-url https://github.com/nlampi/SwiftGridView \
    --source-host-files-url https://github.com/nlampi/SwiftGridView/tree/0.7.8 \
    --module-version 0.7.8
