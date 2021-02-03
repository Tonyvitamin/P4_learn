#! /bin/bash

echo register_reset cm_sketch2_r1 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch2_r2 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch2_r3 | simple_switch_CLI --thrift-port 9090 > /dev/null

echo register_reset hp3           | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset hp4           | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset hp5           | simple_switch_CLI --thrift-port 9090 > /dev/null


echo register_reset mask_queried_2 | simple_switch_CLI --thrift-port 9090 > /dev/null  
