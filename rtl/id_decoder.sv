`timescale 1ns/1ps

module id_decoder #(parameter ID_WIDTH=4) (
	input wire [ID_WIDTH:0] id_tagged,
	output reg [ID_WIDTH-1:0] id_stripped,
	output reg master_sel
	);


	//take top bit and store it in master_sel
	
	always @(*) begin
		master_sel=id_tagged[ID_WIDTH];
		id_stripped=id_tagged[ID_WIDTH-1:0]; //store stripped id in id_stripped
	end
	endmodule
