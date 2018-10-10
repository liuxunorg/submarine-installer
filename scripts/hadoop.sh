#!/bin/bash


function install_yarn()
{
	install_yarn_container_executor
  install_yarn_config
}

function uninstall_yarn()
{
  rm -rf /etc/yarn/sbin/Linux-amd64-64/*
  rm -rf /etc/yarn/sbin/etc/hadoop/*
}

function download_yarn_container_executor()
{
  # my download http server
  if [[ -n "$DOWNLOAD_HTTP" ]]; then
    MY_YARN_CONTAINER_EXECUTOR_PATH="${DOWNLOAD_HTTP}/downloads/hadoop/container-executor"
  else
    MY_YARN_CONTAINER_EXECUTOR_PATH=${YARN_CONTAINER_EXECUTOR_PATH}
  fi

  if [ -d "${DOWNLOAD_DIR}/hadoop/" ]; then
    mkdir -p ${DOWNLOAD_DIR}/hadoop/
  fi

  if [[ -f "${DOWNLOAD_DIR}/hadoop/container-executor" ]]; then
    echo "${DOWNLOAD_DIR}/hadoop/container-executor is exist."
  else
    if [[ -n "$DOWNLOAD_HTTP" ]]; then
      echo "download ${MY_YARN_CONTAINER_EXECUTOR_PATH} ..."
      wget -P ${DOWNLOAD_DIR}/hadoop ${MY_YARN_CONTAINER_EXECUTOR_PATH}
    else
      echo "copy ${MY_YARN_CONTAINER_EXECUTOR_PATH} ..."
      cp ${MY_YARN_CONTAINER_EXECUTOR_PATH} ${DOWNLOAD_DIR}/hadoop/
    fi
  fi
}

function install_yarn_container_executor()
{
  download_yarn_container_executor

  if [ -d "/etc/yarn/sbin/Linux-amd64-64" ]; then
    mkdir -p /etc/yarn/sbin/Linux-amd64-64
  fi
  cp ${DOWNLOAD_DIR}/hadoop/container-executor /etc/yarn/sbin/Linux-amd64-64

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
  sed -i "s/YARN_HIERARCHY_REPLACE/${YARN_HIERARCHY}/g" $INSTALL_TEMP_DIR/hadoop/container-executor.cfg >>$LOG

  if [ -d "/etc/yarn/sbin/etc/hadoop" ]; then
    mkdir -p /etc/yarn/sbin/etc/hadoop
  fi

  cp $INSTALL_TEMP_DIR/hadoop/container-executor.cfg /etc/yarn/sbin/etc/hadoop
}
