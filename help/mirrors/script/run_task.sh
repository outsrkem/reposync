#!/bin/bash
workspace=$(cd `dirname $0`/..; pwd)
cd $workspace

[ -d logs ] || mkdir logs

# 删除10天前的日志
mark=`date -d -10day +%s`
for f in `ls logs`;do
    log_date=$(echo $f | grep -oP '(?<=tree.|reposync.)[0-9]{4}.[0-9]{2}.[0-9]{2}')
    if [ $(($mark - $(date -d "${log_date//./-}" +%s))) -gt 0 ];then
        [ -f "logs/$f" ] &&rm -f logs/$f
    fi
done

# 清理旧容器
ct=`docker ps -a |grep reposync$`
if [ -n "$ct" ];then
    docker rm reposync
fi

# 启动任务
sleep 1
docker run --name=reposync \
-e REPO_ID=base,updates,extras,epel,WANdisco-git,nginx,docker-ce-stable,kubernetes,elrepo-kernel,elrepo \
-v /opt/mirrors/repos:/etc/yum.repos.d \
-v /opt/mirrors/centos:/opt/mirrors/centos reposync |& tee  logs/reposync.`date +%Y.%m.%d`.log >/dev/null 2>&1

sleep 3
tree centos > logs/tree.`date +%Y-%m-%d`.log

sleep 1
yum clean all
yum makecache
