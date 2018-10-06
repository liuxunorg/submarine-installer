
DOCKER_REPO=https://yum.dockerproject.org/repo/main/centos/7/Packages
DOCKER_ENGINE_RPM=docker-engine-1.12.5-1.el7.centos.x86_64.rpm
DOCKER_ENGINE_SELINUX_RPM=docker-engine-selinux-1.12.5-1.el7.centos.noarch.rpm
NVIDIA_DOCKER_ENGINE_SELINUX_RPM=https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker-1.0.1-1.x86_64.rpm

function install_docker()
{
  # download docker rpm
  wget -P ${INSTALL_TEMP_DIR} ${DOCKER_REPO}/${DOCKER_ENGINE_SELINUX_RPM}
  wget -P ${INSTALL_TEMP_DIR} ${DOCKER_REPO}/${DOCKER_ENGINE_RPM}

  yum -y localinstall ${DOCKER_ENGINE_SELINUX_RPM}
  yum -y localinstall ${DOCKER_ENGINE_RPM}

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

  sudo systemctl restart docker
}

