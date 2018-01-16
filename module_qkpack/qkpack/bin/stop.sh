#!/bin/bash

ngproxyDirectoryName='/opt/data-qkpack-ngproxy/qkpack'

BIN=$ngproxyDirectoryName"sbin/nginx"
PID=`ps -ef|grep $BIN |grep -v grep|grep -v rsync| awk '{print $2}'`

if [ x"$PID" != x ];then
	kill $PID;
	echo "[data-qkpack-ngproxy-qkpack] kill $PID success"
else
	echo "[data-qkpack-ngproxy-qkpack] stoped already"	
fi
