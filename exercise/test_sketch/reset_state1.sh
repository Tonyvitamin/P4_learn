#! /bin/bash


echo register_reset cm_sketch3_r1 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch3_r2 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch3_r3 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset hp6           | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset hp7           | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset hp8           | simple_switch_CLI --thrift-port 9090 > /dev/null

echo register_reset mask_queried_3 | simple_switch_CLI --thrift-port 9090 > /dev/null   
