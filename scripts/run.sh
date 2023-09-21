#!/bin/bash

if [ '-x' == "$1" ]; then
  set -x
fi

. /work/tools.sh
forwardFlow "$(getRepoSha)" "$(getVmrSha)"
