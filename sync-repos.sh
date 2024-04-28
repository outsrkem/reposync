#!/bin/bash
workspace=$(cd `dirname $0`; pwd)
cd $workspace

function _log_info() {
  echo -e "`date "+[%F %T %z]"`[I] $@"
  echo -e "`date "+[%F %T %z]"`[I] $@" >> task.log
}

function check_network(){
    local targets=("www.baidu.com" "www.huawei.com" "www.sina.com.cn" "nginx.org")
    for target in ${targets[@]};do
        curl --location --connect-timeout 3 -o /dev/null -s -w "%{http_code}" "${target}" &>/dev/null
        if [ $? -eq 0 ]; then
            return 1
        fi
    done
    _log_info "ckeck url ${target}"
    return 0
}

function check_update_time(){
    # 计算rpm包更新时间与基准时间，如果在基准时间之后则返回1
    local repo=$1
    local mar=$2
    # 查找最新同步到的rpm包
    # newrpm=/opt/mirrors/centos/7/x86_64/elrepo-kernel/RPMS/kernel-ml-doc-6.8.8-1.el7.elrepo.noarch.rpm
    newrpm=`find /opt/mirrors/centos/7/x86_64/$repo -type f -name "*.rpm" -ctime -1 -exec ls -tr {} +| head -1`
    if [ -z "$newrpm" ];then
        return 0
    fi
    # stat %Z上次更改的时间(Change time)，自纪元以来的秒数
    ctime=`stat -c %Z ${newrpm}`
    if [ $((${mar} - ${ctime})) -lt 0 ];then
        return 1
    else
        return 0
    fi
}

# main
_log_info "+++++++++++++++++++++++++++++++++++++++"
cat <<'EOF'

  The main file or directory:
    /etc/localtime
    /etc/pki/rpm-gpg
    /etc/yum.repos.d
    /opt/mirrors/centos
  Example:
    docker run --name=reposync \
    -v /etc/localtime:/etc/localtime:ro \
    -v /opt/mirrors/centos:/opt/mirrors/centos \
    -v /opt/mirrors/repos.d:/etc/yum.repos.d \
    reposync:1.0.0 |& tee  logs/reposync.`date +%Y.%m.%d`.log

  Tips:
    Use environment variables to configure the warehouse id to be synchronized.

    ... -e REPO_ID=base,updates ...

EOF


_log_info "+++++++++++++++++++++++++++++++++++++++"

check_network; if [ $? -eq 0 ];then
        _log_info "If the network is abnormal, exit task."
        exit 100
fi

_log_info "import rpm-gpg"
find /etc/pki/rpm-gpg -type f
rpm --import /etc/pki/rpm-gpg/*
rpm -q gpg-pubkey
echo 
_log_info "create yum makecache"

yum clean all
yum makecache
yum repolist

for i in `seq 10`;do echo -n "$i ";sleep 1;done; echo 

_log_info "The system starts source synchronization"
# 从环境变量中获取REPO_ID。如果没有，则使用默认配置
# REPO_ID=base,updates
if [ -n "$REPO_ID" ]; then
    repo_id=(${REPO_ID//,/ })
else
    repo_id=(base updates extras epel WANdisco-git nginx docker-ce-stable elrepo-kernel elrepo)
fi


# 同步yum 源
_log_info "repo_id: ${repo_id[@]}"
for repo in ${repo_id[@]};do
    _log_info "reposync $repo"
    reposync -r $repo -p /opt/mirrors/centos/7/x86_64
done

sleep 1
_log_info "start update createrepo"

# 获取6小时前的时间戳
mark=`date -d -6hour "+%s"`
for repo in ${repo_id[@]};do
    if [ ! -d "/opt/mirrors/centos/7/x86_64/$repo" ];then
        continue
    fi
    # 如果rpm包更新时间在 ${m} 小时前，则认为本次没有同步新版本，则不创建元数据。
    check_update_time $repo $mark; if [ $? -eq 1 ];then
        _log_info "create repo $repo"
        createrepo --update /opt/mirrors/centos/7/x86_64/$repo
    else
        _log_info "The $repo version is not updated, and no metadata is created."
    fi
done

_log_info "sync successfully."
