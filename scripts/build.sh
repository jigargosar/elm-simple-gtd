#!/usr/bin/env bash
pwd &&
cp -rf static/ app &&
rm -rf app/bower_components &&
ls -al app &&
cp -rf src/web/bower_components app/bower_components &&
ls -al app &&
echo "content of app/bower_components" &&
ls -al app/bower_components &&
echo "content of app/bower_components/paper-styles/element-styles/" &&
ls -al app/bower_components/paper-styles/element-styles/ &&
cross-env NODE_ENV=production webpack -p --progress &&
cd app &&
pwd &&
ls -al . &&
ls -al bower_components &&
polymer --version &&
(polymer build || ( ls -al bower_components && pwd && false ))
cd .. &&
cp -Rvf app/build/unbundled/ docs
