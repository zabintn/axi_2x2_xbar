`timescale 1ns/1ps

module axi_rchannel #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64,
    parameter ID_WIDTH   = 4,
    parameter TAG_WIDTH  = ID_WIDTH + 1,
    parameter LEN_WIDTH  = 8,
    parameter SIZE_WIDTH = 3,
    parameter BURST_TYPE = 2
) (
    input  wire                     aclk,
    input  wire                     arst_n,

    input  wire                     m0_rdecode_error,
    input  wire                     m1_rdecode_error,

    input  wire [TAG_WIDTH-1:0]     s0_rid,
    input  wire [DATA_WIDTH-1:0]    s0_rdata,
    input  wire [1:0]               s0_rresp,
    input  wire                     s0_rlast,
    input  wire                     s0_rvalid,
    output wire                     s0_rready,

    input  wire [TAG_WIDTH-1:0]     s1_rid,
    input  wire [DATA_WIDTH-1:0]    s1_rdata,
    input  wire [1:0]               s1_rresp,
    input  wire                     s1_rlast,
    input  wire                     s1_rvalid,
    output wire                     s1_rready,

    input  wire                     m0_rready,
    input  wire                     m1_rready,

    output wire [ID_WIDTH-1:0]      m0_rid,
    output wire [DATA_WIDTH-1:0]    m0_rdata,
    output wire [1:0]               m0_rresp,
    output wire                     m0_rlast,
    output wire                     m0_rvalid,

    output wire [ID_WIDTH-1:0]      m1_rid,
    output wire [DATA_WIDTH-1:0]    m1_rdata,
    output wire [1:0]               m1_rresp,
    output wire                     m1_rlast,
    output wire                     m1_rvalid,

    input  wire                     s0_arvalid,
    input  wire                     s0_arready,
    input  wire                     s1_arvalid,
    input  wire                     s1_arready,

    input  wire [ID_WIDTH-1:0]     m0_arid,
    input  wire [ID_WIDTH-1:0]     m1_arid,
    input  wire [LEN_WIDTH-1:0]     m0_arlen,
    input  wire [LEN_WIDTH-1:0]     m1_arlen,
    input  wire [TAG_WIDTH-1:0]     s0_arid,
    input  wire [TAG_WIDTH-1:0]     s1_arid
);

    localparam FIFO_WORD_WIDTH = TAG_WIDTH + DATA_WIDTH + 3;

    localparam [1:0] GRANT_NONE = 2'b00;
    localparam [1:0] GRANT_ERR  = 2'b01;
    localparam [1:0] GRANT_S0   = 2'b10;
    localparam [1:0] GRANT_S1   = 2'b11;

    wire s0_rfifo_push, s1_rfifo_push;
    wire s0_rfifo_po, s1_rfifo_pop;
    wire s0_rfifo_empty, s1_rfifo_empty;
    wire s0_rfifo_full, s1_rfifo_full;
    wire [FIFO_WORD_WIDTH-1:0]   s0_rfifo_data_in;
    wire [FIFO_WORD_WIDTH-1:0]   s1_rfifo_data_in;
    wire [FIFO_WORD_WIDTH-1:0]   s0_rfifo_data_out;
    wire [FIFO_WORD_WIDTH-1:0]   s1_rfifo_data_out;

    assign s0_rfifo_data_in = {s0_rid, s0_rdata, s0_rresp, s0_rlast};
    assign s1_rfifo_data_in = {s1_rid, s1_rdata, s1_rresp, s1_rlast};

    assign s0_rready     = !s0_rfifo_full;
    assign s1_rready     = !s1_rfifo_full;
    assign s0_rfifo_push = s0_rvalid && s0_rready;
    assign s1_rfifo_push = s1_rvalid && s1_rready;

    sync_fifo #(
        .DEPTH      (8),
        .DATA_WIDTH (FIFO_WORD_WIDTH)
    ) s0_rfifo (
        .clk   (aclk),
        .rstn  (arst_n),
        .wr_en (s0_rfifo_push),
        .rd_en (s0_rfifo_pop),
        .wdata (s0_rfifo_data_in),
        .rdata (s0_rfifo_data_out),
        .full  (s0_rfifo_full),
        .empty (s0_rfifo_empty)
    );

    sync_fifo #(
        .DEPTH      (8),
        .DATA_WIDTH (FIFO_WORD_WIDTH)
    ) s1_rfifo (
        .clk   (aclk),
        .rstn  (arst_n),
        .wr_en (s1_rfifo_push),
        .rd_en (s1_rfifo_pop),
        .wdata (s1_rfifo_data_in),
        .rdata (s1_rfifo_data_out),
        .full  (s1_rfifo_full),
        .empty (s1_rfifo_empty)
    );

    wire [TAG_WIDTH-1:0]  s0_rfifo_tag;
    wire [TAG_WIDTH-1:0]  s1_rfifo_tag;
    wire [ID_WIDTH-1:0]   s0_rfifo_rid;
    wire [ID_WIDTH-1:0]   s1_rfifo_rid;
    wire [DATA_WIDTH-1:0] s0_rfifo_rdata;
    wire [DATA_WIDTH-1:0] s1_rfifo_rdata;
    wire [1:0]            s0_rfifo_rresp;
    wire [1:0]            s1_rfifo_rresp;
    wire                  s0_rfifo_rlast;
    wire                  s1_rfifo_rlast;

    assign s0_rfifo_rlast = s0_rfifo_data_out[0];
    assign s0_rfifo_rresp = s0_rfifo_data_out[2:1];
    assign s0_rfifo_rdata = s0_rfifo_data_out[DATA_WIDTH+2:3];
    assign s0_rfifo_tag   = s0_rfifo_data_out[FIFO_WORD_WIDTH-1 -: TAG_WIDTH];
    assign s0_rfifo_rid   = s0_rfifo_tag[ID_WIDTH-1:0];

    assign s1_rfifo_rlast = s1_rfifo_data_out[0];
    assign s1_rfifo_rresp = s1_rfifo_data_out[2:1];
    assign s1_rfifo_rdata = s1_rfifo_data_out[DATA_WIDTH+2:3];
    assign s1_rfifo_tag   = s1_rfifo_data_out[FIFO_WORD_WIDTH-1 -: TAG_WIDTH];
    assign s1_rfifo_rid   = s1_rfifo_tag[ID_WIDTH-1:0];

    wire s0_req_m0;
    wire s0_req_m1;
    wire s1_req_m0;
    wire s1_req_m1;

    assign s0_req_m0 = !s0_rfifo_empty && (s0_rfifo_tag[TAG_WIDTH-1] == 1'b0);
    assign s0_req_m1 = !s0_rfifo_empty && (s0_rfifo_tag[TAG_WIDTH-1] == 1'b1);
    assign s1_req_m0 = !s1_rfifo_empty && (s1_rfifo_tag[TAG_WIDTH-1] == 1'b0);
    assign s1_req_m1 = !s1_rfifo_empty && (s1_rfifo_tag[TAG_WIDTH-1] == 1'b1);

    reg                       m0_error_active;
    reg                       m1_error_active;
    reg [ID_WIDTH-1:0]        m0_error_rid_reg;
    reg [ID_WIDTH-1:0]        m1_error_rid_reg;
    reg [LEN_WIDTH-1:0]       m0_error_beats_left;
    reg [LEN_WIDTH-1:0]       m1_error_beats_left;

    wire [ID_WIDTH-1:0]       m0_error_rid;
    wire [ID_WIDTH-1:0]       m1_error_rid;
    wire [DATA_WIDTH-1:0]     m0_error_rdata;
    wire [DATA_WIDTH-1:0]     m1_error_rdata;
    wire [1:0]                m0_error_rresp;
    wire [1:0]                m1_error_rresp;
    wire                      m0_error_rlast;
    wire                      m1_error_rlast;
    wire                      m0_error_rvalid;
    wire                      m1_error_rvalid;
    wire                      m0_error_rready;
    wire                      m1_error_rready;

    assign m0_error_rid    = m0_error_rid_reg;
    assign m1_error_rid    = m1_error_rid_reg;
    assign m0_error_rdata  = {DATA_WIDTH{1'b0}};
    assign m1_error_rdata  = {DATA_WIDTH{1'b0}};
    assign m0_error_rresp  = 2'b11; // DECERR
    assign m1_error_rresp  = 2'b11; // DECERR
    assign m0_error_rlast  = (m0_error_beats_left == {LEN_WIDTH{1'b0}});
    assign m1_error_rlast  = (m1_error_beats_left == {LEN_WIDTH{1'b0}});
    assign m0_error_rvalid = m0_error_active;
    assign m1_error_rvalid = m1_error_active;

    always @(posedge aclk or negedge arst_n) begin
        if (!arst_n) begin
            m0_error_active     <= 1'b0;
            m0_error_rid_reg    <= {ID_WIDTH{1'b0}};
            m0_error_beats_left <= {LEN_WIDTH{1'b0}};
        end else begin
            if (m0_error_rvalid && m0_error_rready) begin
                if (m0_error_rlast) begin
                    m0_error_active <= 1'b0;
                end else begin
                    m0_error_beats_left <= m0_error_beats_left - 1'b1;
                end
            end

            if (m0_rdecode_error &&
                (!m0_error_active ||
                 (m0_error_rvalid && m0_error_rready && m0_error_rlast))) begin
                m0_error_active     <= 1'b1;
                m0_error_rid_reg    <= m0_arid[ID_WIDTH-1:0];
                m0_error_beats_left <= m0_arlen;
            end
        end
    end

    always @(posedge aclk or negedge arst_n) begin
        if (!arst_n) begin
            m1_error_active     <= 1'b0;
            m1_error_rid_reg    <= {ID_WIDTH{1'b0}};
            m1_error_beats_left <= {LEN_WIDTH{1'b0}};
        end else begin
            if (m1_error_rvalid && m1_error_rready) begin
                if (m1_error_rlast) begin
                    m1_error_active <= 1'b0;
                end else begin
                    m1_error_beats_left <= m1_error_beats_left - 1'b1;
                end
            end

            if (m1_rdecode_error &&
                (!m1_error_active ||
                 (m1_error_rvalid && m1_error_rready && m1_error_rlast))) begin
                m1_error_active     <= 1'b1;
                m1_error_rid_reg    <= m1_arid[ID_WIDTH-1:0];
                m1_error_beats_left <= m1_arlen;
            end
        end
    end

    /* Fixed priority is error, slave 0, then slave 1. */
    wire [1:0] m0_grant;
    wire [1:0] m1_grant;

    fixed_priority_arbiter m0_response_arbiter (
        .clk       (aclk),
        .rst_n     (arst_n),
        .err_valid (m0_error_rvalid),
        .s0_valid  (s0_req_m0),
        .s1_valid  (s1_req_m0),
        .S0_grant  (m0_grant)
    );

    fixed_priority_arbiter m1_response_arbiter (
        .clk       (aclk),
        .rst_n     (arst_n),
        .err_valid (m1_error_rvalid),
        .s0_valid  (s0_req_m1),
        .s1_valid  (s1_req_m1),
        .S0_grant  (m1_grant)
    );

    assign m0_rid = (m0_grant == GRANT_S0) ? s0_rfifo_rid :
                    (m0_grant == GRANT_S1) ? s1_rfifo_rid : m0_error_rid;
    assign m0_rdata = (m0_grant == GRANT_S0) ? s0_rfifo_rdata :
                      (m0_grant == GRANT_S1) ? s1_rfifo_rdata : m0_error_rdata;
    assign m0_rresp = (m0_grant == GRANT_S0) ? s0_rfifo_rresp :
                      (m0_grant == GRANT_S1) ? s1_rfifo_rresp : m0_error_rresp;
    assign m0_rlast = (m0_grant == GRANT_S0) ? s0_rfifo_rlast :
                      (m0_grant == GRANT_S1) ? s1_rfifo_rlast : m0_error_rlast;
    assign m0_rvalid = (m0_grant == GRANT_ERR) ? m0_error_rvalid :
                       (m0_grant == GRANT_S0)  ? s0_req_m0 :
                       (m0_grant == GRANT_S1)  ? s1_req_m0 : 1'b0;

    assign m1_rid = (m1_grant == GRANT_S0) ? s0_rfifo_rid :
                    (m1_grant == GRANT_S1) ? s1_rfifo_rid : m1_error_rid;
    assign m1_rdata = (m1_grant == GRANT_S0) ? s0_rfifo_rdata :
                      (m1_grant == GRANT_S1) ? s1_rfifo_rdata : m1_error_rdata;
    assign m1_rresp = (m1_grant == GRANT_S0) ? s0_rfifo_rresp :
                      (m1_grant == GRANT_S1) ? s1_rfifo_rresp : m1_error_rresp;
    assign m1_rlast = (m1_grant == GRANT_S0) ? s0_rfifo_rlast :
                      (m1_grant == GRANT_S1) ? s1_rfifo_rlast : m1_error_rlast;
    assign m1_rvalid = (m1_grant == GRANT_ERR) ? m1_error_rvalid :
                       (m1_grant == GRANT_S0)  ? s0_req_m1 :
                       (m1_grant == GRANT_S1)  ? s1_req_m1 : 1'b0;

    assign m0_error_rready = (m0_grant == GRANT_ERR) && m0_rready;
    assign m1_error_rready = (m1_grant == GRANT_ERR) && m1_rready;

    assign s0_rfifo_pop = ((m0_grant == GRANT_S0) && m0_rvalid && m0_rready) ||
                          ((m1_grant == GRANT_S0) && m1_rvalid && m1_rready);
    assign s1_rfifo_pop = ((m0_grant == GRANT_S1) && m0_rvalid && m0_rready) ||
                          ((m1_grant == GRANT_S1) && m1_rvalid && m1_rready);

endmodule

