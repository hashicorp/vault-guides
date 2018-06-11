#!/usr/bin/env bash

###############################################################################
#
# demo-magic.sh
#
# Copyright (c) 2015 Paxton Hare
#
# This script lets you script demos in bash. It runs through your demo script when you press
# ENTER. It simulates typing and runs commands.
#
###############################################################################

# Preferred demo prompt
DEMO_PROMPT='[\u@\[\e[32;40m\]\h\[\e[0m\]] '

# the speed to "type" the text
TYPE_SPEED=${TYPE_SPEED:-20}

# no wait after "p" or "pe"
NO_WAIT=false

# if > 0, will pause for this amount of seconds before automatically proceeding with any p or pe
PROMPT_TIMEOUT=0

# Wait before a command is run
PRE_WAIT=true
# Wait after a command is run
POST_WAIT=true

# handy color vars for pretty prompts
BLACK="\033[0;30m"
BLUE="\033[0;34m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
RED="\033[0;31m"
PURPLE="\033[0;35m"
YELLOW="\033[0;33m"
WHITE="\033[1;37m"
COLOR_RESET="\033[0m"

green () {
  echo -e "${GREEN}$@${COLOR_RESET}"
}

red () {
  echo -e "${RED}$@${COLOR_RESET}"
}

yellow () {
  echo -e "${YELLOW}$@${COLOR_RESET}"
}

##
# prints the script usage
##
function usage() {
  echo -e ""
  echo -e "Usage: $0 [options]"
  echo -e ""
  echo -e "\tWhere options is one or more of:"
  echo -e "\t-h\tPrints Help text"
  echo -e "\t-d\tDebug mode. Disables simulated typing"
  echo -e "\t-n\tNo wait"
  echo -e "\t-w\tWaits max the given amount of seconds before proceeding with demo (e.g. `-w5`)"
  echo -e ""
}

##
# wait for user to press ENTER
# if $PROMPT_TIMEOUT > 0 this will be used as the max time for proceeding automatically
##
function wait() {
  if [[ "$PROMPT_TIMEOUT" == "0" ]]; then
    read -rs
  else
    read -rst "$PROMPT_TIMEOUT"
  fi
}

##
# print command only. Useful for when you want to pretend to run a command
#
# takes 1 param - the string command to print
#
# usage: p "ls -l"
#
##
function p() {
  cmd=$1

  echo ""
  # render the prompt
  x=$(PS1="$DEMO_PROMPT" "$BASH" --norc -i </dev/null 2>&1 | sed -n '${s/^\(.*\)exit$/\1/p;}')
  printf "$x"

  # wait for the user to press a key before typing the command
  if [[ -n $PRE_WAIT ]]; then
    wait
  fi

  if [[ -z $TYPE_SPEED ]]; then
    echo -en "\033[0m$cmd"
  else
    echo -en "\033[0m$cmd" | pv -qL $[$TYPE_SPEED+(-2 + RANDOM%5)];
  fi

  # wait for the user to press a key before moving on
  if $POST_WAIT; then
    wait
  fi
  echo ""
  echo ""
}

##
# Prints and executes a command
#
# takes 1 parameter - the string command to run
#
# usage: pe "ls -l"
#
##
function pe() {
  # print the command
  p "$@"

  # execute the command
  eval "$@"
  echo ""
}

##
# Enters script into interactive mode
#
# and allows newly typed commands to be executed within the script
#
# usage : cmd
#
##
function cmd() {
  # render the prompt
  x=$(PS1="$DEMO_PROMPT" "$BASH" --norc -i </dev/null 2>&1 | sed -n '${s/^\(.*\)exit$/\1/p;}')
  printf "$x\033[0m"
  read command
  eval "${command}"
}


function check_pv() {
  command -v pv >/dev/null 2>&1 || {

    echo ""
    echo -e "${RED}##############################################################"
    echo "# HOLD IT!! I require pv but it's not installed.  Aborting." >&2;
    echo -e "${RED}##############################################################"
    echo ""
    echo -e "${COLOR_RESET}Installing pv:"
    echo ""
    echo -e "${BLUE}Mac:${COLOR_RESET} $ brew install pv"
    echo ""
    echo -e "${BLUE}Other:${COLOR_RESET} http://www.ivarch.com/programs/pv.shtml"
    echo -e "${COLOR_RESET}"
    # Only exit is TYPE_SPEED is defined, this will work fine without it.   
    if [[ -n ${TYPE_SPEED} ]];then
      exit 1;
    fi
  }
}

#check_pv
#
# handle some default params
# -h for help
# -d for disabling simulated typing
#
while getopts ":dhnptw:" opt; do
  case $opt in
    h)
      usage
      exit 1
      ;;
    d)
      unset TYPE_SPEED
      ;;
    n)
      NO_WAIT=true
      unset PRE_WAIT
      unset POST_WAIT
      ;;
    p)
      unset PRE_WAIT
      ;;
    t)
      unset POST_WAIT
      ;;
    w)
      PROMPT_TIMEOUT=$OPTARG
  esac
done
