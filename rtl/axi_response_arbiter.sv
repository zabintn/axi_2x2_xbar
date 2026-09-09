`timescale 1ns/1ps
module fixed_priority_arbiter (

        input  wire clk,
        input  wire rst_n,
        input  wire err_valid,
        input  wire s0_valid,
	input  wire s1_valid,
	input  wire last_i,
// 2'b00 = none, 2'b01 = error, 2'b10 = slave0, 2'b11 = slave1
        output reg  [1:0]              S0_grant
        );

localparam GNT_NONE = 2'b00;
localparam GNT_ERR  = 2'b01;
localparam GNT_S0   = 2'b10;
localparam GNT_S1   = 2'b11;
reg [1:0] gnt_next;
reg busy;
always @(*) begin
    if (busy && !last_i) begin
        gnt_next = S0_grant;
    end
    else if (busy && last_i) begin
        gnt_next = GNT_NONE;   // release current grant
    end
    else begin
        if (err_valid)
            gnt_next = GNT_ERR;
        else if (s0_valid)
            gnt_next = GNT_S0;
        else if (s1_valid)
            gnt_next = GNT_S1;
        else
            gnt_next = GNT_NONE;
    end
end
//registered grant
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
                S0_grant <= GNT_NONE;
		busy <= 1'b0;
	end
	else begin
                S0_grant <= gnt_next;
		if (busy) begin
			if(last_i)
				busy <= (gnt_next != GNT_NONE);
		end
		else begin
			busy <= (gnt_next != GNT_NONE);
		end

	end			
end
endmodule
