#!/bin/bash
workspace=$(cd `dirname $0`/..; pwd)
cd $workspace

[ -d logs ] || mkdir logs

docker rm reposync

docker run --name=reposync \
-v /opt/mirrors/repos:/etc/yum.repos.d \
-v /opt/mirrors/centos:/opt/mirrors/centos reposync |& tee  logs/reposync.`date +%Y.%m.%d`.log >/dev/null 2>&1

sleep 3
tree centos > logs/tree.`date +%Y-%m-%d`.log

sleep 1
yum clean all
yum makecache
