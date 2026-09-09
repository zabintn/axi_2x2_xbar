`timescale 1ns/1ps

module error_response_write #(parameter ID_WIDTH=4,
	parameter DATA_WIDTH=64) (
	input wire clk,
	input wire rstn,

	//error value from address decoder
	//
	input wire aw_err,
	input logic [ID_WIDTH-1:0] awid,
	input logic awvalid,
	input logic awready,
	input wire wlast, 
	input wire wvalid, 
	input wire wready,
	output reg [ID_WIDTH-1:0] bid,
	output reg [1:0] bresp,
	output reg bvalid,
	input logic bready
	);

	localparam [1:0] DECERR= 2'b11;
	logic [ID_WIDTH-1:0] error_awid;
	logic error_pending;
	always_ff @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			bvalid <= 1'b0;
			bresp  <= 2'b00;
			bid    <= '0;
			error_awid <= '0;
			error_pending<=1'b0;
		end
		else begin
			if (aw_err) begin
				error_awid <= awid;
				error_pending<=1'b1;
			end
			if (error_pending && !bvalid && wvalid &&  wready && wlast) begin
				bvalid <= 1'b1;
				bresp <= DECERR;
				bid <= error_awid[ID_WIDTH-1:0];
				error_pending<=1'b0;
			end
			if (bvalid && bready)
				bvalid <= 1'b0;
		end
	end
endmodule


