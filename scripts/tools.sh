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

function createRepoPatch() {
  local from=$1
  local to=$2

  path=/work/repo
  name="$path-${from}-${to}.patch"

  local res=$(createPatch "$path" "$name" "$from" "$to")
  echo "$res"
}

function createVmrPatch() {
  local from=$1
  local to=$2

  path=/work/tmp/vmr
  name="$path-${from}-${to}.patch"

  local res=$(createPatch "$path" "$name" "$from" "$to")
  echo "$res"
}

function createPatch() {
  local path=$1
  local name=$2
  local from=$3
  local to=$4

  pushd /work/vmr/src || exit 1
  git diff --patch --binary --output "$name" --relative "$from..$to" -- .
  popd || exit 1

  echo "$name"
}

function applyPatchToVmr() {
  local path=$1
  git -C /work/vmr apply --cached --ignore-space-change --directory src "$1" || fail "Applying the patch failed!"
}

function applyPatchToRepo() {
  local path=$1
  git -C /work/repo apply --cached --ignore-space-change "$1" || fail "Applying the patch failed!"
}
