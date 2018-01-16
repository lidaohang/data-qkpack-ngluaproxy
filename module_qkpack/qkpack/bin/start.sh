#!/bin/bash

ngproxyDirectoryName='/opt/data-qkpack-ngproxy/qkpack'

BIN=$ngproxyDirectoryName"bin/nginx"
CONF=$ngproxyDirectoryName"conf/nginx.conf.online"
PID=`ps -ef|grep $BIN |grep -v grep|grep -v rsync | awk '{print $2}'`

if [ x"$PID" != x ];then
	echo "[data-qkpack-ngproxy-qkpack] nginx $PID already is running."
	exit 1;
fi

cd $ngproxyDirectoryName

$BIN -c $CONF -p `pwd` 2 > error.out &
sleep 1

PID=`ps -ef|grep $CONF |grep -v grep|grep -v rsync|awk '{print $2}'`
if [ x"$PID" != x ];then
	echo "[data-qkpack-ngproxy-qkpack] $BIN -c $CONF $PID start success."
else
	echo "[data-qkpack-ngproxy-qkpack] $BIN -c $CONF start failure."
fi
