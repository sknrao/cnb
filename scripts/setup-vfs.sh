#sudo /home/opnfv/vswitchperf/src/dpdk/dpdk/usertools/dpdk-devbind.py -b ixgbe 06:00.0 06:00.1
#ip link set ens785f0 up
#ip link set ens785f1 up
echo 1 > /sys/class/net/ens785f0/device/sriov_numvfs
echo 1 > /sys/class/net/ens785f1/device/sriov_numvfs
