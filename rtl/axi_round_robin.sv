`timescale 1ns/1ps

module rr_arbiter #(
    parameter NUM_REQ = 2
) (
    input  wire                 clk,
    input  wire                 resetn,
    input  wire [NUM_REQ-1:0]   req,
    input  wire                 done,
    input  wire               accept,
    output reg  [NUM_REQ-1:0]   grant,
    output reg locked,
    output reg owner

);

    logic prio;
    
    always @(*) begin

        grant = 2'b00;

        if (locked) begin
            grant[owner] = 1'b1;
        end
        else begin
            // Normal round-robin arbitration
            if (req[prio])
                grant[prio] = 1'b1;
            else if (|req)
                grant[~prio] = 1'b1;
        end

    end

    always_ff @(posedge clk or negedge resetn) begin

        if (!resetn) begin
            prio   <= 1'b0;
            locked <= 1'b0;
	    owner  <= 1'b0;
        end

        else begin

            if (!locked) begin

                if (accept) begin
                    locked <= 1'b1;

                    if (req[prio])
                        owner <= prio;
                    else
                        owner <= ~prio;
                end
            end

            else if (done) begin

                locked <= 1'b0;
                if (owner==1'b0)
                    prio <= 1'b1;
                else if (owner==1'b1)
                    prio <= 1'b0;

            end
        end
    end

endmodule
