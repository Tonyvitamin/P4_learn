#! /bin/bash


echo register_reset cm_sketch3_r1 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch3_r2 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch3_r3 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset hp4           | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset hp5           | simple_switch_CLI --thrift-port 9090 > /dev/null

echo register_reset mask_queried_3 | simple_switch_CLI --thrift-port 9090 > /dev/null   
