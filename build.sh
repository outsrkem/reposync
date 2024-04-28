version=$1
if [ -z $version ];then
    echo "Please enter version. example $0 0.0.1"
    exit 1
fi

docker build -t reposync:$version . --progress plain
if [ $? -ne 0 ];then
  exit 100
fi
docker build -t reposync .
docker build -t swr.cn-north-1.myhuaweicloud.com/onge/reposync:$version .
docker build -t swr.cn-north-1.myhuaweicloud.com/onge/reposync .

