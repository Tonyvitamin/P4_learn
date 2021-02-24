#! /bin/bash

echo register_read Flow_ID_3 | simple_switch_CLI --thrift-port 9090 > s2_data.txt
echo register_read Counter_3 | simple_switch_CLI --thrift-port 9090 >> s2_data.txt

echo register_read Flow_ID_4 | simple_switch_CLI --thrift-port 9090 >> s2_data.txt
echo register_read Counter_4 | simple_switch_CLI --thrift-port 9090 >> s2_data.txt

echo register_read Flow_ID_5 | simple_switch_CLI --thrift-port 9090 >> s2_data.txt
echo register_read Counter_5 | simple_switch_CLI --thrift-port 9090 >> s2_data.txt



echo register_read cm_sketch2_r1 | simple_switch_CLI --thrift-port 9090 >> s2_data.txt
echo register_read cm_sketch2_r2 | simple_switch_CLI --thrift-port 9090 >> s2_data.txt
echo register_read cm_sketch2_r3 | simple_switch_CLI --thrift-port 9090 >> s2_data.txt
