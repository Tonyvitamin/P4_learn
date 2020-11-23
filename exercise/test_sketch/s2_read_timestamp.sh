#!/bin/sh

echo register_read  cur_timestamp | simple_switch_CLI --thrift-port 9091
echo register_read  last_timestamp | simple_switch_CLI --thrift-port 9091




#echo register_reset  old_cm_sketch_r1 | simple_switch_CLI --thrift-port 9091
#echo register_reset  old_cm_sketch_r2 | simple_switch_CLI --thrift-port 9091
#echo register_reset  old_cm_sketch_r3 | simple_switch_CLI --thrift-port 9091
#echo register_reset  new_cm_sketch_r1 | simple_switch_CLI --thrift-port 9091
#echo register_reset  new_cm_sketch_r2 | simple_switch_CLI --thrift-port 9091
#echo register_reset  new_cm_sketch_r3 | simple_switch_CLI --thrift-port 9091
#echo register_reset  last_timestamp | simple_switch_CLI --thrift-port 9091
#echo register_reset  last_timestamp | simple_switch_CLI --thrift-port 9091
