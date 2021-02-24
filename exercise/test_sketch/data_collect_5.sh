#! /bin/bash

echo register_read Flow_ID_12 | simple_switch_CLI --thrift-port 9090 > s1_data.txt
echo register_read Counter_12 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt

echo register_read Flow_ID_13 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read Counter_13 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt

echo register_read Flow_ID_14 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read Counter_14 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt


echo register_read cm_sketch5_r1 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read cm_sketch5_r2 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read cm_sketch5_r3 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
