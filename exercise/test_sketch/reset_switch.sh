#!/bin/sh

echo register_reset  old_cm_sketch_r1 | simple_switch_CLI --thrift-port 9090
echo register_reset  old_cm_sketch_r2 | simple_switch_CLI --thrift-port 9090
echo register_reset  old_cm_sketch_r3 | simple_switch_CLI --thrift-port 9090
echo register_reset  new_cm_sketch_r1 | simple_switch_CLI --thrift-port 9090
echo register_reset  new_cm_sketch_r2 | simple_switch_CLI --thrift-port 9090
echo register_reset  new_cm_sketch_r3 | simple_switch_CLI --thrift-port 9090
echo register_reset  cur_timestamp | simple_switch_CLI --thrift-port 9090
echo register_reset  last_timestamp | simple_switch_CLI --thrift-port 9090
echo register_reset  new_cms_estimate | simple_switch_CLI --thrift-port 9090
echo register_reset  old_cms_estimate | simple_switch_CLI --thrift-port 9090



echo register_reset  old_cm_sketch_r1 | simple_switch_CLI --thrift-port 9091
echo register_reset  old_cm_sketch_r2 | simple_switch_CLI --thrift-port 9091
echo register_reset  old_cm_sketch_r3 | simple_switch_CLI --thrift-port 9091
echo register_reset  new_cm_sketch_r1 | simple_switch_CLI --thrift-port 9091
echo register_reset  new_cm_sketch_r2 | simple_switch_CLI --thrift-port 9091
echo register_reset  new_cm_sketch_r3 | simple_switch_CLI --thrift-port 9091
echo register_reset  last_timestamp | simple_switch_CLI --thrift-port 9091
echo register_reset  cur_timestamp | simple_switch_CLI --thrift-port 9091
echo register_reset  new_cms_estimate | simple_switch_CLI --thrift-port 9091
echo register_reset  old_cms_estimate | simple_switch_CLI --thrift-port 9091