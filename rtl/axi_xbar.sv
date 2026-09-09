`timescale 1ns/1ps

module axi_xbar_top #(    parameter ADDR_WIDTH  = 32,
    parameter ID_WIDTH = 4,
    parameter MASTER_ID =0,
    parameter TAG_WIDTH = ID_WIDTH + 1,
    parameter LEN_WIDTH=8,
    parameter SIZE_WIDTH=3,
    parameter BURST_TYPE=2,
    parameter DATA_WIDTH=64
    )(

	   input wire aclk,
	   input wire arst_n,
//=======================AW CHANNEL====================
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
	  
	   output wire [ADDR_WIDTH-1:0] s1_awaddr,
	   output wire [TAG_WIDTH-1:0] s1_awid,
	   output wire [LEN_WIDTH-1:0] s1_awlen,
	   output wire [SIZE_WIDTH-1:0] s1_awsize,
	   output wire [BURST_TYPE-1:0] s1_awburst,
	   input wire s1_awready,
	   output wire s1_awvalid,

	   output logic m0_decode_error,
	   output logic m1_decode_error,


//========================W CHANNEL=================
	
	    input wire [DATA_WIDTH-1:0] m0_wdata,
	    input wire [DATA_WIDTH/8-1:0] m0_wstrb,
	    input wire m0_wlast,
	    input wire m0_wvalid,
	    output wire m0_wready,
	   
	    input wire [DATA_WIDTH-1:0] m1_wdata,
	    input wire [DATA_WIDTH/8-1:0] m1_wstrb,
	    input wire m1_wlast,
	    input wire m1_wvalid,
	    output wire m1_wready,

	    output wire s0_wvalid,
	    output wire s1_wvalid,

	    input wire s0_wready,
	    input wire s1_wready,

	    output wire [DATA_WIDTH-1:0] s0_wdata,
	    output wire [DATA_WIDTH/8-1:0] s0_wstrb,
	    output wire s0_wlast,

	    output wire [DATA_WIDTH-1:0] s1_wdata,
	    output wire [DATA_WIDTH/8-1:0] s1_wstrb,
	    output wire s1_wlast,
//========================B CHANNEL================
             output wire [ID_WIDTH-1:0] m0_bid,
	     output wire [1:0] m0_bresp,
	     output wire m0_bvalid,
	     input  wire m0_bready,
	     
	     input wire [1:0] s0_bresp,
	     input wire s0_bvalid,
	     output wire s0_bready,
	     input wire [TAG_WIDTH-1:0] s0_bid,
	    
	     output wire [ID_WIDTH-1:0] m1_bid,
	     output wire [1:0] m1_bresp,
	     output wire m1_bvalid,
	     input  wire m1_bready,
	     
	     input wire [1:0] s1_bresp,
	     input wire s1_bvalid,
	     output wire s1_bready,
	     input wire [TAG_WIDTH-1:0] s1_bid,

//==========================AR CHANNEL============== 
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
	     
	     output wire s0_rlocked,
	     output wire s0_rowner,
	     output wire s1_rlocked,
	     output wire s1_rowner, 
	     
	     output wire m0_rdecode_error,
	     output wire m1_rdecode_error,
	     
//=============================AR CHANNEL=====================
	     input wire [TAG_WIDTH-1:0] s0_rid, 	     
	     input  wire [DATA_WIDTH-1:0] s0_rdata,
	     input  wire [1:0] s0_rresp,
	     input  wire s0_rvalid,
	     output wire s0_rready,
	     
	     input  wire [TAG_WIDTH-1:0] s1_rid,
	     input  wire [DATA_WIDTH-1:0] s1_rdata,
	     input  wire [1:0] s1_rresp,
	     input  wire s1_rvalid,
	     output wire s1_rready,
	     
	     input  wire m0_rready,
	     input  wire m1_rready,
	     
	     output wire [ID_WIDTH-1:0] m0_rid,
	     output wire [DATA_WIDTH-1:0] m0_rdata,
	     output wire [1:0] m0_rresp,
	     output wire m0_rlast,
	     output wire m0_rvalid,
	     
	     output wire [ID_WIDTH-1:0] m1_rid,
	     output wire [DATA_WIDTH-1:0] m1_rdata,
	     output wire [1:0] m1_rresp,
	     output wire m1_rlast,
	     output wire m1_rvalid
	    );
wire m0_fifo_pop_i, m1_fifo_pop_i;
wire m0_decode_error_saved_i, m1_decode_error_saved_i;
wire [LEN_WIDTH-1:0] m0_fifo_awlen_i, m1_fifo_awlen_i;

	    wire s0_locked, s0_owner;
	    wire s1_locked, s1_owner;
	    axi_xbar_aw #(.ADDR_WIDTH(ADDR_WIDTH), 
		    .ID_WIDTH(ID_WIDTH),
		    .MASTER_ID(MASTER_ID),
		    .TAG_WIDTH(TAG_WIDTH),
		    .LEN_WIDTH(LEN_WIDTH),
		    .SIZE_WIDTH(SIZE_WIDTH),
		    .BURST_TYPE(BURST_TYPE)
		    ) awchannel (.aclk(aclk), 
			    .arst_n(arst_n),
			    .m0_awaddr(m0_awaddr), 
			    .m0_awid(m0_awid),
			    .m0_awlen(m0_awlen),
			    .m0_awsize(m0_awsize),
			    .m0_awburst(m0_awburst),
			    .m0_awvalid(m0_awvalid),
			    .m0_awready(m0_awready),
			    .m0_slave_sel(m0_slave_sel),
			    .m1_awaddr(m1_awaddr), 
			    .m1_awid(m1_awid),
			    .m1_awlen(m1_awlen), 
			    .m1_awsize(m1_awsize),
			    .m1_awburst(m1_awburst), 
			    .m1_awvalid(m1_awvalid), 
			    .m1_awready(m1_awready),
			    .m1_slave_sel(m1_slave_sel),
			    .s0_awaddr(s0_awaddr), 
			    .s0_awid(s0_awid),
			    .s0_awlen(s0_awlen),
			    .s0_awsize(s0_awsize),
			    .s0_awburst(s0_awburst),
			    .s0_awready(s0_awready),
			    .s0_awvalid(s0_awvalid),
			    .s0_wlast(s0_wlast),
			    .s1_wlast(s1_wlast),
			    .s1_awaddr(s1_awaddr), 
			    .s1_awid(s1_awid),
			    .s1_awlen(s1_awlen), 
			    .s1_awsize(s1_awsize),
			    .s1_awburst(s1_awburst), 
			    .s1_awready(s1_awready),
			    .s1_awvalid(s1_awvalid),
			    .s0_locked(s0_locked), 
			    .s0_owner(s0_owner),
			    .s1_locked(s1_locked),
			    .s1_owner(s1_owner),
			    .m0_decode_error(m0_decode_error), 
			    .m1_decode_error(m1_decode_error),
			    .m0_fifo_pop(m0_fifo_pop_i),
			    .m0_decode_error_saved(m0_decode_error_saved_i),
			    .m0_fifo_awlen(m0_fifo_awlen_i),
			    .m1_fifo_pop(m1_fifo_pop_i),
			    .m1_decode_error_saved(m1_decode_error_saved_i),
			    .m1_fifo_awlen(m1_fifo_awlen_i),
			    .s0_wvalid(s0_wvalid),
			    .s0_wready(s0_wready),
			    .s1_wvalid(s1_wvalid),
			    .s1_wready(s1_wready)

			  );

	// instantiate axi w channel
	

	axi_xbar_wchannel #(.ADDR_WIDTH(ADDR_WIDTH), 
		    .ID_WIDTH(ID_WIDTH),
		    .MASTER_ID(MASTER_ID),
		    .TAG_WIDTH(TAG_WIDTH),
		    .LEN_WIDTH(LEN_WIDTH),
		    .SIZE_WIDTH(SIZE_WIDTH),
		    .BURST_TYPE(BURST_TYPE)
		    ) wchannel(.aclk(aclk), .arst_n(arst_n),
			    .s0_locked(s0_locked), 
			    .s1_locked(s1_locked),
			    .s0_owner(s0_owner), 
			    .s1_owner(s1_owner),
			    .m0_wdata(m0_wdata), 
			    .m0_wstrb(m0_wstrb),
			    .m0_wlast(m0_wlast), 
			    .m0_wvalid(m0_wvalid), 
			    .m0_wready(m0_wready), 
			    .m1_wdata(m1_wdata),
			    .m1_wstrb(m1_wstrb), 
			    .m1_wlast(m1_wlast),
			    .m1_wvalid(m1_wvalid),
			    .m1_wready(m1_wready), 
			    .s0_wvalid(s0_wvalid),
			    .s1_wvalid(s1_wvalid),
			    .s0_wready(s0_wready),
			    .s1_wready(s1_wready),
			    .m0_decode_error(m0_decode_error), 
			    .m1_decode_error(m1_decode_error),
			    .s0_wdata(s0_wdata), 
			    .s0_wstrb(s0_wstrb),
			    .s0_wlast(s0_wlast), 
			    .s1_wdata(s1_wdata), 
			    .s1_wstrb(s1_wstrb),
			    .s1_wlast(s1_wlast),
			    .m0_fifo_pop(m0_fifo_pop_i),
			    .m0_decode_error_saved(m0_decode_error_saved_i),
			    .m0_fifo_awlen(m0_fifo_awlen_i),
			    .m1_fifo_pop(m1_fifo_pop_i),
			    .m1_decode_error_saved(m1_decode_error_saved_i),
			    .m1_fifo_awlen(m1_fifo_awlen_i)

			    );

	//instantiate axi b channel
	
	
	axi_xbar_bchannel #( .ADDR_WIDTH (ADDR_WIDTH), .ID_WIDTH   (ID_WIDTH),
		.TAG_WIDTH  (TAG_WIDTH), .LEN_WIDTH  (LEN_WIDTH),
		.SIZE_WIDTH (SIZE_WIDTH), .BURST_TYPE (BURST_TYPE) 
		) bchannel ( .aclk(aclk), 
			.arst_n(arst_n),
			.m0_decode_error(m0_decode_error), 
			.m1_decode_error(m1_decode_error),
			.m0_bid(m0_bid), 
			.m0_bresp(m0_bresp),
			.m0_bvalid(m0_bvalid), 
			.m0_bready(m0_bready),
			.s0_bresp(s0_bresp), 
			.s0_bvalid(s0_bvalid),
			.s0_bready(s0_bready),
			.s0_bid(s0_bid),
			.m1_bid(m1_bid), 
			.m1_bresp(m1_bresp),
			.m1_bvalid(m1_bvalid), 
			.m1_bready(m1_bready),
			.s1_bresp(s1_bresp), 
			.s1_bvalid(s1_bvalid),
			.s1_bready(s1_bready),
			.s1_bid(s1_bid),
			.m0_awid(m0_awid), 
			.m0_awvalid(m0_awvalid),
			.m0_awready(m0_awready), 
			.m0_wlast(m0_wlast),
			.m0_wvalid(m0_wvalid), 
			.m0_wready(m0_wready),
			.m1_awid(m1_awid), 
			.m1_awvalid(m1_awvalid),
			.m1_awready(m1_awready), 
			.m1_wlast(m1_wlast),
			.m1_wvalid(m1_wvalid),
			.m1_wready(m1_wready),
			.s0_awvalid(s0_awvalid), 
			.s0_awready(s0_awready),
			.s1_awvalid(s1_awvalid), 
			.s1_awready(s1_awready),
			.s0_awid(s0_awid), 
			.s1_awid(s1_awid)
			);

	//instantiate axi ar channnel
	//
	
	axi_xbar_ar #( .ADDR_WIDTH(ADDR_WIDTH), 
		.ID_WIDTH(ID_WIDTH),
		.TAG_WIDTH(TAG_WIDTH),
		.LEN_WIDTH(LEN_WIDTH),
		.SIZE_WIDTH(SIZE_WIDTH),
		.BURST_TYPE(BURST_TYPE)
		) archannel ( .aclk(aclk),
			.arst_n(arst_n),
			.m0_araddr(m0_araddr),
			.m0_arid(m0_arid),
			.m0_arlen(m0_arlen),
			.m0_arsize(m0_arsize),
			.m0_arburst(m0_arburst),
			.m0_arvalid(m0_arvalid),
			.m0_arready(m0_arready),
			.m1_araddr(m1_araddr),
			.m1_arid(m1_arid),
			.m1_arlen(m1_arlen),
			.m1_arsize(m1_arsize),
			.m1_arburst(m1_arburst),
			.m1_arvalid(m1_arvalid),
			.m1_arready(m1_arready),
			.s0_araddr(s0_araddr),
			.s0_arid(s0_arid),
			.s0_arlen(s0_arlen),
			.s0_arsize(s0_arsize),
			.s0_arburst(s0_arburst),
			.s0_arready(s0_arready),
			.s0_arvalid(s0_arvalid),
			.s1_araddr(s1_araddr),
			.s1_arid(s1_arid),
			.s1_arlen(s1_arlen),
			.s1_arsize(s1_arsize),
			.s1_arburst(s1_arburst),
			.s1_arready(s1_arready),
			.s1_arvalid(s1_arvalid),
			.s0_rlast(s0_rlast),
			.s1_rlast(s1_rlast),
			.s0_locked(s0_rlocked),
			.s0_owner(s0_rowner),
			.s1_locked(s1_rlocked),
			.s1_owner(s1_rowner),
			.m0_decode_error(m0_rdecode_error),
			.m1_decode_error(m1_rdecode_error)
			);
			
			axi_rchannel #(
    			.ADDR_WIDTH (ADDR_WIDTH),
    			.DATA_WIDTH (DATA_WIDTH),
    			.ID_WIDTH   (ID_WIDTH),
   			 .TAG_WIDTH  (TAG_WIDTH),
    			.LEN_WIDTH  (LEN_WIDTH),
    			.SIZE_WIDTH (SIZE_WIDTH),
    			.BURST_TYPE (BURST_TYPE)
			) u_axi_rchannel (
    				.aclk            (aclk),
    .arst_n          (arst_n),

    .m0_decode_error (m0_rdecode_error),
    .m1_decode_error (m1_rdecode_error),

    // Slave 0 read data channel
    .s0_rid          (s0_rid),
    .s0_rdata        (s0_rdata),
    .s0_rresp        (s0_rresp),
    .s0_rlast        (s0_rlast),
    .s0_rvalid       (s0_rvalid),
    .s0_rready       (s0_rready),

    // Slave 1 read data channel
    .s1_rid          (s1_rid),
    .s1_rdata        (s1_rdata),
    .s1_rresp        (s1_rresp),
    .s1_rlast        (s1_rlast),
    .s1_rvalid       (s1_rvalid),
    .s1_rready       (s1_rready),

    // Master read data channel
    .m0_rready       (m0_rready),
    .m1_rready       (m1_rready),

    .m0_rid          (m0_rid),
    .m0_rdata        (m0_rdata),
    .m0_rresp        (m0_rresp),
    .m0_rlast        (m0_rlast),
    .m0_rvalid       (m0_rvalid),

    .m1_rid          (m1_rid),
    .m1_rdata        (m1_rdata),
    .m1_rresp        (m1_rresp),
    .m1_rlast        (m1_rlast),
    .m1_rvalid       (m1_rvalid),

    // AR-side handshake / ID info (only used by rchannel for RID field width bookkeeping)
    .s0_arvalid      (s0_arvalid),
    .s0_arready      (s0_arready),
    .s1_arvalid      (s1_arvalid),
    .s1_arready      (s1_arready),

    .m0_arid         (m0_arid),
    .m1_arid         (m1_arid),
    .m0_arlen        (m0_arlen),
    .m1_arlen        (m1_arlen),
    .s0_arid         (s0_arid),
    .s1_arid         (s1_arid)
);


endmodule
