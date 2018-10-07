#!/bin/bash

# Solution: Grant user yarn the access to /sys/fs/cgroup/cpu,cpuacct, 
# which is the subfolder of cgroup mount destination.
chown :yarn -R /sys/fs/cgroup/cpu,cpuacct
chmod g+rwx -R /sys/fs/cgroup/cpu,cpuacct

# If GPUs are used，the access to cgroup devices folder is neede as well
chown :yarn -R /sys/fs/cgroup/devices
chmod g+rwx -R /sys/fs/cgroup/devices

