#!/usr/bin/env bash
cp -R static/ app &&
cross-env NODE_ENV=production webpack -p --progress &&
cd app &&
polymer --version &&
polymer build &&
cd .. &&
cp -R app/build/unbundled/ docs
