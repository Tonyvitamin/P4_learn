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

    /* Sketch 1: CM Sketch */

    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch1_r1;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch1_r2;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch1_r3;


    /* Sketch 2: CM Sketch */

    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch2_r1;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch2_r2;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch2_r3;

    /* Sketch 3: CM Sketch */

    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch3_r1;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch3_r2;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch3_r3;


    /* Sketch 4: CM Sketch */

    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch4_r1;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch4_r2;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch4_r3;

    /* Sketch 5: CM Sketch */

    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch5_r1;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch5_r2;
    register<bit<32> >(FLOW_TABLE_SIZE_EACH) cm_sketch5_r3;

    /* Queried Mask(bloom filter) */
    // In case that queried flow keep forwarding packet to controller to remind controller this flow change
    register<bit<2> > (FLOW_TABLE_SIZE_EACH) mask_queried_1;
    register<bit<2> > (FLOW_TABLE_SIZE_EACH) mask_queried_2;
    register<bit<2> > (FLOW_TABLE_SIZE_EACH) mask_queried_3;
    register<bit<2> > (FLOW_TABLE_SIZE_EACH) mask_queried_4;
    register<bit<2> > (FLOW_TABLE_SIZE_EACH) mask_queried_5;


    register<bit<48> > (1) last_timestamp;
    register<bit<48> > (1) cur_timestamp;
    register<bit<8> > (1) time_flag;
    register<bit<2> >(1) query_flag;
    register<bit<2> >(1) start_flag;


    action min_cnt(inout bit<32> mincnt, in bit<32> cnt1, in bit<32> cnt2, in bit<32> cnt3){
        if(cnt1 < cnt2){
            mincnt = cnt1;
        }
        else {
            mincnt = cnt2;
        }

        if(mincnt>cnt3){
            mincnt = cnt3;
        }
    }
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
            hash(meta.ha_r2, HashAlgorithm.crc16, HASH_BASE, {meta.flowID, HASH_SEED_r2}, HASH_MAX);
            hash(meta.ha_r3, HashAlgorithm.crc16, HASH_BASE, {meta.flowID, HASH_SEED_r3}, HASH_MAX);

            bit<48>  t_diff;
            bit<48>  ct;
            bit<48>  lt;
            bit<8>   flag;
            bit<2>   q_flag;
            bit<2>   s_flag;
            //cur_timestamp.read(ct, 0);


            time_flag.read(flag, 0);
            query_flag.read(q_flag, 0);
            start_flag.read(s_flag, 0);


            // Start detection
            if(s_flag==0){
                time_flag.write(0, 0);
                flag=0;
                start_flag.write(0, 1);
                last_timestamp.write(0, standard_metadata.ingress_global_timestamp);
                query_flag.write(0, 1);
            }
            ct = standard_metadata.ingress_global_timestamp;

            cur_timestamp.write(0, standard_metadata.ingress_global_timestamp);
            last_timestamp.read(lt, 0);
            t_diff = ct - lt;

            // Circular 4 phase process & query 

            // Phase 1
            // 1. Process packet & store packet counter into sketch 1 (CM sketch)
            // 2. Reset Sketch 3 to 0
            // 3. Reset Queried Mask 3
            // 4. Query Sketch 5 & Sketch 4 ( S5[i] - S4[i] ), for any flow "i"
            // 5. Transition to Phase 2
            //else{
                if(flag==0){


                    // Process packet in S1
                    cm_sketch1_r1.read(meta.qc_r1, meta.ha_r1);
                    cm_sketch1_r2.read(meta.qc_r2, meta.ha_r2);
                    cm_sketch1_r3.read(meta.qc_r3, meta.ha_r3);

                    cm_sketch1_r1.write(meta.ha_r1, meta.qc_r1+meta.flow_cnt);
                    cm_sketch1_r2.write(meta.ha_r2, meta.qc_r2+meta.flow_cnt);
                    cm_sketch1_r3.write(meta.ha_r3, meta.qc_r3+meta.flow_cnt);

                    // Reset Sketch 3 to 0
                    cm_sketch3_r1.write(meta.ha_r1, 0);
                    cm_sketch3_r2.write(meta.ha_r2, 0);
                    cm_sketch3_r3.write(meta.ha_r3, 0);

                    // Reset Queried Mask 3 to 0
                    mask_queried_3.write(meta.ha_r1, 0);
                    mask_queried_3.write(meta.ha_r2, 0);
                    mask_queried_3.write(meta.ha_r3, 0);

                    // Query S5-S4 if necessary
                    //if(q_flag==1){
                        bit<2> index_1;
                        bit<2> index_2;
                        bit<2> index_3;

                        mask_queried_1.read(index_1, meta.ha_r1);
                        mask_queried_1.read(index_2, meta.ha_r2);
                        mask_queried_1.read(index_3, meta.ha_r3);

                        // Never Queried before
                        if(index_1!=1 ||  index_2!=1 || index_3!=1){

                            bit<32> old_1;
                            bit<32> old_2;
                            bit<32> old_3;
                            bit<32> old_est;

                            bit<32> new_1;
                            bit<32> new_2;
                            bit<32> new_3;
                            bit<32> new_est;

                            cm_sketch4_r1.read(old_1, meta.ha_r1);
                            cm_sketch4_r2.read(old_2, meta.ha_r2);
                            cm_sketch4_r3.read(old_3, meta.ha_r3);
                            min_cnt(old_est, old_1, old_2, old_3);

                            cm_sketch5_r1.read(new_1, meta.ha_r1);
                            cm_sketch5_r2.read(new_2, meta.ha_r2);
                            cm_sketch5_r3.read(new_3, meta.ha_r3);
                            min_cnt(new_est, new_1, new_2, new_3);

                            if(new_est > old_est + 50){
                                mask_queried_1.write(meta.ha_r1, 1);
                                mask_queried_1.write(meta.ha_r2, 1);
                                mask_queried_1.write(meta.ha_r3, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 0;
                                meta.time_interval = ct;
                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                            if(old_est > new_est + 50){
                                mask_queried_1.write(meta.ha_r1, 1);
                                mask_queried_1.write(meta.ha_r2, 1);
                                mask_queried_1.write(meta.ha_r3, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 1;
                                meta.time_interval = ct;
                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                        }


                    //}
                    // transition to phase 2
                    if(t_diff>5000000){
                        time_flag.write(0, 1);
                        last_timestamp.write(0, standard_metadata.ingress_global_timestamp);

                    }

                }

                // Phase 2
                // 1. Process packet & store packet counter into sketch 2 (CM sketch)
                // 2. Reset Sketch 4 to 0
                // 3. Reset Queried Mask 4 to 0
                // 4. Query Sketch 1 & Sketch 5 ( S1[i] - S4[i] ), for any flow "i"
                // 5. Transition to Phase 3

                else if (flag==1){


                    // Process packet in S2
                    cm_sketch2_r1.read(meta.qc_r1, meta.ha_r1);
                    cm_sketch2_r2.read(meta.qc_r2, meta.ha_r2);
                    cm_sketch2_r3.read(meta.qc_r3, meta.ha_r3);

                    cm_sketch2_r1.write(meta.ha_r1, meta.qc_r1+meta.flow_cnt);
                    cm_sketch2_r2.write(meta.ha_r2, meta.qc_r2+meta.flow_cnt);
                    cm_sketch2_r3.write(meta.ha_r3, meta.qc_r3+meta.flow_cnt);

                    // Reset Sketch 4 to 0
                    cm_sketch4_r1.write(meta.ha_r1, 0);
                    cm_sketch4_r2.write(meta.ha_r2, 0);
                    cm_sketch4_r3.write(meta.ha_r3, 0);

                    // Reset Queried Mask 4 to 0
                    mask_queried_4.write(meta.ha_r1, 0);
                    mask_queried_4.write(meta.ha_r2, 0);
                    mask_queried_4.write(meta.ha_r3, 0);


                    // Query S1-S5 if necessary
                    //if(q_flag==1){
                        bit<2> index_1;
                        bit<2> index_2;
                        bit<2> index_3;

                        mask_queried_2.read(index_1, meta.ha_r1);
                        mask_queried_2.read(index_2, meta.ha_r2);
                        mask_queried_2.read(index_3, meta.ha_r3);

                        // Never Queried before
                        if(index_1!=1 ||  index_2!=1 || index_3!=1){

                            bit<32> old_1;
                            bit<32> old_2;
                            bit<32> old_3;
                            bit<32> old_est;

                            bit<32> new_1;
                            bit<32> new_2;
                            bit<32> new_3;
                            bit<32> new_est;

                            cm_sketch5_r1.read(old_1, meta.ha_r1);
                            cm_sketch5_r2.read(old_2, meta.ha_r2);
                            cm_sketch5_r3.read(old_3, meta.ha_r3);
                            min_cnt(old_est, old_1, old_2, old_3);

                            cm_sketch1_r1.read(new_1, meta.ha_r1);
                            cm_sketch1_r2.read(new_2, meta.ha_r2);
                            cm_sketch1_r3.read(new_3, meta.ha_r3);
                            min_cnt(new_est, new_1, new_2, new_3);

                            if(new_est > old_est + 50){
                                mask_queried_2.write(meta.ha_r1, 1);
                                mask_queried_2.write(meta.ha_r2, 1);
                                mask_queried_2.write(meta.ha_r3, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 0;
                                meta.time_interval = ct;
                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                            if(old_est > new_est + 50){
                                mask_queried_2.write(meta.ha_r1, 1);
                                mask_queried_2.write(meta.ha_r2, 1);
                                mask_queried_2.write(meta.ha_r3, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 1;
                                meta.time_interval = ct;
                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                        }
                    //}

                    // transition to phase 3
                    if(t_diff>5000000){
                        time_flag.write(0, 2);
                        last_timestamp.write(0, standard_metadata.ingress_global_timestamp);
                    }                


                }

                // Phase 3
                // 1. Process packet & store packet counter into sketch 3 (CM sketch)
                // 2. Reset Sketch 5 to 0
                // 3. Reset Queried Mask 5 to 0
                // 4. Query Sketch 2 & Sketch 1 ( S2[i] - S1[i] ), for any flow "i"
                // 5. Transition to Phase 4
                else if(flag==2){

                    // Process packet in S3
                    cm_sketch3_r1.read(meta.qc_r1, meta.ha_r1);
                    cm_sketch3_r2.read(meta.qc_r2, meta.ha_r2);
                    cm_sketch3_r3.read(meta.qc_r3, meta.ha_r3);

                    cm_sketch3_r1.write(meta.ha_r1, meta.qc_r1+meta.flow_cnt);
                    cm_sketch3_r2.write(meta.ha_r2, meta.qc_r2+meta.flow_cnt);
                    cm_sketch3_r3.write(meta.ha_r3, meta.qc_r3+meta.flow_cnt);                

                    // Reset Sketch 5 to 0
                    cm_sketch5_r1.write(meta.ha_r1, 0);
                    cm_sketch5_r2.write(meta.ha_r2, 0);
                    cm_sketch5_r3.write(meta.ha_r3, 0);

                    // Reset Queried Mask 5 to 0
                    mask_queried_5.write(meta.ha_r1, 0);
                    mask_queried_5.write(meta.ha_r2, 0);
                    mask_queried_5.write(meta.ha_r3, 0);


                    // Query S2-S1 if necessary
                    //if(q_flag==1){
                        bit<2> index_1;
                        bit<2> index_2;
                        bit<2> index_3;

                        mask_queried_3.read(index_1, meta.ha_r1);
                        mask_queried_3.read(index_2, meta.ha_r2);
                        mask_queried_3.read(index_3, meta.ha_r3);

                        // Never Queried before
                        if(index_1!=1 ||  index_2!=1 || index_3!=1){

                            bit<32> old_1;
                            bit<32> old_2;
                            bit<32> old_3;
                            bit<32> old_est;

                            bit<32> new_1;
                            bit<32> new_2;
                            bit<32> new_3;
                            bit<32> new_est;

                            cm_sketch1_r1.read(old_1, meta.ha_r1);
                            cm_sketch1_r2.read(old_2, meta.ha_r2);
                            cm_sketch1_r3.read(old_3, meta.ha_r3);
                            min_cnt(old_est, old_1, old_2, old_3);

                            cm_sketch2_r1.read(new_1, meta.ha_r1);
                            cm_sketch2_r2.read(new_2, meta.ha_r2);
                            cm_sketch2_r3.read(new_3, meta.ha_r3);
                            min_cnt(new_est, new_1, new_2, new_3);

                            if(new_est > old_est + 50){
                                mask_queried_3.write(meta.ha_r1, 1);
                                mask_queried_3.write(meta.ha_r2, 1);
                                mask_queried_3.write(meta.ha_r3, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 0;
                                meta.time_interval = ct;
                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                            if(old_est > new_est + 50){
                                mask_queried_3.write(meta.ha_r1, 1);
                                mask_queried_3.write(meta.ha_r2, 1);
                                mask_queried_3.write(meta.ha_r3, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 1;
                                meta.time_interval = ct;
                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                        }
                    //}
                    // transition to phase 4
                    if(t_diff>5000000){
                        time_flag.write(0, 3);
                        last_timestamp.write(0, standard_metadata.ingress_global_timestamp);

                    }
                }

                // Phase 4
                // 1. Process packet & store packet counter into sketch 4 (CM sketch)
                // 2. Reset Sketch 1 to 0
                // 3. Reset Queried Mask 1 to 0 
                // 3. Query Sketch 3 & Sketch 2 ( S3[i] - S2[i] ), for any flow "i"
                // 4. Transition to Phase 1            
                else if(flag==3){

                    // Process packet in S4
                    cm_sketch4_r1.read(meta.qc_r1, meta.ha_r1);
                    cm_sketch4_r2.read(meta.qc_r2, meta.ha_r2);
                    cm_sketch4_r3.read(meta.qc_r3, meta.ha_r3);

                    cm_sketch4_r1.write(meta.ha_r1, meta.qc_r1+meta.flow_cnt);
                    cm_sketch4_r2.write(meta.ha_r2, meta.qc_r2+meta.flow_cnt);
                    cm_sketch4_r3.write(meta.ha_r3, meta.qc_r3+meta.flow_cnt);
   
                    // Reset Sketch 1 to 0
                    cm_sketch1_r1.write(meta.ha_r1, 0);
                    cm_sketch1_r2.write(meta.ha_r2, 0);
                    cm_sketch1_r3.write(meta.ha_r3, 0);


                    // Reset Queried Mask 1 to 0
                    mask_queried_1.write(meta.ha_r1, 0);
                    mask_queried_1.write(meta.ha_r2, 0);
                    mask_queried_1.write(meta.ha_r3, 0);


                    // Query S3-S2 if necessary
                    //if(q_flag==1){
                        bit<2> index_1;
                        bit<2> index_2;
                        bit<2> index_3;

                        mask_queried_4.read(index_1, meta.ha_r1);
                        mask_queried_4.read(index_2, meta.ha_r2);
                        mask_queried_4.read(index_3, meta.ha_r3);

                        // Never Queried before
                        if(index_1!=1 ||  index_2!=1 || index_3!=1){

                            bit<32> old_1;
                            bit<32> old_2;
                            bit<32> old_3;
                            bit<32> old_est;

                            bit<32> new_1;
                            bit<32> new_2;
                            bit<32> new_3;
                            bit<32> new_est;

                            cm_sketch2_r1.read(old_1, meta.ha_r1);
                            cm_sketch2_r2.read(old_2, meta.ha_r2);
                            cm_sketch2_r3.read(old_3, meta.ha_r3);
                            min_cnt(old_est, old_1, old_2, old_3);

                            cm_sketch3_r1.read(new_1, meta.ha_r1);
                            cm_sketch3_r2.read(new_2, meta.ha_r2);
                            cm_sketch3_r3.read(new_3, meta.ha_r3);
                            min_cnt(new_est, new_1, new_2, new_3);

                            if(new_est > old_est + 50){
                                mask_queried_4.write(meta.ha_r1, 1);
                                mask_queried_4.write(meta.ha_r2, 1);
                                mask_queried_4.write(meta.ha_r3, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 0;
                                meta.time_interval = ct;
                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                            if(old_est > new_est + 50){
                                mask_queried_4.write(meta.ha_r1, 1);
                                mask_queried_4.write(meta.ha_r2, 1);
                                mask_queried_4.write(meta.ha_r3, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 1;
                                meta.time_interval = ct;
                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                        }
                    //}
                    // transition to phase 1
                    if(t_diff>5000000){
                        time_flag.write(0, 4);
                        last_timestamp.write(0, standard_metadata.ingress_global_timestamp);

                    }
                }

                // Phase 5
                // 1. Process packet & store packet counter into sketch 5 (CM sketch)
                // 2. Reset Sketch 2 to 0
                // 3. Reset Queried Mask 2 to 0
                // 3. Query Sketch 4 & Sketch 3 ( S4[i] - S3[i] ), for any flow "i"
                // 4. Transition to Phase 1            
                else if(flag==4){

                    // Process packet in S4
                    cm_sketch5_r1.read(meta.qc_r1, meta.ha_r1);
                    cm_sketch5_r2.read(meta.qc_r2, meta.ha_r2);
                    cm_sketch5_r3.read(meta.qc_r3, meta.ha_r3);

                    cm_sketch5_r1.write(meta.ha_r1, meta.qc_r1+meta.flow_cnt);
                    cm_sketch5_r2.write(meta.ha_r2, meta.qc_r2+meta.flow_cnt);
                    cm_sketch5_r3.write(meta.ha_r3, meta.qc_r3+meta.flow_cnt);
   
                    // Reset Sketch 2 to 0
                    cm_sketch2_r1.write(meta.ha_r1, 0);
                    cm_sketch2_r2.write(meta.ha_r2, 0);
                    cm_sketch2_r3.write(meta.ha_r3, 0);


                    // Reset Queried Mask 2 to 0
                    mask_queried_2.write(meta.ha_r1, 0);
                    mask_queried_2.write(meta.ha_r2, 0);
                    mask_queried_2.write(meta.ha_r3, 0);


                    // Query S4-S3 if necessary
                    //if(q_flag==1){
                        bit<2> index_1;
                        bit<2> index_2;
                        bit<2> index_3;

                        mask_queried_5.read(index_1, meta.ha_r1);
                        mask_queried_5.read(index_2, meta.ha_r2);
                        mask_queried_5.read(index_3, meta.ha_r3);

                        // Never Queried before
                        if(index_1!=1 ||  index_2!=1 || index_3!=1){

                            bit<32> old_1;
                            bit<32> old_2;
                            bit<32> old_3;
                            bit<32> old_est;

                            bit<32> new_1;
                            bit<32> new_2;
                            bit<32> new_3;
                            bit<32> new_est;

                            cm_sketch3_r1.read(old_1, meta.ha_r1);
                            cm_sketch3_r2.read(old_2, meta.ha_r2);
                            cm_sketch3_r3.read(old_3, meta.ha_r3);
                            min_cnt(old_est, old_1, old_2, old_3);

                            cm_sketch4_r1.read(new_1, meta.ha_r1);
                            cm_sketch4_r2.read(new_2, meta.ha_r2);
                            cm_sketch4_r3.read(new_3, meta.ha_r3);
                            min_cnt(new_est, new_1, new_2, new_3);

                            if(new_est > old_est + 50){
                                mask_queried_5.write(meta.ha_r1, 1);
                                mask_queried_5.write(meta.ha_r2, 1);
                                mask_queried_5.write(meta.ha_r3, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 0;
                                meta.time_interval = ct;
                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                            if(old_est > new_est + 50){
                                mask_queried_5.write(meta.ha_r1, 1);
                                mask_queried_5.write(meta.ha_r2, 1);
                                mask_queried_5.write(meta.ha_r3, 1);
                                standard_metadata.egress_spec = 255;
                                meta.sign = 1;
                                meta.time_interval = ct;
                                meta.flow_size_1 = old_est;
                                meta.flow_size_2 = new_est;
                            }

                        }
                    //}
                    // transition to phase 1
                    if(t_diff>5000000){
                        time_flag.write(0, 0);
                        last_timestamp.write(0, standard_metadata.ingress_global_timestamp);

                    }
                }
            //}
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
