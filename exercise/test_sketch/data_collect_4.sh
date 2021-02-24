#! /bin/bash

echo register_read Flow_ID_9 | simple_switch_CLI --thrift-port 9090 > s1_data.txt
echo register_read Counter_9 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt

echo register_read Flow_ID_10 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read Counter_10 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt

echo register_read Flow_ID_11 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read Counter_11 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt


echo register_read cm_sketch4_r1 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read cm_sketch4_r2 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
echo register_read cm_sketch4_r3 | simple_switch_CLI --thrift-port 9090 >> s1_data.txt
