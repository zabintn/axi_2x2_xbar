`timescale 1ns/1ps

module axi_xbar_bchannel #(    parameter ADDR_WIDTH  = 32,
    parameter ID_WIDTH = 4,
    parameter TAG_WIDTH = ID_WIDTH + 1,
    parameter LEN_WIDTH=8,
    parameter SIZE_WIDTH=3,
    parameter BURST_TYPE=2
    )(
	    input wire aclk,
	    input wire arst_n,

	    input wire m0_decode_error,
	    input wire m1_decode_error,

	    //master 0 bchannel 
	
	    output wire [ID_WIDTH-1:0] m0_bid,

	    input wire [1:0] s0_bresp,
	    input wire s0_bvalid,
	    output wire s0_bready,
	    input wire [TAG_WIDTH-1:0] s0_bid,


	    input wire m0_bready,
	    output wire m0_bvalid,
	    output wire [1:0] m0_bresp,
	  
	    output wire [ID_WIDTH-1:0] m1_bid,

	    input wire [1:0] s1_bresp,
	    input wire s1_bvalid,
	    output wire s1_bready,
	    input wire [TAG_WIDTH-1:0] s1_bid,


	    input wire m1_bready,
	    output wire m1_bvalid,
	    output wire [1:0] m1_bresp,
	    
	    input wire [ID_WIDTH-1:0] m0_awid,
	    input wire m0_awvalid,
	    input wire m0_awready,
	    input wire m0_wlast,
	    input wire m0_wvalid,
	    input wire m0_wready,
	   
	   input wire [ID_WIDTH-1:0] m1_awid,
	   input wire m1_awvalid,
	   input wire m1_awready,
	   input wire m1_wlast,
	   input wire m1_wvalid,
	   input wire m1_wready,
	   
	   input wire s0_awvalid,
	   input wire s0_awready,

	   input wire s1_awvalid,
	   input wire s1_awready,

	   input wire [TAG_WIDTH-1:0] s0_awid,
	   input wire [TAG_WIDTH-1:0] s1_awid

	    );


	    //bresp and bid will be pushed into fifo
	    //
	  wire s0_bfifo_push, s1_bfifo_push;
	  wire s0_bfifo_pop, s1_bfifo_pop;
	  wire s0_bfifo_empty, s1_bfifo_empty;
	  wire s0_bfifo_full, s1_bfifo_full;
	   

	  localparam FIFO_WORD_WIDTH = TAG_WIDTH + 2;
	  wire [FIFO_WORD_WIDTH-1:0] s0_bfifo_data_in = {s0_bid, s0_bresp}; 
	  wire [FIFO_WORD_WIDTH-1:0] s1_bfifo_data_in = {s1_bid, s1_bresp};

	  wire [FIFO_WORD_WIDTH-1:0] s0_bfifo_data_out;
	  wire [FIFO_WORD_WIDTH-1:0] s1_bfifo_data_out;
	  
	  wire [1:0]          s0_bfifo_bresp;
	  wire [ID_WIDTH-1:0] s0_bfifo_bid;
	  wire [1:0]          s1_bfifo_bresp;
	  wire [ID_WIDTH-1:0] s1_bfifo_bid;
	  
	  assign s0_bready= !s0_bfifo_full;
	  assign s1_bready= !s1_bfifo_full;
 
	  assign s0_bfifo_push= s0_bready && s0_bvalid;
	  assign s1_bfifo_push= s1_bready && s1_bvalid;

	  sync_fifo #(.DEPTH(8), .DATA_WIDTH(FIFO_WORD_WIDTH)) s0_bfifo  ( .clk(aclk), 
		  .rstn(arst_n), .wr_en(s0_bfifo_push), .rd_en(s0_bfifo_pop), .wdata(s0_bfifo_data_in), .rdata(s0_bfifo_data_out), 
		  .full(s0_bfifo_full), .empty(s0_bfifo_empty));
	  
	 sync_fifo #(.DEPTH(8), .DATA_WIDTH(FIFO_WORD_WIDTH)) s1_bfifo  ( .clk(aclk), 
		  .rstn(arst_n), .wr_en(s1_bfifo_push), .rd_en(s1_bfifo_pop), .wdata(s1_bfifo_data_in), .rdata(s1_bfifo_data_out), 
		  .full(s1_bfifo_full), .empty(s1_bfifo_empty));


      //decode bid

	 wire s0_master_sel;
	 wire s1_master_sel;
	 wire [ID_WIDTH-1:0] s0_id_stripped, s1_id_stripped;
	 id_decoder #(.ID_WIDTH(ID_WIDTH)) s0_bid_decoder (.id_tagged(s0_bfifo_data_out[FIFO_WORD_WIDTH-1:2]), 
		 .id_stripped(s0_id_stripped), .master_sel(s0_master_sel)
		 );
	 id_decoder #(.ID_WIDTH(ID_WIDTH)) s1_bid_decoder (.id_tagged(s1_bfifo_data_out[FIFO_WORD_WIDTH-1:2]),
		 .id_stripped(s1_id_stripped), .master_sel(s1_master_sel));
	
	    //when master decided, check request
	    //

	    wire s0_req_m0, s1_req_m0;
	    wire s0_req_m1, s1_req_m1;
	    assign s0_req_m0 = (s0_master_sel == 1'b0) && !s0_bfifo_empty;
	    assign s1_req_m0 = (s1_master_sel == 1'b0) && !s1_bfifo_empty;
	    assign s0_req_m1 = (s0_master_sel == 1'b1) && !s0_bfifo_empty;
	    assign s1_req_m1 = (s1_master_sel == 1'b1) && !s1_bfifo_empty;

	    //instantiate error response   
	    
	    wire [ID_WIDTH-1:0] m0_error_bid;
	    wire [1:0]          m0_error_bresp;
	    wire                m0_error_bvalid;
	    
	    error_response_write #(.ID_WIDTH(ID_WIDTH)) m0_error_response (
		    .clk     (aclk),
		    .rstn    (arst_n),
		    .aw_err  (m0_decode_error),
		    .awid    (m0_awid),
		    .awvalid (m0_awvalid),.awready (m0_awready),
		    .wlast   (m0_wlast), .wvalid  (m0_wvalid),
		    .wready  (m0_wready),
		    .bid     (m0_error_bid),.bresp   (m0_error_bresp),
		    .bvalid  (m0_error_bvalid), .bready  (m0_bready)
		    );


	    wire [ID_WIDTH-1:0] m1_error_bid;
	    wire [1:0]          m1_error_bresp;
	    wire                m1_error_bvalid;
	    error_response_write #(.ID_WIDTH(ID_WIDTH)) m1_error_response (
		    .clk     (aclk),
		    .rstn    (arst_n),
		    .aw_err  (m1_decode_error),
		    .awid    (m1_awid),
		    .awvalid (m1_awvalid), 
		    .awready (m1_awready),
		    .wlast   (m1_wlast), 
		    .wvalid  (m1_wvalid),
		    .wready  (m1_wready),
		    .bid     (m1_error_bid), 
		    .bresp   (m1_error_bresp),
		    .bvalid  (m1_error_bvalid), 
		    .bready  (m1_bready)
    );
	    //instantiate arbiter
	    //
	    wire [1:0] m0_grant, m1_grant;

	    wire m0_done = (m0_grant != 2'b00) && m0_bvalid && m0_bready;
	    wire m1_done = (m1_grant != 2'b00) && m1_bvalid && m1_bready;
	    fixed_priority_arbiter m0_response_arbiter(
		    .clk(aclk), 
		    .rst_n(arst_n), 
		    .err_valid(m0_decode_error), 
		    .s0_valid(s0_req_m0), 
		    .s1_valid(s1_req_m0),
		    .last_i(m0_done),
		    .S0_grant(m0_grant));
	
	    fixed_priority_arbiter m1_response_arbiter(
		    .clk(aclk), 
		    .rst_n(arst_n), 
		    .err_valid(m1_decode_error), 
		    .s0_valid(s0_req_m1), 
		    .s1_valid(s1_req_m1),
		    .last_i(m1_done),
		    .S0_grant(m1_grant));    



	//fifo pop in case of slave grant or error
		
		assign s0_bfifo_pop = !s0_bfifo_empty && (( (m0_grant == 2'b10) && m0_bvalid && m0_bready) ||((m1_grant == 2'b10) && m1_bvalid && m1_bready));
		assign s1_bfifo_pop=  !s1_bfifo_empty && (( (m0_grant == 2'b11) && m0_bvalid && m0_bready) || ((m1_grant == 2'b11 && m1_bvalid && m1_bready)));

		//fifo data to master


		assign s0_bfifo_bresp = s0_bfifo_data_out[1:0];
		assign s0_bfifo_bid = s0_bfifo_data_out[FIFO_WORD_WIDTH-2:2];

		assign s1_bfifo_bresp = s1_bfifo_data_out[1:0];
		assign s1_bfifo_bid = s1_bfifo_data_out[FIFO_WORD_WIDTH-2:2];

		assign m0_bid = (m0_grant == 2'b10) ? s0_bfifo_bid : (m0_grant == 2'b11) ? s1_bfifo_bid : m0_error_bid; 
		assign m1_bid = (m1_grant == 2'b10) ? s0_bfifo_bid : (m1_grant == 2'b11) ? s1_bfifo_bid : m1_error_bid;

		assign m0_bresp = (m0_grant == 2'b10) ? s0_bfifo_bresp : (m0_grant == 2'b11) ? s1_bfifo_bresp : m0_error_bresp;
		assign m1_bresp = (m1_grant == 2'b10) ? s0_bfifo_bresp : (m1_grant == 2'b11) ? s1_bfifo_bresp : m1_error_bresp;
		
		assign m0_bvalid = (m0_grant == 2'b10) ? !s0_bfifo_empty : (m0_grant == 2'b11) ? !s1_bfifo_empty : (m0_grant == 2'b01) ? m0_error_bvalid:1'b0;
		assign m1_bvalid = (m1_grant == 2'b10) ? !s0_bfifo_empty : (m1_grant == 2'b11) ? !s1_bfifo_empty : (m1_grant == 2'b01) ? m1_error_bvalid:1'b0;

endmodule


