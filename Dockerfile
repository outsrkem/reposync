FROM centos:7.8.2003

#COPY repos/ /etc/yum.repos.d
RUN rm -rf /etc/yum.repos.d/* && \
    curl -o /etc/yum.repos.d/CentOS-Base-Local.repo http://mirrors.local/repo/CentOS-Base-Local.repo

RUN yum install --downloadonly --downloaddir=/tmp/package createrepo yum-utils

##########################
FROM centos:7.8.2003 as build

RUN ln -fs ../usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN rm -rf /etc/yum.repos.d/*
COPY --from=0 /tmp/package /tmp/package

RUN yum -y localinstall /tmp/package/*.rpm
RUN rm -rf /root/anaconda-ks.cfg /tmp/* /var/cache/yum

COPY rpm-gpg /etc/pki/rpm-gpg
COPY repos /etc/yum.repos.d
COPY sync-repos.sh /opt

WORKDIR /opt

CMD ["/opt/sync-repos.sh"]
