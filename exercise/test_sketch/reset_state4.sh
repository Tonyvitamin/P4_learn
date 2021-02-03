#! /bin/bash


echo register_reset cm_sketch1_r1 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch1_r2 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch1_r3 | simple_switch_CLI --thrift-port 9090 > /dev/null

echo register_reset hp0           | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset hp1           | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset post_sketch1_r1 | simple_switch_CLI --thrift-port 9090 > /dev/null

echo register_reset mask_queried_1 | simple_switch_CLI --thrift-port 9090 > /dev/null
