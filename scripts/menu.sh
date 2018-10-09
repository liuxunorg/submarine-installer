#!/bin/bash 

. ${ROOT}/scripts/utils.sh
. ${ROOT}/scripts/environment.sh
. ${ROOT}/scripts/download-server.sh

main_menu()
{
cat<<MENULIST
====================================================================================
                          submarine assembly
           support centos-release-7-3.1611.el7.centos.x86_64 or higher
====================================================================================
[menu]
------------------------------------------------------------------------------------
MENULIST
echo -e "  \e[32m1.prepare system environment [..]\e[0m"
echo -e "  \e[32m2.install component [..]\e[0m"
echo -e "  \e[32m3.uninstall component [..]\e[0m"
echo -e "  \e[32m4.start component [..]\e[0m"
echo -e "  \e[32m5.stop component [..]\e[0m"
echo -e "  \e[32m6.start download server [..]\e[0m"
echo -e ""
echo -e "  \e[32mq.quit\e[0m"
cat<<MENULIST
==================================================================================== 
MENULIST

echo -ne "Please input your choice [\e[32m1\e[0m-\e[32m6\e[0m,\e[32mq\e[0m(quit)]:" 
}

check_menu()
{
cat<<MENULIST
====================================================================================

submarine assembly

====================================================================================
[menu] > [prepare system environment]
------------------------------------------------------------------------------------
MENULIST
echo -e "  \e[32m1.prepare operation system\e[0m"
echo -e "  \e[32m2.prepare operation system kernel\e[0m"
echo -e "  \e[32m3.prepare GCC version\e[0m"
echo -e "  \e[32m4.check GPU\e[0m"
echo -e "  \e[32m5.prepare user&group\e[0m"
echo -e "  \e[32m6.prepare nvidia environment\e[0m"
echo -e ""
echo -e "  \e[32mb.back main menu\e[0m"
cat<<MENULIST
==================================================================================== 
MENULIST

echo -ne "Please input your choice [\e[32m1\e[0m-\e[32m5\e[0m,\e[32mb\e[0m(back)]:" 
}

install_menu()
{
cat<<MENULIST
====================================================================================

submarine assembly

====================================================================================
[menu] > [install component]
------------------------------------------------------------------------------------
MENULIST
echo -e "  \e[32m1.instll etcd\e[0m"
echo -e "  \e[32m2.instll docker\e[0m"
echo -e "  \e[32m3.instll calico network\e[0m"
echo -e "  \e[32m4.instll nvidia driver\e[0m"
echo -e "  \e[32m5.instll nvidia docker\e[0m"
echo -e "  \e[32m6.instll yarn container-executor\e[0m"
echo -e "  \e[32m7.instll submarine autorun script\e[0m"
echo -e ""
echo -e "  \e[32mb.back main menu\e[0m"
cat<<MENULIST
==================================================================================== 
MENULIST

echo -ne "Please input your choice [\e[32m1\e[0m-\e[32m7\e[0m,\e[32mb\e[0m(back)]:" 
}

uninstall_menu()
{
cat<<MENULIST
====================================================================================

submarine assembly

====================================================================================
[menu] > [uninstll component]
------------------------------------------------------------------------------------
MENULIST
echo -e "  \e[32m1.uninstll etcd\e[0m"
echo -e "  \e[32m2.uninstll docker\e[0m"
echo -e "  \e[32m3.uninstll calico network\e[0m"
echo -e "  \e[32m4.uninstll nvidia driver\e[0m"
echo -e "  \e[32m5.uninstll nvidia docker\e[0m"
echo -e "  \e[32m6.uninstll yarn container-executor\e[0m"
echo -e "  \e[32m7.uninstll submarine autorun script\e[0m"
echo -e ""
echo -e "  \e[32mb.back main menu\e[0m"
cat<<MENULIST
==================================================================================== 
MENULIST

echo -ne "Please input your choice [\e[32m1\e[0m-\e[32m7\e[0m,\e[32mb\e[0m(back)]:" 
}

start_menu()
{
cat<<MENULIST
====================================================================================

submarine assembly

====================================================================================
[menu] > [stop component]
------------------------------------------------------------------------------------
MENULIST
echo -e "  \e[32m1.start etcd\e[0m"
echo -e "  \e[32m2.start docker\e[0m"
echo -e "  \e[32m3.start calico network\e[0m"
echo -e "  \e[32m4.start nvidia driver\e[0m"
echo -e "  \e[32m5.start nvidia docker\e[0m"
echo -e "  \e[32m6.start submarine autorun script\e[0m"
echo -e ""
echo -e "  \e[32mb.back main menu\e[0m"
cat<<MENULIST
==================================================================================== 
MENULIST

echo -ne "Please input your choice [\e[32m1\e[0m-\e[32m6\e[0m,\e[32mb\e[0m(back)]:" 
}

