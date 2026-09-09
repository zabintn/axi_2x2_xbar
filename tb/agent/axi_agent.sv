`timescale 1ns/1ps

import axi_param_pkg::*;
class agent;
	master_driver mdrv0, mdrv1;
	slave_driver slv;
	master_monitor mmon0, mmon1;
	slave_monitor smon0, smon1;
	arb_monitor amon;
	generator gen;

	mailbox gen2drv0, gen2drv1;
	mailbox mon2sb_s, mon2sb_m;
	mailbox mon2sb_arb;

	virtual axi_xbar_if axi_vif;

	function new(mailbox mon2sb_m, mailbox mon2sb_s, mailbox mon2sb_arb, virtual axi_xbar_if axi_vif);
		this.mon2sb_m=mon2sb_m;
		this.mon2sb_s=mon2sb_s;
		this.mon2sb_arb=mon2sb_arb;
		this.axi_vif=axi_vif;

		gen2drv0=new();
		gen2drv1=new();

		mdrv0=new(0, axi_vif, gen2drv0);
		mdrv1=new(1, axi_vif, gen2drv1);
		slv=new(axi_vif);
		mmon0=new(0, mon2sb_m, axi_vif);
		mmon1=new(1, mon2sb_m, axi_vif);
		smon0=new(0, mon2sb_s, axi_vif);
		smon1=new(1, mon2sb_s, axi_vif);
		amon=new(axi_vif, mon2sb_arb);
		gen=new(gen2drv0, gen2drv1);
	endfunction

	task drive_bready();
		forever begin
			@(posedge axi_vif.aclk);
			axi_vif.m0_bready<=1'b1;
			axi_vif.m1_bready<=1'b1;
			axi_vif.m0_rready<=1'b1;
			axi_vif.m1_rready<=1'b1;
		end
	endtask

	task run();

		fork 
			mmon0.run();
			mmon1.run();
			slv.run();
			mdrv0.run();
			mdrv1.run();
			smon0.run();
			smon1.run();
			amon.run();
			drive_bready();
		join_none
	endtask
endclass
