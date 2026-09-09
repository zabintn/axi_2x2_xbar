`timescale 1ns/1ps

module axi_xbar_wchannel #( parameter ADDR_WIDTH  = 32,
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

	    input wire s0_locked,
	    input wire s1_locked,
	    input wire s0_owner,
	    input wire s1_owner,

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

	    input wire m0_decode_error,
	    input wire m1_decode_error,

	    output wire [DATA_WIDTH-1:0] s0_wdata,
	    output wire [DATA_WIDTH/8-1:0]s0_wstrb,
	    output wire s0_wlast,

	    output wire [DATA_WIDTH-1:0] s1_wdata,
	    output wire [DATA_WIDTH/8-1:0] s1_wstrb,
	    output wire s1_wlast,

	    input wire m0_fifo_pop,
	    input wire m1_fifo_pop,
	    input wire m0_decode_error_saved,
	    input wire m1_decode_error_saved,
	    input wire [LEN_WIDTH-1:0] m0_fifo_awlen,
	    input wire [LEN_WIDTH-1:0] m1_fifo_awlen
	    );

//in W channel, data is first pushed to FIFO
//

  wire m0_wfifo_empty, m1_wfifo_empty;
  wire m0_wfifo_full, m1_wfifo_full;
  wire m0_wfifo_push, m1_wfifo_push;
  wire m0_wfifo_pop, m1_wfifo_pop;

  localparam STROBE_WIDTH= DATA_WIDTH/8;
  localparam FIFO_WORD_WIDTH= DATA_WIDTH + 1 + STROBE_WIDTH;

  wire [STROBE_WIDTH-1:0] m0_wfifo_wstrb;
  wire                    m0_wfifo_wlast;
  wire [DATA_WIDTH-1:0]   m0_wfifo_wdata;

  wire [STROBE_WIDTH-1:0] m1_wfifo_wstrb;
  wire                    m1_wfifo_wlast;
  wire [DATA_WIDTH-1:0]   m1_wfifo_wdata;

  wire [FIFO_WORD_WIDTH-1:0] m0_wfifo_write_in= {m0_wdata, m0_wlast, m0_wstrb};
  wire [FIFO_WORD_WIDTH-1:0] m1_wfifo_write_in= {m1_wdata, m1_wlast, m1_wstrb};

  wire [FIFO_WORD_WIDTH-1:0] m0_wfifo_write_out;
  wire [FIFO_WORD_WIDTH-1:0] m1_wfifo_write_out;

  assign m0_wready = !m0_wfifo_full;
  assign m1_wready = !m1_wfifo_full;

  assign m0_wfifo_push = m0_wready && m0_wvalid;
  assign m1_wfifo_push = m1_wready && m1_wvalid;

   sync_fifo #(.DEPTH(8), .DATA_WIDTH(FIFO_WORD_WIDTH)) m0_wfifo (.clk(aclk), .rstn(arst_n), .wr_en(m0_wfifo_push), .rd_en(m0_wfifo_pop), .wdata(m0_wfifo_write_in), .rdata(m0_wfifo_write_out),
          .full(m0_wfifo_full), .empty(m0_wfifo_empty));

  sync_fifo #(.DEPTH(8), .DATA_WIDTH(FIFO_WORD_WIDTH)) m1_wfifo (.clk(aclk), .rstn(arst_n), .wr_en(m1_wfifo_push), .rd_en(m1_wfifo_pop), .wdata(m1_wfifo_write_in), .rdata(m1_wfifo_write_out),
          .full(m1_wfifo_full), .empty(m1_wfifo_empty));

          //from FIFO, data will route to slave

//check if slave grant is locked and master owns the respective slave
          wire m0_owns_s0= s0_locked & s0_owner==(1'b0);
          wire m0_owns_s1= s1_locked & s1_owner==(1'b0);
          wire m1_owns_s0= s0_locked & s0_owner==(1'b1);
          wire m1_owns_s1= s1_locked & s1_owner==(1'b1);

//route ready according to which slave is selected

          wire m0_dest_wready= m0_owns_s0? s0_wready: m0_owns_s1? s1_wready : 1'b0;
          wire m1_dest_wready= m1_owns_s0? s0_wready: m1_owns_s1? s1_wready : 1'b0;

          logic m0_derr_active, m1_derr_active;
          logic [LEN_WIDTH-1:0] m0_derr_beats_left, m1_derr_beats_left;

always_ff @(posedge aclk or negedge arst_n) begin
    if (!arst_n) begin
        m0_derr_active     <= 1'b0;
        m0_derr_beats_left <= '0;
        m1_derr_active     <= 1'b0;
        m1_derr_beats_left <= '0;
    end else begin
        // m0
        if (m0_fifo_pop && m0_decode_error_saved) begin
            m0_derr_active     <= 1'b1;
            m0_derr_beats_left <= m0_fifo_awlen;
        end else if (m0_derr_active && m0_wfifo_pop) begin
            if (m0_derr_beats_left == 0)
                m0_derr_active <= 1'b0;
            else
                m0_derr_beats_left <= m0_derr_beats_left - 1;
        end

        // m1
        if (m1_fifo_pop && m1_decode_error_saved) begin
            m1_derr_active     <= 1'b1;
            m1_derr_beats_left <= m1_fifo_awlen;
        end else if (m1_derr_active && m1_wfifo_pop) begin
            if (m1_derr_beats_left == 0)
                m1_derr_active <= 1'b0;
            else
                m1_derr_beats_left <= m1_derr_beats_left - 1;
        end
    end
end

          assign m0_wfifo_pop = !m0_wfifo_empty && (m0_dest_wready || m0_derr_active);
          assign m1_wfifo_pop = !m1_wfifo_empty && (m1_dest_wready || m1_derr_active);

//drive data to slave
          assign m0_wfifo_wstrb=m0_wfifo_write_out[STROBE_WIDTH-1:0];
          assign m0_wfifo_wlast=m0_wfifo_write_out[STROBE_WIDTH];
          assign m0_wfifo_wdata=m0_wfifo_write_out[FIFO_WORD_WIDTH-1:STROBE_WIDTH+1];

          assign m1_wfifo_wstrb=m1_wfifo_write_out[STROBE_WIDTH-1:0];
          assign m1_wfifo_wlast=m1_wfifo_write_out[STROBE_WIDTH];
          assign m1_wfifo_wdata=m1_wfifo_write_out[FIFO_WORD_WIDTH-1:STROBE_WIDTH+1];

          assign s0_wvalid = s0_locked && (s0_owner ? !m1_wfifo_empty : !m0_wfifo_empty);
          assign s1_wvalid = s1_locked && (s1_owner ? !m1_wfifo_empty : !m0_wfifo_empty);

          assign s0_wdata= s0_locked? (s0_owner? m1_wfifo_wdata : m0_wfifo_wdata) : '0;
          assign s0_wstrb= s0_locked? (s0_owner? m1_wfifo_wstrb : m0_wfifo_wstrb) : '0;
          assign s0_wlast= s0_locked? (s0_owner? m1_wfifo_wlast : m0_wfifo_wlast) : '0;
          assign s1_wdata= s1_locked? (s1_owner? m1_wfifo_wdata : m0_wfifo_wdata) : '0;
          assign s1_wstrb= s1_locked? (s1_owner? m1_wfifo_wstrb : m0_wfifo_wstrb) : '0;
          assign s1_wlast= s1_locked? (s1_owner? m1_wfifo_wlast : m0_wfifo_wlast) : '0;

endmodule
