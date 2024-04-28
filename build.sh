#!/bin/bash
workspace=$(cd `dirname $0`/.; pwd)
cd $workspace
commit_id=`git rev-parse HEAD`
version=$1
if [ -z $version ];then
    echo "Please enter version. example $0 0.0.1"
    exit 1
fi


docker buildx build . \
--build-arg REPOSYNC_REVISION=${commit_id} \
--build-arg REPOSYNC_VERSION=${version} \
--label image.revision=${commit_id} \
--label image.version=${version} \
-t reposync:$version --progress plain
if [ $? -ne 0 ];then
    exit 100
fi


docker buildx build . \
--label image.revision=${commit_id} \
--label image.version=${version} \
--build-arg REPOSYNC_REVISION=${commit_id} \
--build-arg REPOSYNC_VERSION=${version} \
--tag reposync \
--tag swr.cn-north-1.myhuaweicloud.com/onge/reposync:$version \
--tag swr.cn-north-1.myhuaweicloud.com/onge/reposync

