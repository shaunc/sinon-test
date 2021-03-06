#!/bin/bash
set -eu

function finish {
    if [ -n "${TRAVIS+1}" ]; then
      echo "TRAVIS detected, skip killing child processes"
    else
      kill $(jobs -pr)
    fi
}

trap finish SIGINT SIGTERM EXIT

echo
echo starting buster-server
./node_modules/buster/bin/buster-server & # fork to a subshell
sleep 4 # takes a while for buster server to start

echo
echo starting phantomjs
phantomjs ./node_modules/buster/script/phantom.js &
sleep 1 # give phantomjs a second to warm up

echo
echo "starting buster-test (source)"
./node_modules/buster/bin/buster-test --config-group coverage

echo
echo "starting buster-test (packaged)"
mkdir -p pkg
./node_modules/.bin/browserify ./test/*-test.js ./test/test-helper.js --exclude buster -t browserify-shim -o pkg/sinon-test-testrunner.js
./node_modules/buster/bin/buster-test -o --config test/buster-packaged.js
