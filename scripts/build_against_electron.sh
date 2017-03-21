#!/usr/bin/env bash

source ~/.nvm/nvm.sh

set -e -u -x

GYP_ARGS="--runtime=electron --target=${ELECTRON_VERSION} --dist-url=https://atom.io/download/electron"
export DISPLAY=":99.0"

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
    echo $?
    npm install electron-mocha
    echo $?
    sh -e /etc/init.d/xvfb start
    echo $?
    sleep 3
}

function electron_test() {
    echo $(npm bin)
    ls -l $(npm bin)
    echo "var {app} = require('electron'); require('./createdb.js')(function () { app.quit(); });" >test/support/createdb-electron.js
    ls -l test/support/
    "$(npm bin)"/electron test/support/createdb-electron.js
    rm test/support/createdb-electron.js
    "$(npm bin)"/electron-mocha -R spec --timeout 480000
}

# test installing from source
npm install --build-from-source  --clang=1 $GYP_ARGS
echo $?
electron_pretest
echo $?
electron_test
echo $?


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

