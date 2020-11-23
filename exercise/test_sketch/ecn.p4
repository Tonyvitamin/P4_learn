/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<8>  TCP_PROTOCOL = 0x06;
const bit<16> TYPE_IPV4 = 0x800;
const bit<19> ECN_THRESHOLD = 10;


// light part
#define HASH_SEED_r1 10w12
#define HASH_SEED_r2 10w34
#define HASH_SEED_r3 10w56
#define HASH_BASE 10w0
#define HASH_MAX 10w9

// heavy part
#define HASH_BASE_heavy 10w0
#define HASH_MAX_HEAVY 10w9
#define HASH_SEED_heavy 10w78

const bit<32> FLOW_TABLE_SIZE_EACH = 10;
const bit<32> HEAVY_PART_COUNTER_SIZE = 10;
const bit<32> EVICT_THRESHOLD = 5;
const bit<72> IDLE_HEAVY_COUNTER_FLOWID = 168w0;





/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/



typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

@controller_header("packet_in")
header packet_in_header_t {
    bit<9> ingress_port;
    bit<7> direction_id;
    bit<32> flow_size_1;
    bit<32> flow_size_2;
    bit<48> time_interval;
    bit<8> sign;
}

//_PKT_OUT_HDR_ANNOT_
@controller_header("packet_out")
header packet_out_header_t {
    bit<9> egress_port;
    bit<7> _padding;
}

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<6>    diffserv;
    bit<2>    ecn;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}
// tuple in the heavy part of Elastic Sketch
struct heavy_tuple {
    bit<72> flowID;
    bit<32>  p_vote;
    bit<1>   flag;
    bit<32>  total_vote;
}
struct metadata {
    
    // Reward info
    bit<7> direction_id;
    bit<32> flow_size_1;
    bit<32> flow_size_2;
    bit<8>  sign;
    bit<48> time_interval;


    ip4Addr_t srcIP;
    ip4Addr_t dstIP;
    bit<8> protocol;

    bit<72> flowID;
    bit<32> flow_cnt;

    bit<32> ha_heavy;
    heavy_tuple ha_tuple;


    bit<32> ha_r1;
    bit<32> ha_r2;
    bit<32> ha_r3;

    bit<32> qc_r1;
    bit<32> qc_r2;
    bit<32> qc_r3;

    bit<32> cms_freq_estimate;
    /* empty */
}

struct headers {
    packet_out_header_t packet_out;
    packet_in_header_t packet_in;
    ethernet_t   ethernet;
    ipv4_t       ipv4;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition select(standard_metadata.ingress_port) {
            255: parse_packet_out;
            default: parse_ethernet;
        }
    }

    state parse_packet_out {
        packet.extract(hdr.packet_out);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }
    /*
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }
    */
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


