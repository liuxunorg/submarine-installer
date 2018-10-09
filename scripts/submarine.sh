#!/bin/bash

function install_submarine()
{
	cp ${PACKAGE_DIR}/submarine/submarine.sh /etc/rc.d/init.d/submarine.sh
  chmod +x /etc/rc.d/init.d/submarine.sh
  chmod +x /etc/rc.d/rc.local

  if [ `grep -c "/etc/rc.d/init.d/submarine.sh" /etc/rc.d/rc.local` -eq '0' ]; then
    echo "/etc/rc.d/init.d/submarine.sh">> /etc/rc.d/rc.local
  fi
}

function uninstall_submarine()
{
  rm /etc/rc.d/init.d/submarine.sh
}