`timescale 1ns/1ps
module sync_fifo #(
    parameter DEPTH      = 8,
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire                    clk,
    input  wire                    rstn,
    input  wire                    wr_en,
    input  wire                    rd_en,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output reg  [DATA_WIDTH-1:0]   rdata,
    output wire                    full,
    output wire                    empty
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0]   wptr, rptr;

    // write logic + read logic (independent, can happen same cycle)
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wptr <= 0;
            rptr <= 0;
        end
        else begin
            if (wr_en && !full) begin
                mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
                wptr <= wptr + 1;
            end
            if (rd_en && !empty) begin
                rdata <= mem[rptr[ADDR_WIDTH-1:0]];
                rptr  <= rptr + 1;
            end
        end
    end

    // full/empty flags
    assign empty = (wptr == rptr);
    assign full  = (wptr[ADDR_WIDTH] != rptr[ADDR_WIDTH]) &&
                   (wptr[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0]);

endmodule

