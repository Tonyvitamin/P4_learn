#! /bin/bash

echo register_reset cm_sketch5_r1 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch5_r2 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch5_r3 | simple_switch_CLI --thrift-port 9090 > /dev/null

echo register_reset hp8           | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset hp9           | simple_switch_CLI --thrift-port 9090 > /dev/null

echo register_reset mask_queried_5 | simple_switch_CLI --thrift-port 9090 > /dev/null