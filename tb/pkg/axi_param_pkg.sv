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
endpackage
