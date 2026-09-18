`timescale 1ns/1ps

module axi_xbar_ar #(    parameter ADDR_WIDTH  = 32,
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

	   input wire [ADDR_WIDTH-1:0]  m0_araddr,
	   input wire [ID_WIDTH-1:0]    m0_arid,
	   input wire [LEN_WIDTH-1:0]   m0_arlen,
	   input wire [SIZE_WIDTH-1:0]  m0_arsize,
	   input wire [BURST_TYPE-1:0] m0_arburst,
	   input wire  m0_arvalid,
	   output wire m0_arready,

	   input wire [ADDR_WIDTH-1:0]  m1_araddr,
	   input wire [ID_WIDTH-1:0]    m1_arid,
	   input wire [LEN_WIDTH-1:0]   m1_arlen,
	   input wire [SIZE_WIDTH-1:0]  m1_arsize,
	   input wire [BURST_TYPE-1:0] m1_arburst,
	   input wire  m1_arvalid,
	   output wire m1_arready,
	   
	   output wire [ADDR_WIDTH-1:0] s0_araddr,
	   output wire [TAG_WIDTH-1:0] s0_arid,
	   output wire [LEN_WIDTH-1:0] s0_arlen,
	   output wire [SIZE_WIDTH-1:0] s0_arsize,
	   output wire [BURST_TYPE-1:0] s0_arburst,
	   input wire s0_arready,
	   output wire s0_arvalid,

	   input wire s0_rlast,
	   input wire s1_rlast,
	 
	   output wire [ADDR_WIDTH-1:0] s1_araddr,
	   output wire [TAG_WIDTH-1:0] s1_arid,
	   output wire [LEN_WIDTH-1:0] s1_arlen,
	   output wire [SIZE_WIDTH-1:0] s1_arsize,
	   output wire [BURST_TYPE-1:0] s1_arburst,
	   input wire s1_arready,
	   output wire s1_arvalid,

	   output wire s0_locked,
	   output wire s0_owner,
	   output wire s1_locked,
	   output wire s1_owner, 

	   output wire m0_decode_error,
	   output wire m1_decode_error
	  
	   );

         //FIFO PUSH
	   
	   wire m0_fifo_empty, m0_fifo_full;
	   wire m0_fifo_push, m0_fifo_pop;
	   wire m1_fifo_empty, m1_fifo_full;
	   wire m1_fifo_push, m1_fifo_pop;


	   localparam FIFO_WORD_WIDTH= ID_WIDTH + ADDR_WIDTH + LEN_WIDTH + SIZE_WIDTH + BURST_TYPE;
	   wire [FIFO_WORD_WIDTH-1:0] m0_fifo_ardata_in = {m0_arid, m0_araddr, m0_arlen, m0_arsize, m0_arburst};
	   wire [FIFO_WORD_WIDTH-1:0] m1_fifo_ardata_in = {m1_arid, m1_araddr, m1_arlen, m1_arsize, m1_arburst};

	   wire [FIFO_WORD_WIDTH-1:0] m0_fifo_ardata_out;
	   wire [FIFO_WORD_WIDTH-1:0] m1_fifo_ardata_out;

	   wire [BURST_TYPE-1:0] m0_fifo_arburst;
	   wire [BURST_TYPE-1:0] m1_fifo_arburst;
	   
	   wire [SIZE_WIDTH-1:0] m0_fifo_arsize;
	   wire [SIZE_WIDTH-1:0] m1_fifo_arsize;
	   
	   wire [LEN_WIDTH-1:0] m0_fifo_arlen;
	   wire [LEN_WIDTH-1:0] m1_fifo_arlen;
	   
	   wire [ADDR_WIDTH-1:0] m0_fifo_araddr;
	   wire [ADDR_WIDTH-1:0] m1_fifo_araddr;
	   
	   wire [ID_WIDTH-1:0] m0_fifo_arid;
	   wire [ID_WIDTH-1:0] m1_fifo_arid;

	   //fifo handshake
	   //
	   assign m0_arready= !m0_fifo_full;
	   assign m1_arready= !m1_fifo_full;

	   assign m0_fifo_push= m0_arvalid && m0_arready;  
	   assign m1_fifo_push= m1_arvalid && m1_arready;  

	   //master 0 fifo instantiation
	   
	   sync_fifo #(.DEPTH(8), .DATA_WIDTH(FIFO_WORD_WIDTH)
	   ) m0_ar_fifo ( .clk(aclk), .rstn(arst_n), .wr_en(m0_fifo_push), .rd_en(m0_fifo_pop), .wdata(m0_fifo_ardata_in), .rdata(m0_fifo_ardata_out), .full(m0_fifo_full), .empty(m0_fifo_empty)
	   );
	
	   //master 1 fifo instantiation

	   sync_fifo #(.DEPTH(8), .DATA_WIDTH(FIFO_WORD_WIDTH)
	   ) m1_ar_fifo ( .clk(aclk), .rstn(arst_n), .wr_en(m1_fifo_push), .rd_en(m1_fifo_pop), .wdata(m1_fifo_ardata_in), .rdata(m1_fifo_ardata_out), .full(m1_fifo_full), .empty(m1_fifo_empty)
	   );

	   //decode address
	   //
	   
	   wire [1:0] m0_slave_sel, m1_slave_sel;
	   wire m0_decode_error_saved;
	   wire m1_decode_error_saved;
	   addr_decoder #( .ADDR_WIDTH(ADDR_WIDTH)) m0_address_decoder (
		   .address   (m0_fifo_araddr),
		   .slave_sel (m0_slave_sel),
		   .error     (m0_decode_error_saved)
		   );
		   
	   addr_decoder #(.ADDR_WIDTH(ADDR_WIDTH)) m1_address_decoder (
		   .address   (m1_fifo_araddr),
		   .slave_sel (m1_slave_sel),
		   .error     (m1_decode_error_saved)
		   );
		   
	assign m0_decode_error = !m0_fifo_empty && m0_decode_error_saved;
	assign m1_decode_error = !m1_fifo_empty && m1_decode_error_saved;//arbiter
	  
	  wire s0_accept;
	  wire s1_accept;
	  
	  wire [1:0] s0_grant;
	  wire [1:0] s1_grant;

	  wire [1:0] s0_req;
	  wire [1:0] s1_req;

	  wire m0_s0_req, m1_s0_req, m0_s1_req, m1_s1_req;

	  assign s0_accept=(|s0_grant && s0_arready);
	  assign s1_accept=(|s1_grant && s1_arready);


	  assign m0_s0_req= !m0_fifo_empty && !m0_decode_error_saved && (m0_slave_sel == 2'b00) && !(s1_locked && s1_owner==1'b0);
	  assign m1_s0_req= !m1_fifo_empty && !m1_decode_error_saved && (m1_slave_sel == 2'b00) && !(s1_locked && s1_owner==1'b1);
	  assign s0_req= {m1_s0_req, m0_s0_req};
	
	  assign m0_s1_req= !m0_fifo_empty && !m0_decode_error_saved && (m0_slave_sel == 2'b01) && !(s0_locked && s0_owner==1'b0);
	  assign m1_s1_req= !m1_fifo_empty && !m1_decode_error_saved && (m1_slave_sel == 2'b01) && !(s1_locked && s1_owner==1'b1); 
	  assign s1_req= {m1_s1_req, m0_s1_req};
	 
	  rr_arbiter #(.NUM_REQ(2)) slave_0_arbiter ( .clk(aclk), .resetn(arst_n), 
		  .req(s0_req), .done(s0_rlast), 
		  .grant(s0_grant), .accept(s0_accept), 
		  .locked(s0_locked), .owner(s0_owner));
		  
	  rr_arbiter #(.NUM_REQ(2)) slave_1_arbiter ( .clk(aclk), .resetn(arst_n), 
			  .req(s1_req), .done(s1_rlast), 
			  .grant(s1_grant), .accept(s1_accept), 
			  .locked(s1_locked), .owner(s1_owner));
	
	//fifo will pop when grant is high or in case of decode errors
			  
	assign m0_fifo_pop= !m0_fifo_empty && ( 
		(s0_grant[0] && s0_arready) || 
		(s1_grant[0] && s1_arready) || 
		m0_decode_error_saved); 
		
	assign m1_fifo_pop= !m1_fifo_empty && ( 
		(s0_grant[1] && s0_arready) || 
		(s1_grant[1] && s1_arready) || 
		m1_decode_error_saved) ;

	//assign fifo data to m0 and m1
		  
	assign m0_fifo_arburst = m0_fifo_ardata_out[BURST_TYPE-1:0];
	assign m0_fifo_arsize = m0_fifo_ardata_out[BURST_TYPE + SIZE_WIDTH - 1:BURST_TYPE];
	assign m0_fifo_arlen = m0_fifo_ardata_out[BURST_TYPE + SIZE_WIDTH + LEN_WIDTH - 1:BURST_TYPE + SIZE_WIDTH];
	assign m0_fifo_araddr = m0_fifo_ardata_out[BURST_TYPE + SIZE_WIDTH + LEN_WIDTH + ADDR_WIDTH - 1: BURST_TYPE + SIZE_WIDTH + LEN_WIDTH];
	assign m0_fifo_arid = m0_fifo_ardata_out[FIFO_WORD_WIDTH-1: BURST_TYPE + SIZE_WIDTH + LEN_WIDTH + ADDR_WIDTH];
	
	assign m1_fifo_arburst = m1_fifo_ardata_out[BURST_TYPE-1:0];
	assign m1_fifo_arsize = m1_fifo_ardata_out[BURST_TYPE + SIZE_WIDTH - 1:BURST_TYPE];
	assign m1_fifo_arlen = m1_fifo_ardata_out[BURST_TYPE + SIZE_WIDTH + LEN_WIDTH - 1:BURST_TYPE + SIZE_WIDTH];
	assign m1_fifo_araddr = m1_fifo_ardata_out[BURST_TYPE + SIZE_WIDTH + LEN_WIDTH + ADDR_WIDTH - 1: BURST_TYPE + SIZE_WIDTH + LEN_WIDTH];
	assign m1_fifo_arid = m1_fifo_ardata_out[FIFO_WORD_WIDTH-1: BURST_TYPE + SIZE_WIDTH + LEN_WIDTH + ADDR_WIDTH];

	 //TAG ARID
		  
		  wire [TAG_WIDTH-1:0] m0_fifo_arid_tagged;
		  wire [TAG_WIDTH-1:0] m1_fifo_arid_tagged;
		  id_tagger #(.ID_TAG(0)) tag_m0_id (
			  .id_in(m0_fifo_arid), .id_out(m0_fifo_arid_tagged)
			  );
		  
		  id_tagger #(.ID_TAG(1)) tag_m1_id (
			  .id_in(m1_fifo_arid), .id_out(m1_fifo_arid_tagged)
			  );  

	  //DRIVE GRANTED MASTER DATA TO SLAVE
		assign s0_araddr= s0_grant[0] ? m0_fifo_araddr : m1_fifo_araddr;
                  assign s0_arid = s0_grant[0] ? m0_fifo_arid_tagged : m1_fifo_arid_tagged;
                  assign s0_arlen= s0_grant[0] ? m0_fifo_arlen : m1_fifo_arlen;
                  assign s0_arsize= s0_grant[0] ? m0_fifo_arsize : m1_fifo_arsize;
                  assign s0_arburst= s0_grant[0] ? m0_fifo_arburst : m1_fifo_arburst;
		  assign s0_arvalid = s0_grant[0] ? !m0_fifo_empty : s0_grant[1] ? !m1_fifo_empty : 1'b0;



		  //DRIVE GRANTED MASTER DATA TO SLAVE

                  assign s1_araddr= s1_grant[0] ? m0_fifo_araddr : m1_fifo_araddr;
                  assign s1_arid = s1_grant[0] ? m0_fifo_arid_tagged : m1_fifo_arid_tagged;
                  assign s1_arlen= s1_grant[0] ? m0_fifo_arlen : m1_fifo_arlen;
                  assign s1_arsize= s1_grant[0] ? m0_fifo_arsize : m1_fifo_arsize;
                  assign s1_arburst= s1_grant[0] ? m0_fifo_arburst : m1_fifo_arburst;
		  assign s1_arvalid = s1_grant[0] ? !m0_fifo_empty : s1_grant[1] ? !m1_fifo_empty : 1'b0;
	  endmodule
	


