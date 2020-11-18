#!/bin/sh

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "${DIR}/demo-function"

echo "Removing old builds..."
rm -f bin/main 2> /dev/null
rm -f demo-function.zip 2> /dev/null

echo "Build function..."
GOOS=linux GOARCH=amd64 go build -ldflags '-s -w' -a -o bin/main main.go

echo

echo "Making new zip..."
zip -j -D -r demo-function.zip bin/bootstrap bin/main

popd # ${DIR}