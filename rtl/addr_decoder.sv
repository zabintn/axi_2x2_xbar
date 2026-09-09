`timescale 1ns/1ps

module addr_decoder #(parameter ADDR_WIDTH=32, 
	parameter s0_lower=32'h00000000,
	parameter s0_upper=32'h0FFFFFFF,
	parameter s1_lower=32'h10000000,
	parameter s1_upper=32'h1FFFFFFF
		)( input wire [ADDR_WIDTH-1:0] address,
		   output reg [1:0] slave_sel,
		   output reg error
		   );


//check if address is valid
	always @(*) begin
		if (address>= s0_lower && address <= s0_upper) begin
		       	slave_sel=2'b00;
			error=0;
		end
		else if (address>= s1_lower && address <=s1_upper) begin
			slave_sel=2'b01;
			error=0;
		end
		else begin 
			slave_sel=2'b11;
			error=1;
		end
	end

endmodule

		   	 