control Measurement(inout headers hdr,
                    inout metadata meta,
                    inout standard_metadata_t standard_metadata) {

    /* Sketch 1: Elastic Sketch */

    register<bit<72> >(HEAVY_PART_COUNTER_SIZE) heavy_counters_flowID_1;
    register<bit<32> >(HEAVY_PART_COUNTER_SIZE) heavy_counters_p_vote_1;
    register<bit<1> >(HEAVY_PART_COUNTER_SIZE) heavy_counters_flag_1;
    register<bit<32> >(HEAVY_PART_COUNTER_SIZE) heavy_counters_total_vote_1;

    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch1_r1;
    //register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch1_r2;
    //register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch1_r3;
    //register<bit<32> >(1) old_cms_estimate;
    //register<bit<32> >(1) new_cms_estimate;

    /* Sketch 2: Elastic Sketch */


    register<bit<72> >(HEAVY_PART_COUNTER_SIZE) heavy_counters_flowID_2;
    register<bit<32> >(HEAVY_PART_COUNTER_SIZE) heavy_counters_p_vote_2;
    register<bit<1> >(HEAVY_PART_COUNTER_SIZE) heavy_counters_flag_2;
    register<bit<32> >(HEAVY_PART_COUNTER_SIZE) heavy_counters_total_vote_2;

    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch2_r1;
    //register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch2_r2;
    //register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch2_r3;




    register<bit<48> > (1) last_timestamp;
    register<bit<48> > (1) cur_timestamp;

    action heavy_part_init_1() {
        hash(meta.ha_heavy, HashAlgorithm.crc16, HASH_BASE_heavy,
                {meta.flowID, HASH_SEED_heavy}, HASH_MAX_HEAVY);

        heavy_counters_flowID_1.read(meta.ha_tuple.flowID, meta.ha_heavy);
        heavy_counters_p_vote_1.read(meta.ha_tuple.p_vote, meta.ha_heavy);
        heavy_counters_flag_1.read(meta.ha_tuple.flag, meta.ha_heavy);
        heavy_counters_total_vote_1.read(meta.ha_tuple.total_vote, meta.ha_heavy);
    }

    action heavy_part_init_2() {
        hash(meta.ha_heavy, HashAlgorithm.crc16, HASH_BASE_heavy,
                {meta.flowID, HASH_SEED_heavy}, HASH_MAX_HEAVY);

        heavy_counters_flowID_2.read(meta.ha_tuple.flowID, meta.ha_heavy);
        heavy_counters_p_vote_2.read(meta.ha_tuple.p_vote, meta.ha_heavy);
        heavy_counters_flag_2.read(meta.ha_tuple.flag, meta.ha_heavy);
        heavy_counters_total_vote_2.read(meta.ha_tuple.total_vote, meta.ha_heavy);
    }
    /*action min_cnt(inout bit<32> mincnt, in bit<32> cnt1, in bit<32> cnt2, in bit<32> cnt3){
        if(cnt1 < cnt2){
            mincnt = cnt1;
        }
        else {
            mincnt = cnt2;
        }

        if(mincnt>cnt3){
            mincnt = cnt3;
        }
    }*/
    apply{
            meta.srcIP = hdr.ipv4.srcAddr;
            meta.dstIP = hdr.ipv4.dstAddr;
            meta.protocol = hdr.ipv4.protocol;

            meta.flowID[31:0] = meta.srcIP;
            meta.flowID[63:32] = meta.dstIP;
            meta.flowID[71:64] = meta.protocol;

            meta.flow_cnt = 1;//standard_metadata.packet_length;
            hash(meta.ha_heavy, HashAlgorithm.crc16, HASH_BASE, {meta.flowID, HASH_SEED_heavy}, HASH_MAX_HEAVY);
            hash(meta.ha_r1, HashAlgorithm.crc16, HASH_BASE, {meta.flowID, HASH_SEED_r1}, HASH_MAX);
            //hash(meta.ha_r2, HashAlgorithm.crc16, HASH_BASE, {meta.flowID, HASH_SEED_r2}, HASH_MAX);
            //hash(meta.ha_r3, HashAlgorithm.crc16, HASH_BASE, {meta.flowID, HASH_SEED_r3}, HASH_MAX);

            bit<48>  t_diff;
            bit<48>  ct;
            bit<48>  lt;
            //cur_timestamp.read(ct, 0);
            ct = standard_metadata.ingress_global_timestamp;
            cur_timestamp.write(0, standard_metadata.ingress_global_timestamp);

            last_timestamp.read(lt, 0);
            t_diff = ct - lt;

            // Measurement & Update interval info


            // Measurement start up
            if(lt==0){
                last_timestamp.write(0, ct);



                /**** heavy part process ****/
                heavy_part_init_1();
                bit<1> is_heavy_processed = 0;

                // f == f
                if(meta.ha_tuple.flowID == meta.flowID){
                    heavy_counters_p_vote_1.write(meta.ha_heavy, meta.ha_tuple.p_vote + meta.flow_cnt);
                    is_heavy_processed = 1;
                }

                // f = empty
                if(meta.ha_tuple.flowID == IDLE_HEAVY_COUNTER_FLOWID){
                    // hashed counter in heavy part is idle
                    heavy_counters_flowID_1.write(meta.ha_heavy, meta.flowID);
                    heavy_counters_p_vote_1.write(meta.ha_heavy, 32w1);
                    heavy_counters_flag_1.write(meta.ha_heavy, 1w0);

                    is_heavy_processed = 1w1;
                }
            
                heavy_counters_total_vote_1.write(meta.ha_heavy, meta.ha_tuple.total_vote + 1);
                heavy_part_init_1();

                if (meta.ha_tuple.p_vote * EVICT_THRESHOLD <= meta.ha_tuple.total_vote) {
                    // evict the current 'heavy' flow
                    is_heavy_processed = 1w0;

                    // exchange the value of 'current heavy flow' and 'new flow'
                    bit<72> tmp_flowID = meta.ha_tuple.flowID;
                    bit<32> tmp_p_vote = meta.ha_tuple.p_vote;

                    heavy_counters_flowID_1.write(meta.ha_heavy, meta.flowID);
                    heavy_counters_p_vote_1.write(meta.ha_heavy, 32w1);
                    heavy_counters_flag_1.write(meta.ha_heavy, 1w1);
                    heavy_counters_total_vote_1.write(meta.ha_heavy, 32w1);

                    // set the 'evicted flow' in meta, for insertion in CMS
                    meta.flowID = tmp_flowID;
                    meta.flow_cnt = tmp_p_vote;

                    // reload counters into meta
                    heavy_part_init_1();
                }


                /**** light part process ****/
                if(is_heavy_processed == 0){
                    cm_sketch1_r1.read(meta.qc_r1, meta.ha_r1);
                    cm_sketch1_r1.write(meta.ha_r1, meta.qc_r1 + meta.flow_cnt);

                }
                //cm_sketch1_r1.read(meta.qc_r1, meta.ha_r1);
                //cm_sketch1_r2.read(meta.qc_r2, meta.ha_r2);
                //cm_sketch1_r3.read(meta.qc_r3, meta.ha_r3);

                //min_cnt(meta.cms_freq_estimate, meta.qc_r1, meta.qc_r2, meta.qc_r3);
                //cms_estimate.write(0, meta.cms_freq_estimate);
                //cur_timestamp.write(0, standard_metadata.ingress_global_timestamp);

                //cm_sketch1_r1.write(meta.ha_r1, meta.qc_r1 + meta.flow_cnt);
                //cm_sketch1_r2.write(meta.ha_r2, meta.qc_r2 + meta.flow_cnt);
                //cm_sketch1_r3.write(meta.ha_r3, meta.qc_r3 + meta.flow_cnt);
            }

            // Reset Measurement cycle
            else if (t_diff > 21000000){
                last_timestamp.write(0, ct);

                /**** Elastic Sketch 1 reset ****/
                // Heavy part reset
                heavy_counters_flowID_1.write(0, 0);
                heavy_counters_flowID_1.write(1, 0);
                heavy_counters_flowID_1.write(2, 0);
                heavy_counters_flowID_1.write(3, 0);
                heavy_counters_flowID_1.write(4, 0);
                heavy_counters_flowID_1.write(5, 0);
                heavy_counters_flowID_1.write(6, 0);
                heavy_counters_flowID_1.write(7, 0);
                heavy_counters_flowID_1.write(8, 0);
                heavy_counters_flowID_1.write(9, 0);

                heavy_counters_p_vote_1.write(0, 0);
                heavy_counters_p_vote_1.write(1, 0);
                heavy_counters_p_vote_1.write(2, 0);
                heavy_counters_p_vote_1.write(3, 0);
                heavy_counters_p_vote_1.write(4, 0);
                heavy_counters_p_vote_1.write(5, 0);
                heavy_counters_p_vote_1.write(6, 0);
                heavy_counters_p_vote_1.write(7, 0);
                heavy_counters_p_vote_1.write(8, 0);
                heavy_counters_p_vote_1.write(9, 0);

                
                heavy_counters_flag_1.write(0, 0);
                heavy_counters_flag_1.write(1, 0);
                heavy_counters_flag_1.write(2, 0);
                heavy_counters_flag_1.write(3, 0);
                heavy_counters_flag_1.write(4, 0);
                heavy_counters_flag_1.write(5, 0);
                heavy_counters_flag_1.write(6, 0);
                heavy_counters_flag_1.write(7, 0);
                heavy_counters_flag_1.write(8, 0);
                heavy_counters_flag_1.write(9, 0);
                
                heavy_counters_total_vote_1.write(0, 0);
                heavy_counters_total_vote_1.write(1, 0);
                heavy_counters_total_vote_1.write(2, 0);
                heavy_counters_total_vote_1.write(3, 0);
                heavy_counters_total_vote_1.write(4, 0);
                heavy_counters_total_vote_1.write(5, 0);
                heavy_counters_total_vote_1.write(6, 0);
                heavy_counters_total_vote_1.write(7, 0);
                heavy_counters_total_vote_1.write(8, 0);
                heavy_counters_total_vote_1.write(9, 0);

                // light part reset
                cm_sketch1_r1.write(0, 0);
                cm_sketch1_r1.write(1, 0);
                cm_sketch1_r1.write(2, 0);
                cm_sketch1_r1.write(3, 0);
                cm_sketch1_r1.write(4, 0);
                cm_sketch1_r1.write(5, 0);
                cm_sketch1_r1.write(6, 0);
                cm_sketch1_r1.write(7, 0);
                cm_sketch1_r1.write(8, 0);
                cm_sketch1_r1.write(9, 0);

                /*
                cm_sketch1_r2.write(0, 0);
                cm_sketch1_r2.write(1, 0);
                cm_sketch1_r2.write(2, 0);
                cm_sketch1_r2.write(3, 0);
                cm_sketch1_r2.write(4, 0);
                cm_sketch1_r2.write(5, 0);
                cm_sketch1_r2.write(6, 0);
                cm_sketch1_r2.write(7, 0);
                cm_sketch1_r2.write(8, 0);
                cm_sketch1_r2.write(9, 0);

                cm_sketch1_r3.write(0, 0);
                cm_sketch1_r3.write(1, 0);
                cm_sketch1_r3.write(2, 0);
                cm_sketch1_r3.write(3, 0);
                cm_sketch1_r3.write(4, 0);
                cm_sketch1_r3.write(5, 0);
                cm_sketch1_r3.write(6, 0);
                cm_sketch1_r3.write(7, 0);
                cm_sketch1_r3.write(8, 0);
                cm_sketch1_r3.write(9, 0);
                */

                /**** Elastic Sketch 2 reset ****/
                // Heavy part reset
                heavy_counters_flowID_2.write(0, 0);
                heavy_counters_flowID_2.write(1, 0);
                heavy_counters_flowID_2.write(2, 0);
                heavy_counters_flowID_2.write(3, 0);
                heavy_counters_flowID_2.write(4, 0);
                heavy_counters_flowID_2.write(5, 0);
                heavy_counters_flowID_2.write(6, 0);
                heavy_counters_flowID_2.write(7, 0);
                heavy_counters_flowID_2.write(8, 0);
                heavy_counters_flowID_2.write(9, 0);

                heavy_counters_p_vote_2.write(0, 0);
                heavy_counters_p_vote_2.write(1, 0);
                heavy_counters_p_vote_2.write(2, 0);
                heavy_counters_p_vote_2.write(3, 0);
                heavy_counters_p_vote_2.write(4, 0);
                heavy_counters_p_vote_2.write(5, 0);
                heavy_counters_p_vote_2.write(6, 0);
                heavy_counters_p_vote_2.write(7, 0);
                heavy_counters_p_vote_2.write(8, 0);
                heavy_counters_p_vote_2.write(9, 0);

                
                heavy_counters_flag_2.write(0, 0);
                heavy_counters_flag_2.write(1, 0);
                heavy_counters_flag_2.write(2, 0);
                heavy_counters_flag_2.write(3, 0);
                heavy_counters_flag_2.write(4, 0);
                heavy_counters_flag_2.write(5, 0);
                heavy_counters_flag_2.write(6, 0);
                heavy_counters_flag_2.write(7, 0);
                heavy_counters_flag_2.write(8, 0);
                heavy_counters_flag_2.write(9, 0);
                
                heavy_counters_total_vote_2.write(0, 0);
                heavy_counters_total_vote_2.write(1, 0);
                heavy_counters_total_vote_2.write(2, 0);
                heavy_counters_total_vote_2.write(3, 0);
                heavy_counters_total_vote_2.write(4, 0);
                heavy_counters_total_vote_2.write(5, 0);
                heavy_counters_total_vote_2.write(6, 0);
                heavy_counters_total_vote_2.write(7, 0);
                heavy_counters_total_vote_2.write(8, 0);
                heavy_counters_total_vote_2.write(9, 0);

                // light part reset
                cm_sketch2_r1.write(0, 0);
                cm_sketch2_r1.write(1, 0);
                cm_sketch2_r1.write(2, 0);
                cm_sketch2_r1.write(3, 0);
                cm_sketch2_r1.write(4, 0);
                cm_sketch2_r1.write(5, 0);
                cm_sketch2_r1.write(6, 0);
                cm_sketch2_r1.write(7, 0);
                cm_sketch2_r1.write(8, 0);
                cm_sketch2_r1.write(9, 0);

                /*
                cm_sketch2_r2.write(0, 0);
                cm_sketch2_r2.write(1, 0);
                cm_sketch2_r2.write(2, 0);
                cm_sketch2_r2.write(3, 0);
                cm_sketch2_r2.write(4, 0);
                cm_sketch2_r2.write(5, 0);
                cm_sketch2_r2.write(6, 0);
                cm_sketch2_r2.write(7, 0);
                cm_sketch2_r2.write(8, 0);
                cm_sketch2_r2.write(9, 0);

                cm_sketch2_r3.write(0, 0);
                cm_sketch2_r3.write(1, 0);
                cm_sketch2_r3.write(2, 0);
                cm_sketch2_r3.write(3, 0);
                cm_sketch2_r3.write(4, 0);
                cm_sketch2_r3.write(5, 0);
                cm_sketch2_r3.write(6, 0);
                cm_sketch2_r3.write(7, 0);
                cm_sketch2_r3.write(8, 0);
                cm_sketch2_r3.write(9, 0);
                */
            }

            // Self Query & Report reward interval (t3 ~ t3')
            else if (t_diff > 20000000 && t_diff < 20010000 ){

                bit<1> has_lp_2 = 1;
                heavy_tuple ha_tuple_2;
                bit<32> hp_est_2 = 0;
                bit<32> lp_est_2 = 0;
                bit<32> est_2 = 0;
                bit<32> new_r1;
                bit<32> new_r2;
                bit<32> new_r3;
                bit<32> new_min_cnt;


                bit<1> has_lp_1 = 1;
                heavy_tuple ha_tuple_1;
                bit<32> hp_est_1 = 0;
                bit<32> lp_est_1 = 0;
                bit<32> est_1 = 0;
                bit<32> old_r1;
                bit<32> old_r2;
                bit<32> old_r3;
                bit<32> old_min_cnt;
                /**** Query Elastic Sketch 2 ****/
                heavy_counters_flowID_2.read(ha_tuple_2.flowID, meta.ha_heavy);
                heavy_counters_p_vote_2.read(ha_tuple_2.p_vote, meta.ha_heavy);
                heavy_counters_flag_2.read(ha_tuple_2.flag, meta.ha_heavy);
                heavy_counters_total_vote_2.read(ha_tuple_2.total_vote, meta.ha_heavy);

                // Query heavy part
                if(ha_tuple_2.flowID == meta.flowID) {
                    // the counter is for `flowID`. 
                    // read the positive vote to heavy part estimation.
                    // set light part to false
                    hp_est_2 = ha_tuple_2.p_vote;
                    has_lp_2 = 1w0;

                    if(ha_tuple_2.flag == 1w1) {
                        // the counter has changed the `flowID`.
                        // need to query light part
                        has_lp_2 = 1w1;
                    }
                }
                // Query light part
                if(has_lp_2==1){
                    cm_sketch2_r1.read(lp_est_2, meta.ha_r1);
  
                }
                est_2 = hp_est_2 + lp_est_2;
                //cm_sketch2_r1.read(new_r1, meta.ha_r1);
                //cm_sketch2_r2.read(new_r2, meta.ha_r2);
                //cm_sketch2_r3.read(new_r3, meta.ha_r3);
                //min_cnt(new_min_cnt, new_r1, new_r2, new_r3);


                /**** Query Elastic Sketch 1 ****/
                heavy_counters_flowID_1.read(ha_tuple_1.flowID, meta.ha_heavy);
                heavy_counters_p_vote_1.read(ha_tuple_1.p_vote, meta.ha_heavy);
                heavy_counters_flag_1.read(ha_tuple_1.flag, meta.ha_heavy);
                heavy_counters_total_vote_1.read(ha_tuple_1.total_vote, meta.ha_heavy);

                // Query heavy part
                if(ha_tuple_1.flowID == meta.flowID) {
                    // the counter is for `flowID`. 
                    // read the positive vote to heavy part estimation.
                    // set light part to false
                    hp_est_1 = ha_tuple_1.p_vote;
                    has_lp_1 = 1w0;

                    if(ha_tuple_1.flag == 1w1) {
                        // the counter has changed the `flowID`.
                        // need to query light part
                        has_lp_1 = 1w1;
                    }
                }
                // Query light part
                if(has_lp_1==1){
                    cm_sketch1_r1.read(lp_est_1, meta.ha_r1);
  
                }
                est_1 = hp_est_1 + lp_est_1;
                //cm_sketch1_r1.read(old_r1, meta.ha_r1);
                //cm_sketch1_r2.read(old_r2, meta.ha_r2);
                //cm_sketch1_r3.read(old_r3, meta.ha_r3);
                //min_cnt(old_min_cnt, old_r1, old_r2, old_r3);
                
                // flow decrease
                if(est_1 > est_2 + 50){
                    standard_metadata.egress_spec = 255;
                    meta.sign = 1;
                    meta.time_interval = 20000000;
                    meta.flow_size_1 = est_1;
                    meta.flow_size_2 = est_2;
                }

                // flow rate increase
                if(est_2 > est_1+50){
                    standard_metadata.egress_spec = 255;
                    meta.sign = 0;
                    meta.time_interval = 20000000;
                    meta.flow_size_1 = est_1;
                    meta.flow_size_2 = est_2;
                }
                // flow rate decrease
                /*
                if(old_r1 > new_r1 + 50){
                    standard_metadata.egress_spec = 255;
                    meta.sign = 1;
                    meta.time_interval = 20000000;
                    meta.flow_size_1 = old_r1;
                    meta.flow_size_2 = new_r1;
                }

                // flow rate increase
                if(new_r1 > old_r1+50){
                    standard_metadata.egress_spec = 255;
                    meta.sign = 0;
                    meta.time_interval = 20000000;
                    meta.flow_size_1 = old_r1;
                    meta.flow_size_2 = new_r1;
                }
                */
                //old_cms_estimate.write(0, old_min_cnt);
                //new_cms_estimate.write(0, new_min_cnt);

                //old_cm_sketch_r1.write(meta.ha_r1, new_r1);
                //old_cm_sketch_r2.write(meta.ha_r2, new_r2);
                //old_cm_sketch_r3.write(meta.ha_r3, new_r3);

                //new_cm_sketch_r1.write(meta.ha_r1, new_r1 - new_min_cnt);
                //new_cm_sketch_r2.write(meta.ha_r2, new_r2 - new_min_cnt);
                //new_cm_sketch_r3.write(meta.ha_r3, new_r3 - new_min_cnt);

            }
            // Interval 1
            else if (t_diff < 10000000){

                /**** heavy part process ****/
                heavy_part_init_1();
                bit<1> is_heavy_processed = 0;

                // f == f
                if(meta.ha_tuple.flowID == meta.flowID){
                    heavy_counters_p_vote_1.write(meta.ha_heavy, meta.ha_tuple.p_vote + meta.flow_cnt);
                    is_heavy_processed = 1;
                }

                // f = empty
                if(meta.ha_tuple.flowID == IDLE_HEAVY_COUNTER_FLOWID){
                    // hashed counter in heavy part is idle
                    heavy_counters_flowID_1.write(meta.ha_heavy, meta.flowID);
                    heavy_counters_p_vote_1.write(meta.ha_heavy, 32w1);
                    heavy_counters_flag_1.write(meta.ha_heavy, 1w0);

                    is_heavy_processed = 1w1;
                }
            
                heavy_counters_total_vote_1.write(meta.ha_heavy, meta.ha_tuple.total_vote + 1);
                heavy_part_init_1();

                if (meta.ha_tuple.p_vote * EVICT_THRESHOLD <= meta.ha_tuple.total_vote) {
                    // evict the current 'heavy' flow
                    is_heavy_processed = 1w0;

                    // exchange the value of 'current heavy flow' and 'new flow'
                    bit<72> tmp_flowID = meta.ha_tuple.flowID;
                    bit<32> tmp_p_vote = meta.ha_tuple.p_vote;

                    heavy_counters_flowID_1.write(meta.ha_heavy, meta.flowID);
                    heavy_counters_p_vote_1.write(meta.ha_heavy, 32w1);
                    heavy_counters_flag_1.write(meta.ha_heavy, 1w1);
                    heavy_counters_total_vote_1.write(meta.ha_heavy, 32w1);

                    // set the 'evicted flow' in meta, for insertion in CMS
                    meta.flowID = tmp_flowID;
                    meta.flow_cnt = tmp_p_vote;

                    // reload counters into meta
                    heavy_part_init_1();
                }


                /**** light part process ****/
                if(is_heavy_processed == 0){
                    cm_sketch1_r1.read(meta.qc_r1, meta.ha_r1);
                    cm_sketch1_r1.write(meta.ha_r1, meta.qc_r1 + meta.flow_cnt);
                }


                //cm_sketch1_r1.read(meta.qc_r1, meta.ha_r1);
                //cm_sketch1_r2.read(meta.qc_r2, meta.ha_r2);
                //cm_sketch1_r3.read(meta.qc_r3, meta.ha_r3);


                //min_cnt(meta.cms_freq_estimate, meta.qc_r1, meta.qc_r2, meta.qc_r3);
                //cms_estimate.write(0, meta.cms_freq_estimate);
                //cur_timestamp.write(0, standard_metadata.ingress_global_timestamp);

                //cm_sketch1_r1.write(meta.ha_r1, meta.qc_r1 + meta.flow_cnt);
                //cm_sketch1_r2.write(meta.ha_r2, meta.qc_r2 + meta.flow_cnt);
                //cm_sketch1_r3.write(meta.ha_r3, meta.qc_r3 + meta.flow_cnt);


            }

            // Interval 2
            else if (t_diff > 10000000 && t_diff < 20000000){

                /**** heavy part process ****/
                heavy_part_init_2();
                bit<1> is_heavy_processed = 0;

                // f == f
                if(meta.ha_tuple.flowID == meta.flowID){
                    heavy_counters_p_vote_2.write(meta.ha_heavy, meta.ha_tuple.p_vote + meta.flow_cnt);
                    is_heavy_processed = 1;
                }

                // f = empty
                if(meta.ha_tuple.flowID == IDLE_HEAVY_COUNTER_FLOWID){
                    // hashed counter in heavy part is idle
                    heavy_counters_flowID_2.write(meta.ha_heavy, meta.flowID);
                    heavy_counters_p_vote_2.write(meta.ha_heavy, 32w1);
                    heavy_counters_flag_2.write(meta.ha_heavy, 1w0);

                    is_heavy_processed = 1w1;
                }
            
                heavy_counters_total_vote_2.write(meta.ha_heavy, meta.ha_tuple.total_vote + 1);
                heavy_part_init_2();

                if (meta.ha_tuple.p_vote * EVICT_THRESHOLD <= meta.ha_tuple.total_vote) {
                    // evict the current 'heavy' flow
                    is_heavy_processed = 1w0;

                    // exchange the value of 'current heavy flow' and 'new flow'
                    bit<72> tmp_flowID = meta.ha_tuple.flowID;
                    bit<32> tmp_p_vote = meta.ha_tuple.p_vote;

                    heavy_counters_flowID_2.write(meta.ha_heavy, meta.flowID);
                    heavy_counters_p_vote_2.write(meta.ha_heavy, 32w1);
                    heavy_counters_flag_2.write(meta.ha_heavy, 1w1);
                    heavy_counters_total_vote_2.write(meta.ha_heavy, 32w1);

                    // set the 'evicted flow' in meta, for insertion in CMS
                    meta.flowID = tmp_flowID;
                    meta.flow_cnt = tmp_p_vote;

                    // reload counters into meta
                    heavy_part_init_1();
                }


                /**** light part process ****/
                if(is_heavy_processed == 0){
                    cm_sketch2_r1.read(meta.qc_r1, meta.ha_r1);
                    cm_sketch2_r1.write(meta.ha_r1, meta.qc_r1 + meta.flow_cnt);
                }
                
                //cm_sketch2_r1.read(meta.qc_r1, meta.ha_r1);
                //cm_sketch2_r2.read(meta.qc_r2, meta.ha_r2);
                //cm_sketch2_r3.read(meta.qc_r3, meta.ha_r3);


                //min_cnt(meta.cms_freq_estimate, meta.qc_r1, meta.qc_r2, meta.qc_r3);
                //cur_timestamp.write(0, standard_metadata.ingress_global_timestamp);
                //cms_estimate.write(0, meta.cms_freq_estimate);

                //cm_sketch2_r1.write(meta.ha_r1, meta.qc_r1 + meta.flow_cnt);
                //cm_sketch2_r2.write(meta.ha_r2, meta.qc_r2 + meta.flow_cnt);
                //cm_sketch2_r3.write(meta.ha_r3, meta.qc_r3 + meta.flow_cnt);


            }
    }

}
control packetio_ingress(inout headers hdr,
                         inout standard_metadata_t standard_metadata) {
    apply {
        if (standard_metadata.ingress_port == 255) {
            standard_metadata.egress_spec = hdr.packet_out.egress_port;
            hdr.packet_out.setInvalid();
            exit;
        }
    }
}