stop_menu()
{
cat<<MENULIST
====================================================================================

submarine assembly

====================================================================================
[menu] > [stop component]
------------------------------------------------------------------------------------
MENULIST
echo -e "  \e[32m1.stop etcd\e[0m"
echo -e "  \e[32m2.stop docker\e[0m"
echo -e "  \e[32m3.stop calico network\e[0m"
echo -e "  \e[32m4.stop nvidia driver\e[0m"
echo -e "  \e[32m5.stop nvidia docker\e[0m"
echo -e "  \e[32m6.stop submarine autorun script\e[0m"
echo -e "  \e[32m7.stop all\e[0m"
echo -e ""
echo -e "  \e[32mb.back main menu\e[0m"
cat<<MENULIST
==================================================================================== 
MENULIST

echo -ne "Please input your choice [\e[32m1\e[0m-\e[32m6\e[0m,\e[32mb\e[0m(back)]:" 
}

menu_index="0"
menu() 
{ 
  clear 
  echo "menu_index-menu_choice=$menu_index-$menu_choice"
  case $menu_index in
    "0")
      main_menu
    ;;
    "1")
      check_menu
    ;;
    "2")
      install_menu
    ;;
    "3")
      uninstall_menu
    ;;
    "4")
      start_menu
    ;;
    "5")
      stop_menu
    ;;
    "6")
      start_download_server
    ;;
    "q")
    	exit 1
    ;;
    *)
      echo "error "
      menu_index="0"
      menu_choice="0"
      main_menu
    ;;
  esac

  read menu_choice 
} 

menu_process()
{
  process=0
  unset myselect
  echo "aaaa=$menu_index-$menu_choice"
  case "$menu_index-$menu_choice" in 
    "1-b"|"2-b"|"3-b"|"4-b"|"5-b"|"6-b")
      menu_index="0"
      menu_choice="0"
    ;;
# check system environment
    "1-1")
      myselect="y"
      check_operationSystem
    ;; 
    "1-2")
      myselect="y"
      check_operationSystemKernel
    ;; 
    "1-3")
      myselect="y"
      check_gccVersion
    ;; 
    "1-4")
      myselect="y"
      check_GPU
    ;; 
    "1-5")
      myselect="y"
      check_userGroup
    ;; 
    "1-6")
      myselect="y"
      prepare_nvidia_environment
    ;; 
# install component
    "2-1")
      echo -n "Do you want to install etcd?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        install_etcd
      fi
    ;;
    "2-2")
      echo -n "Do you want to install docker?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        install_docker
      fi
    ;;
    "2-3")
      echo -n "Do you want to install calico network?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        install_calico
      fi
    ;;
    "2-4")
      echo -n "Do you want to install nvidia driver?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        install_nvidia
      fi
    ;;
    "2-5")
      echo -n "Do you want to install nvidia docker?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        install_nvidia_docker
      fi
    ;;
    "2-6")
      echo -n "Do you want to install yarn container-executor?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        install_yarn_container_executor
      fi
    ;;
    "2-7")
      echo -n "Do you want to install submarine auto start script?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        install_submarine
      fi
    ;;
# uninstall component
    "3-1")
      echo -n "Do you want to uninstall etcd?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        uninstall_etcd
      fi
    ;;
    "3-2")
      echo -n "Do you want to uninstall docker?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        uninstall_docker
      fi
    ;;
	 "3-3")
      echo -n "Do you want to uninstall calico network?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        uninstall_calico
      fi
    ;;
    "3-4")
      echo -n "Do you want to uninstall nvidia driver?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        uninstall_nvidia
      fi
    ;;
    "3-5")
      echo -n "Do you want to uninstall nvidia docker?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        uninstall_nvidia_docker
      fi
    ;;
    "3-6")
      echo -n "Do you want to uninstall yarn container-executor?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        uninstall_yarn_container_executor
      fi
    ;;
    "3-7")
      echo -n "Do you want to uninstall submarine autostart script?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        uninstall_submarine
      fi
    ;;
# startup component
    "4-1")
      echo -n "Do you want to startup etcd?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        start_etcd
      fi
    ;;
    "4-2")
      echo -n "Do you want to startup docker?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        start_docker
      fi
    ;;
    "4-3")
      echo -n "Do you want to startup calico network?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        start_calico
      fi
    ;;
    "4-4")
      echo -n "Do you want to startup nvidia driver?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        echo ""
      fi
    ;;
    "4-5")
      echo -n "Do you want to startup nvidia docker?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        echo ""
      fi
    ;;
    "4-6")
      echo -n "Do you want to startup submarine autostart script?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then  
        echo ""
      fi
    ;;
# stop component
    "5-1")
      echo -n "Do you want to stop etcd?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        stop_etcd
      fi
    ;;
    "5-2")
      echo -n "Do you want to stop docker?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        stop_docker
      fi
    ;;
    "5-3")
      echo -n "Do you want to stop calico network?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        stop_calico
      fi
    ;;
    "5-4")
      echo -n "Do you want to stop nvidia driver?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        echo ""
      fi
    ;;
    "5-5")
      echo -n "Do you want to stop nvidia docker?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then
        echo ""
      fi
    ;;
    "5-6")
      echo -n "Do you want to stop submarine autostart script?[y|n]"
      read myselect
      if [[ "$myselect" = "y" || "$myselect" = "Y" ]]
      then  
        echo ""
      fi
    ;;
  esac

  if [[ "$myselect" = "y" || "$myselect" = "Y" ]] 
  then
    process=1
  fi

#  echo "process=$process"
  return $process
}

