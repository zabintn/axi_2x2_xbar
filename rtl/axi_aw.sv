`timescale 1ns/1ps

module axi_xbar_aw #(    parameter ADDR_WIDTH  = 32,
	parameter DATA_WIDTH=64,
    parameter ID_WIDTH = 4,
    parameter MASTER_ID =0,
    parameter TAG_WIDTH = ID_WIDTH + 1,
    parameter LEN_WIDTH=8,
    parameter SIZE_WIDTH=3,
    parameter BURST_TYPE=2
    )(

	    input wire aclk,
	    input wire arst_n,

	   input wire [ADDR_WIDTH-1:0]  m0_awaddr,
	   input wire [ID_WIDTH-1:0]    m0_awid,
	   input wire [LEN_WIDTH-1:0]   m0_awlen,
	   input wire [SIZE_WIDTH-1:0]  m0_awsize,
	   input wire [BURST_TYPE-1:0] m0_awburst,
	   input wire  m0_awvalid,
	   output wire m0_awready,
	   output wire [1:0] m0_slave_sel,

	   input wire [ADDR_WIDTH-1:0]  m1_awaddr,
	   input wire [ID_WIDTH-1:0]    m1_awid,
	   input wire [LEN_WIDTH-1:0]   m1_awlen,
	   input wire [SIZE_WIDTH-1:0]  m1_awsize,
	   input wire [BURST_TYPE-1:0] m1_awburst,
	   input wire  m1_awvalid,
	   output wire m1_awready,
	   output wire [1:0] m1_slave_sel,

	   output wire [ADDR_WIDTH-1:0] s0_awaddr,
	   output wire [TAG_WIDTH-1:0] s0_awid,
	   output wire [LEN_WIDTH-1:0] s0_awlen,
	   output wire [SIZE_WIDTH-1:0] s0_awsize,
	   output wire [BURST_TYPE-1:0] s0_awburst,
	   input wire s0_awready,
	   output wire s0_awvalid,

	   input wire s0_wlast,
	   input wire s1_wlast,
	 
	   output wire [ADDR_WIDTH-1:0] s1_awaddr,
	   output wire [TAG_WIDTH-1:0] s1_awid,
	   output wire [LEN_WIDTH-1:0] s1_awlen,
	   output wire [SIZE_WIDTH-1:0] s1_awsize,
	   output wire [BURST_TYPE-1:0] s1_awburst,
	   input wire s1_awready,
	   output wire s1_awvalid,

	   output wire s0_locked,
	   output wire s0_owner,
	   output wire s1_locked,
	   output wire s1_owner,
	   
	   
	   output logic m0_decode_error,
	   output logic m1_decode_error,
	   
	   output wire m0_fifo_pop,
	   output wire m1_fifo_pop,
	   output wire m0_decode_error_saved,
	   output wire m1_decode_error_saved,
	   output wire [LEN_WIDTH-1:0] m0_fifo_awlen,
	   output wire [LEN_WIDTH-1:0] m1_fifo_awlen,

	   input s0_wvalid,
	   input s1_wvalid,
	   input s0_wready,
	   input s1_wready
	  
	   );


	  //FIFO PUSH
	   //
	   wire m0_fifo_empty, m0_fifo_full;
	   wire m0_fifo_push;
	   wire m1_fifo_empty, m1_fifo_full;
	   wire m1_fifo_push;


	   localparam FIFO_WORD_WIDTH= ID_WIDTH + ADDR_WIDTH + LEN_WIDTH + SIZE_WIDTH + BURST_TYPE;
	   wire [FIFO_WORD_WIDTH-1:0] m0_fifo_awdata_in = {m0_awid, m0_awaddr, m0_awlen, m0_awsize, m0_awburst};
	   wire [FIFO_WORD_WIDTH-1:0] m1_fifo_awdata_in = {m1_awid, m1_awaddr, m1_awlen, m1_awsize, m1_awburst};

	   wire [FIFO_WORD_WIDTH-1:0] m0_fifo_awdata_out;
	   wire [FIFO_WORD_WIDTH-1:0] m1_fifo_awdata_out;

	   wire [BURST_TYPE-1:0] m0_fifo_awburst;
	   wire [BURST_TYPE-1:0] m1_fifo_awburst;
	   
	   wire [SIZE_WIDTH-1:0] m0_fifo_awsize;
	   wire [SIZE_WIDTH-1:0] m1_fifo_awsize;
	   
	   
	   wire [ADDR_WIDTH-1:0] m0_fifo_awaddr;
	   wire [ADDR_WIDTH-1:0] m1_fifo_awaddr;
	   
	   wire [ID_WIDTH-1:0] m0_fifo_awid;
	   wire [ID_WIDTH-1:0] m1_fifo_awid;

	   assign m0_awready= !m0_fifo_full;
	   assign m1_awready= !m1_fifo_full;

	   assign m0_fifo_push= m0_awvalid && m0_awready;  //fifo handshake
	   assign m1_fifo_push= m1_awvalid && m1_awready;  //fifo handshake

	   
	   //master 0 FIFO instantiation
	   
	   sync_fifo #(.DEPTH(8),
			.DATA_WIDTH(FIFO_WORD_WIDTH)
			) m0_aw_fifo( .clk(aclk), .rstn(arst_n), .wr_en(m0_fifo_push), .rd_en(m0_fifo_pop), .wdata(m0_fifo_awdata_in), .rdata(m0_fifo_awdata_out), .full(m0_fifo_full), .empty(m0_fifo_empty) );
			
	   //master 1 FIFO instantiation
	   
	   sync_fifo #(.DEPTH(8),
		.DATA_WIDTH(FIFO_WORD_WIDTH)
			) m1_aw_fifo( .clk(aclk), .rstn(arst_n), .wr_en(m1_fifo_push), .rd_en(m1_fifo_pop), .wdata(m1_fifo_awdata_in), .rdata(m1_fifo_awdata_out), .full(m1_fifo_full), .empty(m1_fifo_empty) );
	 
	  //decode address 

	   addr_decoder #(.ADDR_WIDTH(ADDR_WIDTH)) m0_address_decoder ( .address(m0_fifo_awaddr), .slave_sel(m0_slave_sel), .error(m0_decode_error_saved));

	   addr_decoder #(.ADDR_WIDTH(ADDR_WIDTH)) m1_address_decoder ( .address(m1_fifo_awaddr), .slave_sel(m1_slave_sel), .error(m1_decode_error_saved));
	   
	   assign m0_decode_error = !m0_fifo_empty && m0_decode_error_saved;
	   assign m1_decode_error = !m1_fifo_empty && m1_decode_error_saved;

	   
	  	       
	//arbiter
	  
	  wire s0_accept;
	  wire s1_accept;
	  
	  wire [1:0] s0_grant;
	  wire [1:0] s1_grant;

	  wire [1:0] s0_req;
	  wire [1:0] s1_req;

	  wire m0_s0_req, m1_s0_req, m0_s1_req, m1_s1_req;

	  assign s0_accept = (|s0_grant && s0_awready);
	  assign s1_accept = (|s1_grant && s1_awready);

	  wire s0_w_done = s0_wvalid && s0_wready && s0_wlast;
	  wire s1_w_done = s1_wvalid && s1_wready && s1_wlast;
	  
	  assign m0_s0_req = !m0_fifo_empty && !m0_decode_error_saved && (m0_slave_sel == 2'b00) && !(s1_locked && s1_owner==1'b0);
	  assign m1_s0_req = !m1_fifo_empty && !m1_decode_error_saved && (m1_slave_sel == 2'b00) && !(s1_locked && s1_owner==1'b1);
	  
	  assign m0_s1_req = !m0_fifo_empty && !m0_decode_error_saved && (m0_slave_sel == 2'b01) && !(s0_locked && s0_owner==1'b0);
	  assign m1_s1_req = !m1_fifo_empty && !m1_decode_error_saved && (m1_slave_sel == 2'b01) && !(s0_locked && s0_owner==1'b1);
	  assign s0_req= {m1_s0_req, m0_s0_req};

	  //assign m0_s1_req = !m0_fifo_empty && !m0_decode_error_saved && (m0_slave_sel == 2'b01);
	  //assign m1_s1_req = !m1_fifo_empty && !m1_decode_error_saved && (m1_slave_sel == 2'b01);
	  assign s1_req= {m1_s1_req, m0_s1_req};

		  rr_arbiter #(.NUM_REQ(2)) slave_0_arbiter (.clk(aclk), .resetn(arst_n), .req(s0_req), .done(s0_w_done), .grant(s0_grant), .accept(s0_accept), .locked(s0_locked), .owner(s0_owner));

		  rr_arbiter #(.NUM_REQ(2)) slave_1_arbiter (.clk(aclk), .resetn(arst_n), .req(s1_req), .done(s1_w_done), .grant(s1_grant), .accept(s1_accept), .locked(s1_locked), .owner(s1_owner));
		 
		 
		  //fifo will pop when grant is high or in case of decode errors
		  
		  assign m0_fifo_pop = !m0_fifo_empty && ((s0_grant[0] && s0_awready) || (s1_grant[0] && s1_awready) || m0_decode_error_saved);
		  assign m1_fifo_pop = !m1_fifo_empty && ((s0_grant[1] && s0_awready) || (s1_grant[1] && s1_awready) || m1_decode_error_saved);
		  
		  
		  //assigning fifo data to m0 and m1
		  //
		  assign m0_fifo_awburst = m0_fifo_awdata_out[BURST_TYPE-1:0];
		  assign m0_fifo_awsize = m0_fifo_awdata_out[BURST_TYPE + SIZE_WIDTH - 1:BURST_TYPE];
		  assign m0_fifo_awlen = m0_fifo_awdata_out[BURST_TYPE + SIZE_WIDTH + LEN_WIDTH - 1:BURST_TYPE + SIZE_WIDTH];
		  assign m0_fifo_awaddr = m0_fifo_awdata_out[BURST_TYPE + SIZE_WIDTH + LEN_WIDTH + ADDR_WIDTH - 1: BURST_TYPE + SIZE_WIDTH + LEN_WIDTH];
		  assign m0_fifo_awid = m0_fifo_awdata_out[FIFO_WORD_WIDTH-1: BURST_TYPE + SIZE_WIDTH + LEN_WIDTH + ADDR_WIDTH];

		  assign m1_fifo_awburst = m1_fifo_awdata_out[BURST_TYPE-1:0];
		  assign m1_fifo_awsize = m1_fifo_awdata_out[BURST_TYPE + SIZE_WIDTH - 1:BURST_TYPE];
		  assign m1_fifo_awlen = m1_fifo_awdata_out[BURST_TYPE + SIZE_WIDTH + LEN_WIDTH - 1:BURST_TYPE + SIZE_WIDTH];
		  assign m1_fifo_awaddr = m1_fifo_awdata_out[BURST_TYPE + SIZE_WIDTH + LEN_WIDTH + ADDR_WIDTH - 1: BURST_TYPE + SIZE_WIDTH + LEN_WIDTH];
		  assign m1_fifo_awid = m1_fifo_awdata_out[FIFO_WORD_WIDTH-1: BURST_TYPE + SIZE_WIDTH + LEN_WIDTH + ADDR_WIDTH];

		  //TAG AWID
		  
		  wire [TAG_WIDTH-1:0] m0_fifo_awid_tagged;
		  wire [TAG_WIDTH-1:0] m1_fifo_awid_tagged;
		  id_tagger #(.ID_TAG(0)) tag_m0_id (
			  .id_in(m0_fifo_awid), .id_out(m0_fifo_awid_tagged)
			  );
		 id_tagger #(.ID_TAG(1)) tag_m1_id (
			  .id_in(m1_fifo_awid), .id_out(m1_fifo_awid_tagged)
			  );  


		  //DRIVE GRANTED MASTER DATA TO SLAVE
		
		  assign s0_awaddr= s0_grant[0] ? m0_fifo_awaddr : m1_fifo_awaddr;
		  assign s0_awid = s0_grant[0] ? m0_fifo_awid_tagged : m1_fifo_awid_tagged;
		  assign s0_awlen= s0_grant[0] ? m0_fifo_awlen : m1_fifo_awlen;
		  assign s0_awsize= s0_grant[0] ? m0_fifo_awsize : m1_fifo_awsize;
		  assign s0_awburst= s0_grant[0] ? m0_fifo_awburst : m1_fifo_awburst;
		  assign s0_awvalid = s0_grant[0] ? !m0_fifo_empty : s0_grant[1] ? !m1_fifo_empty : 1'b0;
		  //DRIVE GRANTED MASTER DATA TO SLAVE

                  assign s1_awaddr= s1_grant[0] ? m0_fifo_awaddr : m1_fifo_awaddr;
                  assign s1_awid = s1_grant[0] ? m0_fifo_awid_tagged : m1_fifo_awid_tagged;
                  assign s1_awlen= s1_grant[0] ? m0_fifo_awlen : m1_fifo_awlen;
                  assign s1_awsize= s1_grant[0] ? m0_fifo_awsize : m1_fifo_awsize;
                  assign s1_awburst= s1_grant[0] ? m0_fifo_awburst : m1_fifo_awburst;
		  assign s1_awvalid = s1_grant[0] ? !m0_fifo_empty : s1_grant[1] ? !m1_fifo_empty : 1'b0;
	  endmodule
