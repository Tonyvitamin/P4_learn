#! /bin/bash

echo register_read Flow_ID_6 | simple_switch_CLI --thrift-port 9090 > s1_data.txt
echo register_read Counter_6 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt

echo register_read Flow_ID_7 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read Counter_7 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt

echo register_read Flow_ID_8 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read Counter_8 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt


echo register_read cm_sketch3_r1 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read cm_sketch3_r2 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read cm_sketch3_r3 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
