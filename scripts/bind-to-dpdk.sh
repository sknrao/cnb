#!/bin/bash

cd /home/opnfv/vswitchperf/src/dpdk/dpdk/usertools
./dpdk-devbind.py -b igb_uio 06:10.0 06:10.1
