#!/bin/bash

initLog () {
  LOG_FILE=${1:-/dev/stderr} || return 1;
}

log () {
  cat - <(echo) >> $LOG_FILE || return 1;
}

withLog () {
  local word=$1
  if [ -p /dev/stdin ]; then
    awk -v word="$word" '{printf $0" "word}' < /dev/stdin
  else
    echo $word 
  fi
}

level () {
  local _level=${1:-DEBUG}
  echo -n "level=$_level"
}

tsLog () {
  local ts="ts=$(LANG=C date +"%Y-%m-%dT%H:%M:%SZ%Z")"
  if [ -p /dev/stdin ]; then
    withLog $ts < /dev/stdin
  else
    withLog $ts
  fi
}

# init
initLog log.txt

# error handling with log
uname | grep "$1" \
  && level DEBUG | tsLog | withLog "msg=found $1" | log \
  || {(level ERROR | tsLog | withLog "msg=not found $1" | log); exit 1; }

echo after 
