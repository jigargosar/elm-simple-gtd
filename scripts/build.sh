#!/usr/bin/env bash
cross-env NODE_ENV=production webpack -p --progress &&
cp -Rv static/** app/ &&
#bash scripts/polymer-build.sh app &&
cd app &&
polymer --version &&
polymer build
cp -Rv app/build/unbundled/** docs/