control packetio_egress(inout headers hdr,
                        inout metadata meta, 
                        inout standard_metadata_t standard_metadata ) {
    apply {
        if (standard_metadata.egress_port == 255) {
            hdr.packet_in.setValid();
            hdr.packet_in.ingress_port = 4;
            hdr.packet_in.direction_id = 5;//meta.direction_id;
            hdr.packet_in.flow_size_1 = meta.flow_size_1;
            hdr.packet_in.flow_size_2 = meta.flow_size_2;
            hdr.packet_in.time_interval = meta.time_interval;
            hdr.packet_in.sign = meta.sign;
        }
    }
}
/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }
    
    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        meta.direction_id = 2;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action send_to_controller(){
        standard_metadata.egress_spec = 255;
        meta.direction_id = 1;
        meta.flow_size_1 = 1200;
        meta.flow_size_2= 1200;
        meta.time_interval = 20000000;
        //clone3(CloneType.I2E, 500, standard_metadata);
    
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            send_to_controller;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }



    apply {
        packetio_ingress.apply(hdr, standard_metadata);

        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
            Measurement.apply(hdr, meta, standard_metadata);

        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    action mark_ecn() {
        hdr.ipv4.ecn = 3;
    }
    apply {
        packetio_egress.apply(hdr, meta, standard_metadata);


    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	      hdr.ipv4.ihl,
	      hdr.ipv4.diffserv,
	      hdr.ipv4.ecn,	
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.packet_in);
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
