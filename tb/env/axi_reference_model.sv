import axi_param_pkg::*;

class refmodel;

    localparam bit [ADDR_WIDTH-1:0] SLAVE0_BASE = 32'h0000_0000;
    localparam bit [ADDR_WIDTH-1:0] SLAVE0_HIGH = 32'h0FFF_FFFF;
    localparam bit [ADDR_WIDTH-1:0] SLAVE1_BASE = 32'h1000_0000;
    localparam bit [ADDR_WIDTH-1:0] SLAVE1_HIGH = 32'h1FFF_FFFF;

    typedef struct packed {
        bit       slave_id;
        bit       decode_err;
        bit [1:0] exp_resp;
    } decode_result_s;

    function decode_result_s decode_addr(bit [ADDR_WIDTH-1:0] addr);
        decode_result_s result;
        result = '0;
        if (addr <= SLAVE0_HIGH)
            result.slave_id = 1'b0;
        else if (SLAVE1_BASE <= addr && addr <= SLAVE1_HIGH)
            result.slave_id = 1'b1;
        else begin
            result.decode_err = 1'b1;
            result.exp_resp   = 2'b11;
        end
        return result;
    endfunction

    function decode_result_s predict_decode(transaction tr);
        bit [ADDR_WIDTH-1:0] addr;
        addr = (tr.axi_op == AXI_WRITE) ? tr.m_awaddr : tr.m_araddr;
        return decode_addr(addr);
    endfunction

    
    typedef struct packed {
        bit master_id;
    } decode_response;

    function decode_response predict_master(bit [TAG_WIDTH-1:0] tagged_id);
        decode_response result;
        result.master_id = tagged_id[TAG_WIDTH-1];
        return result;
    endfunction

    //ARBITRATION
    int last_ar_granted[2];
    int last_aw_granted[2];
    
    function new();
	    last_aw_granted[0] = 1'b1;  // first contention on slave 0 to predict master 0
	    last_aw_granted[1] = 1'b1;   
	    last_ar_granted[0] = 1'b1;  // first contention on slave 0 to predict master 0
	    last_ar_granted[1] = 1'b1;     

    endfunction
    function int predict_write_winner(int slave_id, bit m0_req, bit m1_req);
        if (m0_req && !m1_req) return 0;
        if (!m0_req && m1_req) return 1;
        if (m0_req && m1_req)
            return (last_aw_granted[slave_id] == 0) ? 1 : 0;
        return -1; // neither requesting
    endfunction

    function void update_w_arb_state(int slave_id, int observed_winner);
        last_aw_granted[slave_id] = observed_winner;
    endfunction
   
    function int predict_read_winner(int slave_id, bit m0_req, bit m1_req);
        if (m0_req && !m1_req) return 0;
        if (!m0_req && m1_req) return 1;
        if (m0_req && m1_req)
            return (last_ar_granted[slave_id] == 0) ? 1 : 0;
        return -1; // neither requesting
    endfunction

    function void update_r_arb_state(int slave_id, int observed_winner);
        last_ar_granted[slave_id] = observed_winner;
    endfunction

endclass
