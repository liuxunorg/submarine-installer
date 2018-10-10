#!/bin/bash


function download_docker_rpm()
{
  # submarin http server
  if [[ -n "$DOWNLOAD_HTTP" ]]; then
    MY_DOCKER_ENGINE_SELINUX_RPM="${DOWNLOAD_HTTP}/downloads/docker/${DOCKER_ENGINE_SELINUX_RPM}"
    MY_DOCKER_ENGINE_RPM="${DOWNLOAD_HTTP}/downloads/docker/${DOCKER_ENGINE_RPM}"
  else
    MY_DOCKER_ENGINE_SELINUX_RPM=${DOCKER_REPO}/${DOCKER_ENGINE_SELINUX_RPM}
    MY_DOCKER_ENGINE_RPM=${DOCKER_REPO}/${DOCKER_ENGINE_RPM}
  fi

  # download docker rpm
  if [[ -f ${DOWNLOAD_DIR}/docker/${DOCKER_ENGINE_SELINUX_RPM} ]]; then
    echo "${DOWNLOAD_DIR}/docker/${DOCKER_ENGINE_SELINUX_RPM} is exist."
  else
    echo "download ${MY_DOCKER_ENGINE_SELINUX_RPM} ..."
    wget -P ${DOWNLOAD_DIR}/docker/ ${MY_DOCKER_ENGINE_SELINUX_RPM}
  fi

  if [[ -f ${DOWNLOAD_DIR}/docker/${DOCKER_ENGINE_RPM} ]]; then
    echo "${DOWNLOAD_DIR}/docker/${DOCKER_ENGINE_RPM} is exist."
  else
    echo "download ${MY_DOCKER_ENGINE_RPM} ..."
    wget -P ${DOWNLOAD_DIR}/docker/ ${MY_DOCKER_ENGINE_RPM}
  fi
}

function install_docker_bin()
{
  download_docker_rpm

  yum -y localinstall ${DOWNLOAD_DIR}/docker/${DOCKER_ENGINE_SELINUX_RPM}
  yum -y localinstall ${DOWNLOAD_DIR}/docker/${DOCKER_ENGINE_RPM}
}

function uninstall_docker_bin()
{
  download_docker_rpm

  yum -y remove ${DOWNLOAD_DIR}/docker/${DOCKER_ENGINE_SELINUX_RPM}
  yum -y remove ${DOWNLOAD_DIR}/docker/${DOCKER_ENGINE_RPM}
}

function install_docker_config()
{
  rm -rf ${INSTALL_TEMP_DIR}/docker
  cp -R ${PACKAGE_DIR}/docker ${INSTALL_TEMP_DIR}/

  # replace cluster-store
  # "cluster-store":"etcd://10.196.69.173:2379,10.196.69.174:2379,10.196.69.175:2379"
  # char '/' need to escape '\/'
  clusterStore="etcd:\/\/"
  index=1
  etcdHostsSize=${#ETCD_HOSTS[@]}
  for item in ${ETCD_HOSTS[@]}
  do
    clusterStore="${clusterStore}${item}:2379"
    if [[ ${index} -lt ${etcdHostsSize}-1 ]]; then
      clusterStore=${clusterStore}","
    fi
    index=$(($index+1))
  done
  echo "clusterStore=${clusterStore}"
  sed -i "s/CLUSTER_STORE_REPLACE/${clusterStore}/g" $INSTALL_TEMP_DIR/docker/daemon.json >>$LOG

  sed -i "s/DOCKER_REGISTRY_REPLACE/${DOCKER_REGISTRY}/g" $INSTALL_TEMP_DIR/docker/daemon.json >>$LOG
  sed -i "s/LOCAL_HOST_IP_REPLACE/${LOCAL_HOST_IP}/g" $INSTALL_TEMP_DIR/docker/daemon.json >>$LOG
  sed -i "s/YARN_DNS_HOST_REPLACE/${YARN_DNS_HOST}/g" $INSTALL_TEMP_DIR/docker/daemon.json >>$LOG
  sed -i "s/LOCAL_DNS_HOST_REPLACE/${LOCAL_DNS_HOST}/g" $INSTALL_TEMP_DIR/docker/daemon.json >>$LOG

  if [ ! -d "/etc/docker" ]; then
    mkdir /etc/docker
  fi

  cp $INSTALL_TEMP_DIR/docker/daemon.json /etc/docker/
  cp $INSTALL_TEMP_DIR/docker/docker.service /etc/systemd/system/ >>$LOG
}

function install_docker()
{
  install_docker_bin
  install_docker_config

  systemctl daemon-reload
  systemctl enable docker.service
}

function uninstall_docker()
{
  echo "stop docker service"
  systemctl stop docker

  echo "remove docker"
  uninstall_docker_bin

  rm /etc/docker/daemon.json >>$LOG
  rm /etc/systemd/system/docker.service >>$LOG

  systemctl daemon-reload
}

function start_docker()
{
  systemctl restart docker
  systemctl status docker
  docker info
}

function stop_docker()
{
  systemctl stop docker
  systemctl status docker
}

function containers_exist()
{
  local dockerContainersInfo=`docker ps --filter NAME=$1`
  echo ${dockerContainersInfo} | grep $1
}
