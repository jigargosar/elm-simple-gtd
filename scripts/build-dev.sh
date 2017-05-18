#!/usr/bin/env bash
cp -R static/ dev &&
cross-env NODE_ENV=development webpack --progress &&
cd dev &&
polymer --version &&
polymer build &&
cd ..
