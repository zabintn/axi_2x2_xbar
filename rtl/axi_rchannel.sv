`timescale 1ns/1ps

module axi_rchannel #(parameter ADDR_WIDTH  = 32,
    parameter DATA_WIDTH = 64,
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

	    input wire [TAG_WIDTH-1:0] s0_rid,
	    input wire [DATA_WIDTH-1:0] s0_rdata,
	    input wire [1:0] s0_rresp,
	    input wire s0_rlast,
	    input wire s0_rvalid,
	    output wire s0_rready,
	   
	    input wire [TAG_WIDTH-1:0] s1_rid,
	    input wire [DATA_WIDTH-1:0] s1_rdata,
	    input wire [1:0] s1_rresp,
	    input wire s1_rlast,
	    input wire s1_rvalid,
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
	    output wire m1_rvalid,

	    input wire s0_arvalid,
	    input wire s0_arready,

	    input wire s1_arvalid,
	    input wire s1_arready,
	   
	    input wire [ID_WIDTH-1:0] m0_arid,
	    input wire [ID_WIDTH-1:0] m1_arid,
	    input wire [LEN_WIDTH-1:0] m0_arlen,
	    input wire [LEN_WIDTH-1:0] m1_arlen,

	    input wire [TAG_WIDTH-1:0] s0_arid,
	    input wire [TAG_WIDTH-1:0] s1_arid

	    );

	  //rid, rdata, rresp, and rlast will be pushed into FIFO from slave


	    wire s0_rfifo_push, s1_rfifo_push;
	    wire s0_rfifo_pop, s1_rfifo_pop;
	    wire s0_rfifo_empty, s1_rfifo_empty;
	    wire s0_rfifo_full, s1_rfifo_full;

	  localparam FIFO_WORD_WIDTH = TAG_WIDTH + DATA_WIDTH + 2 + 1;
	  wire [FIFO_WORD_WIDTH-1:0] s0_rfifo_data_in= {s0_rid, s0_rdata, s0_rresp, s0_rlast};
	  wire [FIFO_WORD_WIDTH-1:0] s1_rfifo_data_in= {s1_rid, s1_rdata, s1_rresp, s1_rlast};  
	  wire [FIFO_WORD_WIDTH-1:0] s0_rfifo_data_out;
	  wire [FIFO_WORD_WIDTH-1:0] s1_rfifo_data_out;
	  assign s0_rready= !s0_rfifo_full;
	  assign s1_rready= !s1_rfifo_full;

	  assign s0_rfifo_push=s0_rready && s0_rvalid;
	  assign s1_rfifo_push=s1_rready && s1_rvalid;
	  
	  sync_fifo #(.DEPTH(8), .DATA_WIDTH(FIFO_WORD_WIDTH)) s0_rfifo  ( .clk(aclk), 
		  .rstn(arst_n), .wr_en(s0_rfifo_push), .rd_en(s0_rfifo_pop), .wdata(s0_rfifo_data_in), .rdata(s0_rfifo_data_out), 
		  .full(s0_rfifo_full), .empty(s0_rfifo_empty));
	  
	 sync_fifo #(.DEPTH(8), .DATA_WIDTH(FIFO_WORD_WIDTH)) s1_rfifo  ( .clk(aclk), 
		  .rstn(arst_n), .wr_en(s1_rfifo_push), .rd_en(s1_rfifo_pop), .wdata(s1_rfifo_data_in), .rdata(s1_rfifo_data_out), 
		  .full(s1_rfifo_full), .empty(s1_rfifo_empty));

	//decode rid
	//
	wire s0_master_sel, s1_master_sel;
	wire [ID_WIDTH-1:0] s0_id_stripped, s1_id_stripped;

	id_decoder #(.ID_WIDTH(ID_WIDTH)) s0_rid_decoder (.id_tagged(s0_rfifo_data_out[FIFO_WORD_WIDTH-1:FIFO_WORD_WIDTH-TAG_WIDTH]), .id_stripped(s0_id_stripped), 
		.master_sel(s0_master_sel));
	id_decoder #(.ID_WIDTH(ID_WIDTH)) s1_rid_decoder (.id_tagged(s1_rfifo_data_out[FIFO_WORD_WIDTH-1:FIFO_WORD_WIDTH-TAG_WIDTH]), .id_stripped(s1_id_stripped), 
		.master_sel(s1_master_sel));

		//when master decided, check request
	    wire s0_req_m0, s1_req_m0;
	    wire s0_req_m1, s1_req_m1;
	    assign s0_req_m0 = (s0_master_sel == 1'b0) && !s0_rfifo_empty;
	    assign s1_req_m0 = (s1_master_sel == 1'b0) && !s1_rfifo_empty;
	    assign s0_req_m1 = (s0_master_sel == 1'b1) && !s0_rfifo_empty;
	    assign s1_req_m1 = (s1_master_sel == 1'b1) && !s1_rfifo_empty;

	    //instantiate error response
	    //
	    
	    wire [ID_WIDTH-1:0] m0_error_rid;
	    wire [1:0]          m0_error_rresp;
	    wire                m0_error_rvalid;
	    wire [DATA_WIDTH-1:0] m0_error_rdata;
	    wire		m0_error_rlast;
	    
	    wire [ID_WIDTH-1:0] m1_error_rid;
	    wire [1:0]          m1_error_rresp;
	    wire                m1_error_rvalid;
	    wire [DATA_WIDTH-1:0] m1_error_rdata;
	    wire		m1_error_rlast;


	    
	   read_error #(.ID_WIDTH(ID_WIDTH)) m0_error_response (
		    .clk     (aclk),
		    .rstn    (arst_n),
		    .ar_err  (m0_decode_error),
		    .arid    (m0_arid),
		    .arvalid (m0_arvalid),.arready (m0_arready),
		    .arlen (m0_arlen),
		    .rready  (m0_rready),
		    .rid     (m0_error_rid),
		    .rdata   (m0_error_rdata),
		    .rresp   (m0_error_rresp),
		    .rlast   (m0_error_rlast),
		    .rvalid  (m0_error_rvalid)		    
		    );
	 
	   read_error #(.ID_WIDTH(ID_WIDTH)) m1_error_response (
		    .clk     (aclk),
		    .rstn    (arst_n),
		    .ar_err  (m1_decode_error),
		    .arid    (m1_arid),
		    .arvalid (m1_arvalid),.arready (m1_arready),
		    .arlen (m1_arlen),
		    .rready  (m1_rready),
		    .rid     (m1_error_rid),
		    .rdata   (m1_error_rdata),
		    .rresp   (m1_error_rresp),
		    .rlast   (m1_error_rlast),
		    .rvalid  (m1_error_rvalid) 
		    );


	//instantiate arbiter	    
	  wire [1:0] m0_grant, m1_grant;
	  wire s0_done;
	  wire s1_done;
	  
  
	  wire m0_done = (m0_grant == 2'b10 && s0_done) ||(m0_grant == 2'b11 && s1_done) || (m0_grant == 2'b01 && m0_error_rvalid && m0_rready && m0_error_rlast);
	  wire m1_done = (m1_grant == 2'b10 && s0_done) ||(m1_grant == 2'b11 && s1_done) || (m1_grant == 2'b01 && m1_error_rvalid && m1_rready && m1_error_rlast);
	    fixed_priority_arbiter m0_response_arbiter(.clk(aclk), .rst_n(arst_n), 
		   .err_valid(m0_decode_error), .s0_valid(s0_req_m0), .s1_valid(s1_req_m0),
		   .last_i(m0_done),
		   .S0_grant(m0_grant));
	
	    fixed_priority_arbiter m1_response_arbiter(.clk(aclk), .rst_n(arst_n), 
		   .err_valid(m1_decode_error), .s0_valid(s0_req_m1), .s1_valid(s1_req_m1),
		   .last_i(m1_done),
		   .S0_grant(m1_grant));    

	//fifo pop in case of slave grant or error
	
	assign s0_rfifo_pop = (!s0_rfifo_empty && (((m0_grant == 2'b10 || m0_grant == 2'b01) && m0_rready) || ((m1_grant == 2'b10 || m1_grant == 2'b01) && m1_rready)));
	assign s1_rfifo_pop = (!s1_rfifo_empty && (((m0_grant == 2'b11 || m0_grant == 2'b01) && m0_rready) || ((m1_grant == 2'b11 || m1_grant == 2'b01) && m1_rready)));
	
	wire [ID_WIDTH-1:0] s0_rfifo_rid, s1_rfifo_rid;
	wire [DATA_WIDTH-1:0] s0_rfifo_rdata, s1_rfifo_rdata;
	wire [1:0] s0_rfifo_rresp, s1_rfifo_rresp;
	wire s0_rfifo_rlast, s1_rfifo_rlast;

	assign s0_rfifo_rlast = s0_rfifo_data_out[0];
	assign s0_rfifo_rresp = s0_rfifo_data_out[2:1];
	assign s0_rfifo_rdata = s0_rfifo_data_out[DATA_WIDTH+2:3];
	assign s0_rfifo_rid   = s0_rfifo_data_out[FIFO_WORD_WIDTH-2:DATA_WIDTH+3];
	
	assign s1_rfifo_rlast = s1_rfifo_data_out[0];
	assign s1_rfifo_rresp = s1_rfifo_data_out[2:1];
	assign s1_rfifo_rdata = s1_rfifo_data_out[DATA_WIDTH+2:3];
	assign s1_rfifo_rid   = s1_rfifo_data_out[FIFO_WORD_WIDTH-2:DATA_WIDTH+3];
	
	assign s0_done = s0_rfifo_rlast && ( (m0_grant == 2'b10 && m0_rready) || (m1_grant == 2'b10 && m1_rready) );
	assign s1_done = s1_rfifo_rlast && ( (m0_grant == 2'b11 && m0_rready) || (m1_grant == 2'b11 && m1_rready) );
	
	assign m0_rid   = (m0_grant==2'b10) ? s0_rfifo_rid  : (m0_grant==2'b11) ? s1_rfifo_rid  : m0_error_rid;
	assign m0_rdata = (m0_grant==2'b10) ? s0_rfifo_rdata: (m0_grant==2'b11) ? s1_rfifo_rdata: {DATA_WIDTH{1'b0}};
	assign m0_rresp = (m0_grant==2'b10) ? s0_rfifo_rresp: (m0_grant==2'b11) ? s1_rfifo_rresp: m0_error_rresp;
	assign m0_rvalid = (m0_grant==2'b10) ? !s0_rfifo_empty : (m0_grant==2'b11) ? !s1_rfifo_empty : (m0_grant==2'b01) ? m0_error_rvalid : 1'b0;
 
	assign m1_rid   = (m1_grant==2'b10) ? s0_rfifo_rid  : (m1_grant==2'b11) ? s1_rfifo_rid  : m1_error_rid;
	assign m1_rdata = (m1_grant==2'b10) ? s0_rfifo_rdata: (m1_grant==2'b11) ? s1_rfifo_rdata: {DATA_WIDTH{1'b0}};
	assign m1_rresp = (m1_grant==2'b10) ? s0_rfifo_rresp: (m1_grant==2'b11) ? s1_rfifo_rresp: m1_error_rresp;
	assign m1_rvalid = (m1_grant==3'b10) ? !s0_rfifo_empty : (m1_grant==2'b11) ? !s1_rfifo_empty : (m1_grant==2'b01) ? m1_error_rvalid : 1'b0;
		
	assign m0_rlast = (m0_grant==2'b10) ? s0_rfifo_rlast : (m0_grant==2'b11) ? s1_rfifo_rlast : (m0_grant==2'b01) ? m0_error_rlast : 1'b0;
	assign m1_rlast = (m1_grant==2'b10) ? s0_rfifo_rlast : (m1_grant==2'b11) ? s1_rfifo_rlast : (m1_grant==2'b01) ? m1_error_rlast : 1'b0;


endmodule
 




