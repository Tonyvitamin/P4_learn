#! /bin/bash

echo register_reset cm_sketch4_r1 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch4_r2 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset cm_sketch4_r3 | simple_switch_CLI --thrift-port 9090 > /dev/null
echo register_reset mask_queried_4 | simple_switch_CLI --thrift-port 9090 > /dev/null   
