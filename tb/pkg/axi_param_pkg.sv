package axi_param_pkg;

    typedef enum bit {AXI_WRITE,
        AXI_READ} axi_opt;

    parameter int ADDR_WIDTH = 32;
    parameter int DATA_WIDTH = 64;
    parameter int ID_WIDTH   = 4;
    parameter int TAG_WIDTH  = ID_WIDTH + 1;
    parameter int LEN_WIDTH  = 8;
    parameter int SIZE_WIDTH = 3;
    parameter int BURST_TYPE = 2;
    parameter logic [ADDR_WIDTH-1:0] SLAVE0_ADDR_FIRST = 32'h0000_0000;
    parameter logic [ADDR_WIDTH-1:0] SLAVE0_ADDR_LAST  = 32'h0FFF_FFFF;

    parameter logic [ADDR_WIDTH-1:0] SLAVE1_ADDR_FIRST = 32'h1000_0000;
    parameter logic [ADDR_WIDTH-1:0] SLAVE1_ADDR_LAST  = 32'h1FFF_FFFF;

    typedef struct packed { 
	    bit axi_op;
	    bit slave_id;
	    bit m0_requesting;
	    bit m1_requesting;
	    bit observed_winner;
	    } arb_event_s;
 
    function automatic bit [31:0] calc_beat_addr(
      bit [31:0] prev_addr,
      bit [1:0]  burst,
      bit [2:0]  size,
      bit [7:0]  len
  );
      int number_bytes;
      int wrap_size;
      bit [31:0] wrap_lo, wrap_hi, next_addr;

      number_bytes = 1 << size;

      case (burst)
          2'b00: calc_beat_addr = prev_addr;
          2'b01: calc_beat_addr = prev_addr + number_bytes;
          2'b10: begin
              wrap_size = number_bytes * (len + 1);
              wrap_lo   = (prev_addr / wrap_size) * wrap_size;
              wrap_hi   = wrap_lo + wrap_size;
              next_addr = prev_addr + number_bytes;
              calc_beat_addr = (next_addr >= wrap_hi) ? wrap_lo : next_addr;
          end
          default: calc_beat_addr = prev_addr;
      endcase
  endfunction
  function automatic bit [31:0] calc_last_incr_addr(
    bit [31:0] awaddr,
    bit [2:0]  awsize,
    bit [7:0]  awlen
);
    calc_last_incr_addr = awaddr + (awlen * (1 << awsize));
endfunction
endpackage
