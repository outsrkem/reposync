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

repo_id=(WANdisco-git nginx docker-ce-stable base elrepo elrepo-kernel epel extras updates)
for repo in ${repo_id[@]};do
    _log_info "reposync $repo"
    reposync -r $repo -p /opt/mirrors/centos/7/x86_64
done

sleep 1
_log_info "start update createrepo"

for i in `ls /opt/mirrors/centos/7/x86_64`;do
    _log_info "createrepo $i"
    createrepo --update /opt/mirrors/centos/7/x86_64/$i
done

_log_info "sync successfully."
