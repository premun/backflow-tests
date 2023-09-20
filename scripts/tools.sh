#!/bin/bash

COLOR_RED=$(tput setaf 1 2>/dev/null || true)
COLOR_CYAN=$(tput setaf 6 2>/dev/null || true)
COLOR_CLEAR=$(tput sgr0 2>/dev/null || true)
COLOR_RESET=uniquesearchablestring

function fail () {
  echo "$FAILURE_PREFIX${COLOR_RED}${1//${COLOR_RESET}/${COLOR_RED}}${COLOR_CLEAR}"
  exit 1
}

function highlight () {
  echo
  echo "$FAILURE_PREFIX${COLOR_CYAN}${1//${COLOR_RESET}/${COLOR_CYAN}}${COLOR_CLEAR}"
}

