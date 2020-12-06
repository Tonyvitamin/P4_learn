#!/bin/sh

#echo register_read  old_cms_estimate | simple_switch_CLI --thrift-port 9090
#echo register_read  old_cm_sketch_r1 | simple_switch_CLI --thrift-port 9090
#echo register_read  old_cm_sketch_r2 | simple_switch_CLI --thrift-port 9090
#echo register_read  old_cm_sketch_r3 | simple_switch_CLI --thrift-port 9090

#echo register_read  new_cms_estimate | simple_switch_CLI --thrift-port 9090
#echo register_read  new_cm_sketch_r1 | simple_switch_CLI --thrift-port 9090
#echo register_read  new_cm_sketch_r2 | simple_switch_CLI --thrift-port 9090
#echo register_read  new_cm_sketch_r3 | simple_switch_CLI --thrift-port 9090
echo register_read  cm_sketch1_r1 | simple_switch_CLI --thrift-port 9090
#echo register_read  cm_sketch1_r2 | simple_switch_CLI --thrift-port 9090
#echo register_read  cm_sketch1_r3 | simple_switch_CLI --thrift-port 9090

echo register_read  cm_sketch2_r1 | simple_switch_CLI --thrift-port 9090
#echo register_read  cm_sketch2_r2 | simple_switch_CLI --thrift-port 9090
#echo register_read  cm_sketch2_r3 | simple_switch_CLI --thrift-port 9090

echo register_read  cm_sketch3_r1 | simple_switch_CLI --thrift-port 9090
echo register_read  cm_sketch4_r1 | simple_switch_CLI --thrift-port 9090
echo register_read  cm_sketch5_r1 | simple_switch_CLI --thrift-port 9090

echo register_read  mask_queried_1 | simple_switch_CLI --thrift-port 9090
echo register_read  mask_queried_2 | simple_switch_CLI --thrift-port 9090
echo register_read  mask_queried_3 | simple_switch_CLI --thrift-port 9090
echo register_read  mask_queried_4 | simple_switch_CLI --thrift-port 9090
echo register_read  mask_queried_5 | simple_switch_CLI --thrift-port 9090

echo register_read  time_flag | simple_switch_CLI --thrift-port 9090


#echo register_read  old_cm_sketch_r1 | simple_switch_CLI --thrift-port 9091
#echo register_read  old_cm_sketch_r2 | simple_switch_CLI --thrift-port 9091
#echo register_read  old_cm_sketch_r3 | simple_switch_CLI --thrift-port 9091
#echo register_read  new_cm_sketch_r1 | simple_switch_CLI --thrift-port 9091
#echo register_read  new_cm_sketch_r2 | simple_switch_CLI --thrift-port 9091
#echo register_read  new_cm_sketch_r3 | simple_switch_CLI --thrift-port 9091
#echo register_read  last_timestamp | simple_switch_CLI --thrift-port 9091
#echo register_read  last_timestamp | simple_switch_CLI --thrift-port 9091
