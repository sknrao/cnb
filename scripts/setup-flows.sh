sudo ovs-ofctl --timeout 10 -O OpenFlow13 del-flows vsperf-br0
sudo ovs-ofctl --timeout 10 -O Openflow13 add-flow vsperf-br0 in_port=1,idle_timeout=0,action=output:3
sudo ovs-ofctl --timeout 10 -O Openflow13 add-flow vsperf-br0 in_port=3,idle_timeout=0,action=output:1
sudo ovs-ofctl --timeout 10 -O Openflow13 add-flow vsperf-br0 in_port=2,idle_timeout=0,action=output:4
sudo ovs-ofctl --timeout 10 -O Openflow13 add-flow vsperf-br0 in_port=4,idle_timeout=0,action=output:2
