#!/bin/bash
######################################################################
#@Author: yushuibo
#@Copyright (c) 2018 yushuibo. All rights reserved.
#@Licence: GPL-2
#@Email: hengchen2005@gmail.com
#@File: aria2c.sh
#@Create: 2018-09-05 21:38:04
#@Last Modified: 2018-09-05 21:38:04
#@Desc: --
######################################################################

conf_home="$HOME/.aria2/"
session="$(grep 'input-file' aria2.conf|awk -F= '{print $2}')"


# install aria2c using Homebrew.
function install(){
  brew &>/dev/null
  if [ $? -ne 1 ];then
    echo "Homebrew not install or error occurred. please check it and run this script."
    exit 10
  fi

  # install
  echo "Starting install aria2c..."
  if [ $(brew list|grep aria2|wc -l) -eq 0 ];then
    brew install aria2 > /dev/null
    if [ $? -ne 0 ];then
      echo "Error occurred when installing aria2c."
      exit 11
    fi
  else
    echo "aria2c is already install, skip..."
  fi

  # make the config directory and copy config file.
  echo "Initilize aria2c..."
  [ ! -d $conf_home ] && mkdir $conf_home
  cp aria2.conf $conf_home
  touch $session

  # install auto run plist
  cp ./aria2.plist $HOME/Library/LaunchAgents/
  chmod 644 $HOME/Library/LaunchAgents/aria2.plist
  launchctl load $HOME/Library/LaunchAgents/aria2.plist
  launchctl start aria2

  echo "aria2c install succeed!"
  sleep 0.5
  _status

}


# get the pid of aria2c daemon process when aria2c is running;
# if aria2c is not running, return 0.
function getpid(){
  if [ $(ps -ef|grep '/usr/local/bin/aria2c'|grep -v 'grep'|wc -l) -ne 0 ];then
    echo $(ps -ef|grep '/usr/local/bin/aria2c'|grep -v 'grep'|awk '{print $2}')
  else
    # not running
    echo 0
  fi
}


# start aria2c daemon process.
function _start(){
  if [ $(getpid) -ne 0 ];then
    echo "aria2c is already running."
    exit 1
  else
    /usr/local/bin/aria2c --conf-path=${conf_home}aria2.conf -D
    sleep 0.5
    local pid=$(getpid)
    if [ $pid -ne 0 ];then
      echo "Starting aria2c: OK, the pid is $pid."
    else
      echo "Starting aria2c: FAILED."
    fi
  fi

}


# stop aria2c daemon process.
function _stop(){
  if [ $(getpid) -eq 0 ];then
    echo "aria2c is not running at this moment."
    exit 2
  else
    kill $(getpid)
    sleep 0.5
    local pid=$(getpid)
    if [ $pid -eq 0 ];then
      echo "Stopping aria2c: OK."
    else
      echo "Stopping aria2c: FAILED, the pid is $pid."
    fi
  fi
}


# check aria2c daemon process is running or not.
function _status(){
  local pid=$(getpid)
  if [ $pid -ne 0 ];then
    echo "aria2c is running with pid: $pid."
  else
    echo "aria2c is not running at this moment."
  fi
}


# print the help information.
function show_help(){
  echo "Usage: $(basename $0) {--install|--start|--stop|--restart|--status}"
  exit 100
}


# main function
function main(){
  # check the number of args
  [ $# -ne 1 ] && show_help

  # parser args
  case $1 in
    --install)
      install
      ;;
    --start)
      _start
      ;;
    --restart)
      _stop && sleep 1 && _start
      ;;
    --stop)
      _stop
      ;;
    --status)
      _status
      ;;
    *)
      show_help
  esac
}

main $*
