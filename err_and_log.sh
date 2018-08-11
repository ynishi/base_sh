#!/bin/bash

readonly DEFAULT_LEVEL=DEBUG
readonly DEFAULT_LOGFILE=/dev/stderr

declare -A -r LEVELS=(\
  ["ALL"]=0 \
  ["DEBUG"]=1 \
  ["INFO"]=2 \
  ["WARN"]=3 \
  ["ERROR"]=4 \
  ["NONE"]=9 \
  )

# init log setting
function initLog () {
  LOG_FILE=${1:-$DEFAULT_LOGFILE}
  local _allow_level=${2:-$DEFAULT_LEVEL}
  if [ -z ${LEVELS[$_allow_level]} ]; then
    ALLOW_LEVEL=$DEFAULT_LEVEL
  else
    ALLOW_LEVEL=$_allow_level
  fi

  local _acc
  for key in "${!LEVELS[@]}";do
    if [ ${LEVELS[$ALLOW_LEVEL]} -le ${LEVELS[$key]} ]; then
      acc=${acc}${acc:+' '}$key
    fi
  done
  ALLOWED_LEVEL=${acc##" "}
}

# composable basic functions

## write log
function log () {
  if [ -p /dev/stdin ]; then
    awk '{print}' < /dev/stdin  >> $LOG_FILE
  fi
}

## create level
function level () {
  local _level=${1:-DEBUG}
  echo -n "level=$_level"
}

## filter level
function allowed () {
  if [ -p /dev/stdin ]; then
    local _pat='/'${ALLOWED_LEVEL// /|}'/'
      awk $_pat' {printf $0}' < /dev/stdin
  fi
}

## add item
function withLog () {
  local word=$1
  if [ -p /dev/stdin ]; then
    awk -v word="$word" '{printf $0" "word}' < /dev/stdin
  else
    echo $word
  fi
}

## add timestamp
function tsLog () {
  local ts="ts=$(LANG=C date +"%Y-%m-%dT%H:%M:%SZ%Z")"
  if [ -p /dev/stdin ]; then
    withLog $ts < /dev/stdin
  else
    withLog $ts
  fi
}

# construct functions for user
function logBase () {
  local _level=$1
  local _msg=$2
  level $_level | tsLog | withLog "msg=$_msg" | allowed | log
}

function logDebug () {
  logBase DEBUG "$1"
}
function logError () {
  logBase ERROR "$1"
}

# example

## init
initLog /dev/stderr DEBUG

## error handling with log
uname | grep "$1" \
  && level DEBUG | tsLog | withLog "msg=found $1 in uname" | allowed | log \
  || {(level ERROR | tsLog | withLog "msg=not found $1 in uname" | allowed | log); exit 1; }

hostname | grep "$1" \
  && logDebug "found $1 in hostname" \
  || {(logError "not found $1 in hostname"); exit 1; }

echo after
