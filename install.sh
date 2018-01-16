#!/bin/bash

installDir='/opt/'
sourceDir='/opt/src/'

ngproxySourceDirectoryName='data-qkpack-ngproxy/'
qkpackSourceDirectoryName=$sourceDir$ngproxySourceDirectoryName"module_qkpack/"

echo "[info] install data-qkpack-ngproxy begin..."

chmod 755 configure
./configure  --prefix=/opt/data-qkpack-ngproxy --with-pcre-jit --with-http_stub_status_module
make
make install

cd $qkpackSourceDirectoryName

cp -r proxy $installDir$ngproxySourceDirectoryName
cp -r qkpack $installDir$ngproxySourceDirectoryName

cp -r $installDir$ngproxySourceDirectoryName"nginx/sbin/nginx" proxy/bin/
cp -r $installDir$ngproxySourceDirectoryName"nginx/sbin/nginx" qkpack/bin/

mkdir -p proxy/logs
mkdir -p qkpack/logs

rm -rf /opt/data-qkpack-ngproxy/bin
rm -rf /opt/data-qkpack-ngproxy/nginx

cp -r $sourceDir$ngproxySourceDirectoryName"module_qkpack/sysctl.conf" /etc/
sysctl -p


echo "[info] install data-qkpack-ngproxy end..."