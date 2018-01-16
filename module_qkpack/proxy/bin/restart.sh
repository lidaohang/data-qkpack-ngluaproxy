#!/bin/bash

ngproxyDirectoryName='/opt/data-qkpack-ngproxy/proxy'

BIN=$ngproxyDirectoryName"bin/nginx"
CONF=$ngproxyDirectoryName"conf/nginx.conf.online"
PID=`ps -ef|grep $BIN |grep -v grep|grep -v rsync | awk '{print $2}'`

if [ x"$PID" != x ];then
	kill $PID;
	echo "[data-qkpack-ngproxy-proxy] kill $PID"
fi

cd $ngproxyDirectoryName

$BIN -c $CONF -p `pwd` 2 > error.out &
sleep 1

PID=`ps -ef|grep $CONF |grep -v grep|grep -v rsync|awk '{print $2}'`
if [ x"$PID" != x ];then
 	echo "[data-qkpack-ngproxy-proxy] $BIN -c $CONF $PID restart success."
else
	echo "[data-qkpack-ngproxy-proxy] $BIN -c $CONF restart failure."
fi