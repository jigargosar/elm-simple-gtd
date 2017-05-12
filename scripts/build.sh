#!/usr/bin/env bash
cross-env NODE_ENV=production webpack -p --progress &&
cp -rv static/** app/ &&
#bash scripts/polymer-build.sh app &&
cd app &&
polymer --version &&
polymer build
cp -rv app/build/unbundled/** docs/
