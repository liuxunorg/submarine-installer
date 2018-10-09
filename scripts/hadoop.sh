#!/bin/bash


function install_yarn()
{
	install_yarn_container_executor
  install_yarn_config
}

function download_yarn_container_executor()
{
  # container-executor
  cp ${YARN_CONTAINER_EXECUTOR_PATH} /etc/yarn/sbin/Linux-amd64-64

  if [[ -f ${DOWNLOAD_DIR}/container-executor ]]; then
    echo "${DOWNLOAD_DIR}/container-executor is exist."
  else
    echo "copy ${YARN_CONTAINER_EXECUTOR_PATH} ..."
    cp ${YARN_CONTAINER_EXECUTOR_PATH} ${DOWNLOAD_DIR}/
  fi
}

function install_yarn_container_executor()
{
  mkdir -p /etc/yarn/sbin/Linux-amd64-64
  
  cp ${YARN_CONTAINER_EXECUTOR_PATH} /etc/yarn/sbin/Linux-amd64-64
  sudo chmod 6755 /etc/yarn/sbin/Linux-amd64-64
  sudo chown :yarn /etc/yarn/sbin/Linux-amd64-64/container-executor 
  sudo chmod 6050 /etc/yarn/sbin/Linux-amd64-64/container-executor
}

function install_yarn_config()
{
  cp -R ${PACKAGE_DIR}/hadoop ${INSTALL_TEMP_DIR}/

  sed -i "s/YARN_NODEMANAGER_LOCAL_DIRS_REPLACE/${YARN_NODEMANAGER_LOCAL_DIRS}/g" $INSTALL_TEMP_DIR/hadoop/container-executor.cfg >>$LOG
  sed -i "s/YARN_NODEMANAGER_LOG_DIRS_REPLACE/${YARN_NODEMANAGER_LOG_DIRS}/g" $INSTALL_TEMP_DIR/hadoop/container-executor.cfg >>$LOG
  sed -i "s/DOCKER_REGISTRY_REPLACE/${DOCKER_REGISTRY}/g" $INSTALL_TEMP_DIR/hadoop/container-executor.cfg >>$LOG
  sed -i "s/CALICO_NETWORK_NAME_REPLACE/${CALICO_NETWORK_NAME}/g" $INSTALL_TEMP_DIR/hadoop/container-executor.cfg >>$LOG

  mkdir -p /etc/yarn/conf
  cp ./container-executor.cfg /etc/yarn/conf
}