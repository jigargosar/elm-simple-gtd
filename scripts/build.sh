#!/usr/bin/env bash
cp -Rvf static/ app &&
ls -al app/bower_components &&
cross-env NODE_ENV=production webpack -p --progress &&
#bash scripts/polymer-build.sh app &&
ls -al app/bower_components &&
cd app &&
polymer --version &&
polymer build &&
cd .. &&
cp -Rvf app/build/unbundled/ docs
