`timescale 1ns/1ps

module read_error #(
    parameter ID_WIDTH   = 4,
    parameter DATA_WIDTH = 64,
    parameter LEN_WIDTH  = 8
) (
    input  wire                  clk,
    input  wire                  rstn,

    // Error value from address decoder
    input  wire                  ar_err,

    // AR channel
    input  logic [ID_WIDTH-1:0]  arid,
    input  logic                 arvalid,
    input  logic                 arready,
    input  logic [LEN_WIDTH-1:0] arlen,

    // R channel
    output reg   [ID_WIDTH-1:0]  rid,
    output reg   [DATA_WIDTH-1:0] rdata,
    output reg   [1:0]           rresp,
    output reg                   rlast,
    output reg                   rvalid,
    input  wire                  rready
);

    localparam [1:0] DECERR = 2'b11;

    reg [ID_WIDTH-1:0]  error_arid;
    reg [LEN_WIDTH-1:0] error_arlen;
    reg [LEN_WIDTH-1:0] r_count;


    always_ff @(posedge clk or negedge rstn) begin

        if (!rstn) begin

            rvalid      <= 1'b0;
            rdata       <= '0;
            rresp       <= 2'b00;
            rid         <= '0;
            rlast       <= 1'b0;

            error_arid  <= '0;
            error_arlen <= '0;
            r_count     <= '0;

        end
        else begin

            // Capture a read request that generated DECERR
            if (ar_err && !rvalid) begin

                error_arid  <= arid;
                error_arlen <= arlen;
                r_count     <= '0;

                rvalid <= 1'b1;
                rdata  <= '0;
                rresp  <= DECERR;
                rid    <= arid;

                if (arlen == 0)
                    rlast <= 1'b1;
                else
                    rlast <= 1'b0;

            end


            // Current DECERR response beat accepted
            if (rvalid && rready) begin

                if (r_count == error_arlen) begin

                    // Last beat completed
                    rvalid <= 1'b0;
                    rlast  <= 1'b0;

                end
                else begin

                    // Generate next error response beat
                    r_count <= r_count + 1'b1;

                    rvalid <= 1'b1;
                    rid    <= error_arid;
                    rdata  <= '0;
                    rresp  <= DECERR;

                    if ((r_count + 1'b1) == error_arlen)
                        rlast <= 1'b1;
                    else
                        rlast <= 1'b0;

                end
            end

        end                 
    end                     

endmodule

