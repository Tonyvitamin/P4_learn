#!/bin/sh

echo register_read  heavy_counters_flowID_1 | simple_switch_CLI --thrift-port 9090
echo register_read  heavy_counters_p_vote_1 | simple_switch_CLI --thrift-port 9090
echo register_read  heavy_counters_flag_1 | simple_switch_CLI --thrift-port 9090
echo register_read  heavy_counters_total_vote_1 | simple_switch_CLI --thrift-port 9090

echo register_read  cm_sketch1_r1 | simple_switch_CLI --thrift-port 9090

echo register_read  heavy_counters_flowID_2 | simple_switch_CLI --thrift-port 9090
echo register_read  heavy_counters_p_vote_2 | simple_switch_CLI --thrift-port 9090
echo register_read  heavy_counters_flag_2 | simple_switch_CLI --thrift-port 9090
echo register_read  heavy_counters_total_vote_2 | simple_switch_CLI --thrift-port 9090

echo register_read  cm_sketch2_r1 | simple_switch_CLI --thrift-port 9090
