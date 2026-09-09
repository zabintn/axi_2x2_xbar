`timescale 1ns/1ps
import axi_param_pkg::*;
class driver;
	virtual axi_xbar_if axi_vif;
	transaction tr;
	mailbox gen2drv;

	function new(mailbox gen2drv, virtual axi_xbar_if axi_vif);
		this.gen2drv=gen2drv;
		this.axi_vif=axi_vif;
		$display("[%0t] DRIVER CONSTRUCTED", $time);
	endfunction

	task run;
		forever begin
			gen2drv.get(tr);

			//AW PHASE
			//
			@(posedge axi_vif.aclk);
			
			axi_vif.m0_awid <= tr.m0_awid;
			axi_vif.m0_awaddr <= tr.m0_awaddr;
			axi_vif.m0_awlen <= tr.m0_awlen;
			axi_vif.m0_awsize <= tr.m0_awsize;
			axi_vif.m0_awburst <= tr.m0_awburst;
			axi_vif.m0_awvalid <= 1'b1;

			do @(posedge axi_vif.aclk); 
				while (axi_vif.m0_awready==0);
			
			axi_vif.m0_awvalid <= 1'b0;
			@(posedge axi_vif.aclk);

			//W PHASE

			axi_vif.m0_wdata <= tr.m0_wdata;
			axi_vif.m0_wstrb <= tr.m0_wstrb;
			axi_vif.m0_wlast <= tr.m0_wlast;
			axi_vif.m0_wvalid <= 1'b1;

			do @(posedge axi_vif.aclk);
				while (axi_vif.m0_wready==0);

			axi_vif.m0_wvalid <= 1'b0;

			//B PHASE
			
			axi_vif.s0_bid <=  tr.s0_bid;
			axi_vif.s0_bresp <= tr.s0_bresp;
			axi_vif.s0_bvalid <= 1'b1;

			do @(posedge axi_vif.aclk);
				while (axi_vif.s0_bready==0);

			axi_vif.s0_bvalid <= 1'b0;

			tr.display("DRIVER");
		end
	endtask
endclass



