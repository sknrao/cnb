sudo vppctl set interface state TenGigabitEthernet6/0/0 up
sudo vppctl set interface state TenGigabitEthernet6/0/1 up
sudo vppctl set interface l2 xconnect TenGigabitEthernet6/0/0 memif1/0
sudo vppctl set interface l2 xconnect TenGigabitEthernet6/0/1 memif2/0
sudo vppctl set interface l2 xconnect memif1/0 TenGigabitEthernet6/0/0
sudo vppctl set interface l2 xconnect memif2/0 TenGigabitEthernet6/0/1
sudo vppctl test l2patch rx TenGigabitEthernet6/0/0 tx memif1/0
sudo vppctl test l2patch rx TenGigabitEthernet6/0/1 tx memif2/0
sudo vppctl test l2patch rx memif1/0 tx TenGigabitEthernet6/0/0
sudo vppctl test l2patch rx memif2/0 tx TenGigabitEthernet6/0/1
