# Use this script to build the containers, then run run-tests.ps1 to execute the tests

docker build --rm -t backflow-base -f base.Dockerfile .
