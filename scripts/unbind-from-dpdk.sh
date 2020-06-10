#!/bin/bash

cd /home/opnfv/vswitchperf/src/dpdk/dpdk/usertools
./dpdk-devbind.py --unbind 06:10.0 06:10.1
./dpdk-devbind.py -b ixgbevf 06:10.0 06:10.1
