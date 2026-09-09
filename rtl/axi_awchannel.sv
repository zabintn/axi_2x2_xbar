`timescale 1ns/1ps

module axi_xbar_aw #(    parameter ADDR_WIDTH  = 32,
    parameter ID_WIDTH = 4,
    parameter NUM_M = 2,
    parameter NUM_S = 2,
    parameter MASTER_ID =0,
    parameter TAG_WIDTH = ID_WIDTH + 1,
    parameter LEN_WIDTH=8,
    parameter SIZE_WIDTH=3,
    parameter BURST_TYPE=2
    )(


	   input wire aclk,
	   input wire arst_n,
	    //AW channel
	   input wire [ADDR_WIDTH-1:0]  m0_awaddr,
	   input wire [ID_WIDTH-1:0]    m0_awid,
	   input wire [LEN_WIDTH-1:0]   m0_awlen,
	   input wire [SIZE_WIDTH-1:0]  m0_awsize,
	   input wire [BURST_TYPE-1:0] m0_awburst,
	   input wire  m0_awvalid,
	   
	   input wire [ADDR_WIDTH-1:0]  m1_awaddr,
	   input wire [ID_WIDTH-1:0]    m1_awid,
	   input wire [LEN_WIDTH-1:0]   m1_awlen,
	   input wire [SIZE_WIDTH-1:0]  m1_awsize,
	   input wire [BURST_TYPE-1:0] m1_awburst,
	   input wire m1_awvalid,	   
	   
	   output wire  m0_fifo_ready,
	   output wire  m1_fifo_ready,

	    
	   input wire s1_awready,
	   input wire s0_awready,  
	    
	   output wire [ADDR_WIDTH-1:0]  s0_awaddr,
	   output wire [ID_WIDTH-1:0]    s0_awid,
	   output wire [LEN_WIDTH-1:0]   s0_awlen,
	   output wire [SIZE_WIDTH-1:0]  s0_awsize,
	   output wire [BURST_TYPE-1:0] s0_awburst,
       	   output wire [ADDR_WIDTH-1:0]  s1_awaddr,
	   output wire [ID_WIDTH-1:0]    s1_awid,
	   output wire [LEN_WIDTH-1:0]   s1_awlen,
	   output wire [SIZE_WIDTH-1:0]  s1_awsize,
	   output wire [BURST_TYPE-1:0] s1_awburst,
	    
	   output wire [1:0] m0_slave_sel,
	   output wire m0_decode_error,
	   output wire [1:0] m1_slave_sel,
	   output wire m1_decode_error,
	   

	   input wire s0_wlast_done,
	   input wire s1_wlast_done,
	   output wire [NUM_M-1:0] s0_req, 
	   output wire [NUM_M-1:0] s1_req
);

	
		
	wire [NUM_M-1:0] s0_grant;
	wire [NUM_M-1:0] s1_grant;
	
	
		//address decode slave_sel


		addr_decoder #(.ADDR_WIDTH(ADDR_WIDTH)) m0_address_decoder ( .address(m0_awaddr), .slave_sel(m0_slave_sel), .error(m0_decode_error));


		//m0 to TO m0 FIFO
		
		wire m0_fifo_empty, m0_fifo_full;
		wire m0_fifo_push, m0_fifo_pop;
		
		wire [ID_WIDTH-1:0]    m0_fifo_awid;
		wire [ADDR_WIDTH-1:0]  m0_fifo_awaddr;
		wire [LEN_WIDTH-1:0]   m0_fifo_awlen;
		wire [SIZE_WIDTH-1:0]  m0_fifo_awsize;
		wire [BURST_TYPE-1:0]  m0_fifo_awburst;
		
		localparam FIFO_WORD_WIDTH= ID_WIDTH + ADDR_WIDTH + LEN_WIDTH + SIZE_WIDTH + BURST_TYPE;
		wire [FIFO_WORD_WIDTH-1:0] fifo_awdata_in = {m0_awid, m0_awaddr, m0_awlen, m0_awsize, m0_awburst}; 
		wire [FIFO_WORD_WIDTH-1:0] fifo_awdata_out;
		
		assign m0_fifo_ready = !m0_fifo_full;
		wire m0_req_s0 = !m0_fifo_empty && (m0_slave_sel == 2'b00);
		wire m1_req_s0 = !m1_fifo_empty && (m1_slave_sel == 2'b00);
		assign s0_req = {1'b0, m0_req_s0}; //HARDCODED, CHANGE THIS LATER
		
		assign m0_fifo_push = m0_awvalid && m0_fifo_ready; //handshake	
		assign m0_fifo_pop = !m0_fifo_empty && ( (s0_grant[0] && s0_awready));


		sync_fifo #(.DEPTH(8),
			.DATA_WIDTH(FIFO_WORD_WIDTH)
			) u_aw_fifo( .clk(aclk), .rstn(arst_n), .wr_en(m0_fifo_push), .rd_en(m0_fifo_pop), .wdata(fifo_awdata_in), .rdata(fifo_awdata_out), .full(m0_fifo_full), .empty(m0_fifo_empty) );

                assign m0_fifo_awburst = fifo_awdata_out[BURST_TYPE-1:0];
		assign m0_fifo_awsize = fifo_awdata_out[BURST_TYPE + SIZE_WIDTH - 1:BURST_TYPE];
		assign m0_fifo_awlen = fifo_awdata_out[BURST_TYPE + SIZE_WIDTH + LEN_WIDTH - 1:BURST_TYPE + SIZE_WIDTH];
		assign m0_fifo_awaddr = fifo_awdata_out[BURST_TYPE + SIZE_WIDTH + LEN_WIDTH + ADDR_WIDTH - 1: BURST_TYPE + SIZE_WIDTH + LEN_WIDTH];
		assign m0_fifo_awid = fifo_awdata_out[FIFO_WORD_WIDTH-1: BURST_TYPE + SIZE_WIDTH + LEN_WIDTH + ADDR_WIDTH];		

	//ARBITER INSTANTIATION
	
	wire s0_accept;
	assign s0_accept = s0_grant[0] && s0_awready;	

	rr_arbiter #( .NUM_REQ(NUM_M)) u_rr_arbiter_s0 (.clk(aclk), .resetn(arst_n), .req(s0_req), .done(s0_wlast_done),  .accept(s0_accept),.grant(s0_grant));

	//DRIVE GRANTED MASTER DATA TO SLAVE
	//
	assign s0_awaddr = m0_fifo_awaddr;
	assign s0_awid = m0_fifo_awid;
	assign s0_awlen = m0_fifo_awlen;
	assign s0_awsize = m0_fifo_awsize;
	assign s0_awburst = m0_fifo_awburst;



endmodule



