#!/usr/bin/env bash
cwd &&
cp -Rvf static/ app &&
ls -al app/bower_components &&
cross-env NODE_ENV=production webpack -p --progress &&
#bash scripts/polymer-build.sh app &&
ls -al app/bower_components &&
rm -f app/bower_components
cp -Rvf src/web/bower_components app/
ls -al /home/travis/build/jigargosar/elm-simple-gtd/app/bower_components/paper-styles/element-styles/paper-material.html &&
ls -al app/bower_components &&
cd app &&
cwd &&
polymer --version &&
polymer build &&
cd .. &&
cp -Rvf app/build/unbundled/ docs
