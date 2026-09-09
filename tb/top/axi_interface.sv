`timescale 1ns/1ps

import axi_param_pkg::*;
interface axi_xbar_if;
      
	   logic aclk;
	   logic arst_n;
//================================AW CHANNEL==========================
	   logic [ADDR_WIDTH-1:0]  m0_awaddr;
	   logic [ID_WIDTH-1:0] m0_awid;
	   logic [LEN_WIDTH-1:0] m0_awlen;
	   logic [SIZE_WIDTH-1:0] m0_awsize;
	   logic [BURST_TYPE-1:0] m0_awburst;
	   logic  m0_awvalid;
	   logic  m0_awready;
	   logic [1:0] m0_slave_sel;

	   logic [ADDR_WIDTH-1:0]  m1_awaddr;
	   logic [ID_WIDTH-1:0]    m1_awid;
	   logic [LEN_WIDTH-1:0]   m1_awlen;
	   logic [SIZE_WIDTH-1:0]  m1_awsize;
	   logic [BURST_TYPE-1:0] m1_awburst;
	   logic  m1_awvalid;
	   logic  m1_awready;
	   logic [1:0] m1_slave_sel;

	   logic [ADDR_WIDTH-1:0] s0_awaddr;
	   logic [TAG_WIDTH-1:0] s0_awid;
	   logic [LEN_WIDTH-1:0] s0_awlen;
	   logic [SIZE_WIDTH-1:0] s0_awsize;
	   logic [BURST_TYPE-1:0] s0_awburst;
	   logic s0_awready;
	   logic s0_awvalid;
	
	   logic [ADDR_WIDTH-1:0] s1_awaddr;
	   logic [TAG_WIDTH-1:0] s1_awid;
	   logic [LEN_WIDTH-1:0] s1_awlen;
	   logic [SIZE_WIDTH-1:0] s1_awsize;
	   logic [BURST_TYPE-1:0] s1_awburst;
	   logic s1_awready;
	   logic s1_awvalid;
	   logic m0_decode_error;
	   logic m1_decode_error;
//==================================W CHANNEL===========================
	   
	   logic [DATA_WIDTH-1:0] m0_wdata;
	   logic [DATA_WIDTH/8-1:0] m0_wstrb;
	   logic m0_wlast;
	   logic m0_wvalid;
	   logic m0_wready;
	   
	   logic [DATA_WIDTH-1:0] m1_wdata;
	   logic [DATA_WIDTH/8-1:0] m1_wstrb;
	   logic m1_wlast;
	   logic m1_wvalid;
	   logic m1_wready;

	   logic s0_wvalid;
	   logic s1_wvalid;
	   logic s0_wready;
	   logic s1_wready;
	  
	   logic [DATA_WIDTH-1:0] s0_wdata;
	   logic [DATA_WIDTH/8-1:0] s0_wstrb;
	   logic s0_wlast;
	   
	   logic [DATA_WIDTH-1:0] s1_wdata;
	   logic [DATA_WIDTH/8-1:0] s1_wstrb;
	   logic s1_wlast;

//==================================B CHANNEL=============================

	   logic [ID_WIDTH-1:0] m0_bid;
	   logic [1:0] m0_bresp;
	   logic m0_bvalid;
	   logic m0_bready;
	   
	   logic [1:0] s0_bresp;
	   logic s0_bvalid;
	   logic s0_bready;
	   logic [TAG_WIDTH-1:0] s0_bid;
	   
	   logic [ID_WIDTH-1:0] m1_bid;
	   logic [1:0] m1_bresp;
	   logic m1_bvalid;
	   logic m1_bready;
	   logic [1:0] s1_bresp;
	   logic s1_bvalid;
	   logic s1_bready;
	   logic [TAG_WIDTH-1:0] s1_bid;
	   
//===========================AR CHANNEL==================================
	    logic [ADDR_WIDTH-1:0]  m0_araddr;

	    logic [ID_WIDTH-1:0]    m0_arid;
	    logic [LEN_WIDTH-1:0]   m0_arlen;
	    logic [SIZE_WIDTH-1:0]  m0_arsize;
	    logic [BURST_TYPE-1:0] m0_arburst;
	    logic  m0_arvalid;
	    logic m0_arready;
	     
	    logic [ADDR_WIDTH-1:0]  m1_araddr;
	    logic [ID_WIDTH-1:0]    m1_arid;
	    logic [LEN_WIDTH-1:0]   m1_arlen;
	    logic [SIZE_WIDTH-1:0]  m1_arsize;
	    logic [BURST_TYPE-1:0] m1_arburst;
	    logic  m1_arvalid;
	    logic m1_arready;
	     
	    logic [ADDR_WIDTH-1:0] s0_araddr;
	    logic [TAG_WIDTH-1:0] s0_arid;
	    logic [LEN_WIDTH-1:0] s0_arlen;
	    logic [SIZE_WIDTH-1:0] s0_arsize;
	    logic [BURST_TYPE-1:0] s0_arburst;
	    logic s0_arready;
	    logic s0_arvalid;
	     
	    logic s0_rlast;
	    logic s1_rlast;
	     
	    logic [ADDR_WIDTH-1:0] s1_araddr;
	    logic [TAG_WIDTH-1:0] s1_arid;
	    logic [LEN_WIDTH-1:0] s1_arlen;
	    logic [SIZE_WIDTH-1:0] s1_arsize;
	    logic [BURST_TYPE-1:0] s1_arburst;
	    logic s1_arready;
	    logic s1_arvalid;
	     
	    logic s0_rlocked;
	    logic s0_rowner;
	    logic s1_rlocked;
	    logic s1_rowner;
	     
	    logic m0_rdecode_error;
	    logic m1_rdecode_error;
	   
	    logic [TAG_WIDTH-1:0] s0_rid;	     
	    logic [DATA_WIDTH-1:0] s0_rdata;
	    logic [1:0] s0_rresp;
	    logic s0_rvalid;
	    logic s0_rready;
	     
	    logic [TAG_WIDTH-1:0] s1_rid;
	    logic [DATA_WIDTH-1:0] s1_rdata;
	    logic [1:0] s1_rresp;
	    logic s1_rvalid;
	    logic s1_rready;
	     
	     logic m0_rready;
	     logic m1_rready;
	     
	     logic [ID_WIDTH-1:0] m0_rid;
	     logic [DATA_WIDTH-1:0] m0_rdata;
	     logic [1:0] m0_rresp;
	     logic m0_rlast;
	     logic m0_rvalid;
	     
	     logic [ID_WIDTH-1:0] m1_rid;
	     logic [DATA_WIDTH-1:0] m1_rdata;
	     logic [1:0] m1_rresp;
	     logic m1_rlast;
	     logic m1_rvalid;

	    initial begin
		    m0_awvalid = 1'b0;
		    m1_awvalid = 1'b0;
        	    m0_wvalid  = 1'b0;
		    m1_wvalid  = 1'b0;
		    s0_bvalid  = 1'b0;
		    s1_bvalid  = 1'b0;
		    s0_rvalid  = 1'b0;
		    s1_rvalid  = 1'b0;
		    s0_arvalid  = 1'b0;
		    s1_arvalid  = 1'b0;
	    end
   endinterface
