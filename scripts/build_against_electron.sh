#!/usr/bin/env bash

source ~/.nvm/nvm.sh

set -e -u

GYP_ARGS="--runtime=electron --target=${ELECTRON_VERSION}"

function publish() {
    if [[ ${PUBLISHABLE:-false} == true ]] && [[ ${COMMIT_MESSAGE} =~ "[publish binary]" ]]; then
        node-pre-gyp package
        node-pre-gyp publish
        node-pre-gyp info
        make clean
    fi
}

function electron_pretest() {
    npm install electron
    npm install electron-mocha
}

function electron_test() {
    echo "var {app} = require('electron'); require('./createdb.js')(function () { app.quit(); });" >test/support/createdb-electron.js
    "$(npm bin)"/electron test/support/createdb-electron.js
    rm test/support/createdb-electron.js
    "$(npm bin)"/electron-mocha -R spec --timeout 480000
}

# test installing from source
npm install --build-from-source  --clang=1 $GYP_ARGS
electron_pretest
electron_test


publish

# now test building against shared sqlite
export NODE_SQLITE3_JSON1=no
if [[ $(uname -s) == 'Darwin' ]]; then
    brew install sqlite
    npm install --build-from-source --sqlite=$(brew --prefix) --clang=1 $GYP_ARGS
else
    npm install --build-from-source --sqlite=/usr --clang=1 $GYP_ARGS
fi
electron_test
export NODE_SQLITE3_JSON1=yes

platform=$(uname -s | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/")

