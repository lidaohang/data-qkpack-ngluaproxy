#!/bin/bash

ngproxyDirectoryName='/opt/data-qkpack-ngproxy/proxy'

BIN=$ngproxyDirectoryName"bin/nginx"
PID=`ps -ef|grep $BIN |grep -v grep|grep -v rsync| awk '{print $2}'`

if [ x"$PID" != x ];then
	kill $PID;
	echo "[data-qkpack-ngproxy-proxy] kill $PID success"
else
	echo "[data-qkpack-ngproxy-proxy] stoped already"	
fi