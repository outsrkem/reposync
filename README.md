### repo
```sh
/etc/yum.repos.d/CentOS7-Base-163.repo
/etc/yum.repos.d/docker-ce.repo
/etc/yum.repos.d//etc/yum.repos.d/elrepo.repo
/etc/yum.repos.d/epel.repo
/etc/yum.repos.d/nginx.repo
/etc/yum.repos.d/wandisco-git.repo
```

### run
```sh
# runtask.sh
#!/bin/bash
workspace=$(cd `dirname $0`/..; pwd)
cd $workspace

docker rm reposync
docker run --name=reposync \
-v /etc/localtime:/etc/localtime:ro \
-v /opt/mirrors/centos:/opt/mirrors/centos \
reposync:1.0.0-alpha |& tee  $workspace/logs/reposync.`date +%Y.%m.%d`.log

sleep 3
tree /opt/mirrors/centos/7/x86_64 > /opt/mirrors/logs/`date +%Y-%m-%d`.txt
```
