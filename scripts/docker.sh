#!/bin/bash


function install_docker()
{
  install_docker_bin
  install_docker_config

  systemctl daemon-reload
  systemctl enable docker.service
  systemctl restart docker
}

function install_docker_bin()
{
  # download docker rpm
  wget -P ${INSTALL_TEMP_DIR} ${DOCKER_REPO}/${DOCKER_ENGINE_SELINUX_RPM}
  wget -P ${INSTALL_TEMP_DIR} ${DOCKER_REPO}/${DOCKER_ENGINE_RPM}

  yum -y localinstall ${DOCKER_ENGINE_SELINUX_RPM}
  yum -y localinstall ${DOCKER_ENGINE_RPM}
}

function install_docker_config()
{
  cp -R ${PACKAGE_DIR}/docker ${INSTALL_TEMP_DIR}/

  # replace cluster-store
  # "cluster-store":"etcd://10.196.69.173:2379,10.196.69.174:2379,10.196.69.175:2379"
  clusterStore=''
  index=0
  etcdHostsSize=${#ETCD_HOSTS[@]}
  for item in ${ETCD_HOSTS[@]}
  do
    index=$(($index+1))
    clusterStore=${clusterStore}"etcdnode"${index}"=http://"${item}":2379"
    if [[ ${index} -lt ${etcdHostsSize} ]]; then
      clusterStore=${clusterStore}","
    fi
  done
  echo "clusterStore=${clusterStore}"
  sed -i "s/CLUSTER_STORE_REPLACE/${clusterStore}/g" $INSTALL_TEMP_DIR/docker/daemon.json >>$LOG

  if [ ! -d "/etc/docker" ]; then
    echo "/etc/docker folder path is not exist!"
    mkdir /etc/docker
  fi

  cp $INSTALL_TEMP_DIR/docker/daemon.json /etc/docker/
}

function containers_exist()
{
  local dockerContainersInfo=`docker ps ls --filter NAME=$1`
  echo ${dockerContainersInfo} | grep $1
}
