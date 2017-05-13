#!/usr/bin/env bash
pwd &&
cp -rf static/ app &&
rm -f app/bower_components &&
ls -al app &&
cp -rf src/web/bower_components app/bower_components &&
ls -al app &&
cross-env NODE_ENV=production webpack -p --progress &&
cd app &&
ls -al . &&
polymer --version &&
polymer build &&
cd .. &&
cp -Rvf app/build/unbundled/ docs
true
