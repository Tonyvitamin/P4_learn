#! /bin/bash

echo register_read Flow_ID_0 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read Counter_0 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt

echo register_read Flow_ID_1 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read Counter_1 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt

echo register_read Flow_ID_2 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read Counter_2 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt

#echo register_read hp0 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
#echo register_read hp1 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt


echo register_read cm_sketch1_r1 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read cm_sketch1_r2 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read cm_sketch1_r3 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
