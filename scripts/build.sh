#!/usr/bin/env bash
pwd &&
cp -Rf static/ app &&
rm -f app/bower_components &&
cp -R src/web/bower_components app/bower_components &&
cross-env NODE_ENV=production webpack -p --progress &&
cd app &&
polymer --version &&
polymer build &&
cd .. &&
cp -Rvf app/build/unbundled/ docs
true
