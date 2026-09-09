`timescale 1ns/1ps

import axi_param_pkg::*;
class master_monitor;
	int unsigned master_id;
	mailbox mon2sb_m;
	virtual axi_xbar_if axi_vif;

function new(int unsigned master_id, mailbox mon2sb_m, virtual axi_xbar_if axi_vif); 
	this.master_id=master_id;
	this.mon2sb_m=mon2sb_m;
	this.axi_vif=axi_vif;
	$display("[%0t] MASTER MONITOR CONSTRUCTED", $time);
endfunction

task run();

	fork 
		monitor_write();
		monitor_read();
	join_none
endtask
task monitor_write();
	wait (axi_vif.arst_n === 1'b1);

	forever begin
		transaction tr;
		bit [DATA_WIDTH-1:0]   wdata_q[$];
		bit [DATA_WIDTH/8-1:0] wstrb_q[$];
		bit wlast_seen;
		int beat_cnt;

		tr = new();
		tr.axi_op    = AXI_WRITE;
		tr.master_id = master_id;

		//AW PHASE
		if(master_id==0) begin
			do @(posedge axi_vif.aclk);
			while ((axi_vif.m0_awvalid && axi_vif.m0_awready) !== 1'b1);
			$display("[%0t] MASTER 0 AW_VALID_RDY Handshake", $time);
			tr.m_awid=axi_vif.m0_awid;
			tr.m_awaddr=axi_vif.m0_awaddr;
			tr.m_awlen=axi_vif.m0_awlen;
			tr.m_awsize=axi_vif.m0_awsize;
			tr.m_awburst=axi_vif.m0_awburst;
		end
		else begin
			do @(posedge axi_vif.aclk);
			while ((axi_vif.m1_awvalid && axi_vif.m1_awready) !== 1'b1);
			$display("[%0t] MASTER 1 AW_VALID_RDY Handshake", $time);
			tr.m_awid=axi_vif.m1_awid;
			tr.m_awaddr=axi_vif.m1_awaddr;
			tr.m_awlen=axi_vif.m1_awlen;
			tr.m_awsize=axi_vif.m1_awsize;
			tr.m_awburst=axi_vif.m1_awburst;
		end
		fork
			capture_slave_id(tr);
		join_none

		//W phase
		wlast_seen=1'b0;
		beat_cnt=0;
		wdata_q.delete();
		wstrb_q.delete();

		if(master_id==0) begin
			while(!wlast_seen) begin
				do @(posedge axi_vif.aclk);
				while ((axi_vif.m0_wvalid && axi_vif.m0_wready) !== 1'b1);
				 wdata_q.push_back(axi_vif.m0_wdata);
			 	 wstrb_q.push_back(axi_vif.m0_wstrb);
			   	 wlast_seen=axi_vif.m0_wlast;	 
			$display("[%0t] MASTER 0 W_VALID_RDY Handshake beat=%0d wlast=%0b", $time, beat_cnt, axi_vif.m0_wlast);
			beat_cnt++;
			end
		end
		else begin	
			while(!wlast_seen) begin
				do @(posedge axi_vif.aclk);
				while ((axi_vif.m1_wvalid && axi_vif.m1_wready) !== 1'b1);
				 wdata_q.push_back(axi_vif.m1_wdata);
			 	 wstrb_q.push_back(axi_vif.m1_wstrb);
			   	 wlast_seen=axi_vif.m1_wlast;	 
			$display("[%0t] MASTER 1 W_VALID_RDY Handshake beat=%0d wlast=%0b", $time, beat_cnt, axi_vif.m1_wlast);
			beat_cnt++;
			end
		end
		tr.m_wdata=wdata_q;
		tr.m_wstrb=wstrb_q;

		fork
			begin
				if(tr.master_id==0) begin	
					do @(posedge axi_vif.aclk);
					while (!((axi_vif.m0_bvalid && axi_vif.m0_bready) && (axi_vif.m0_bid == tr.m_awid)));
					$display("[%0t] MASTER 0 B_VALID_RDY Handshake", $time);
					tr.bid=axi_vif.m0_bid;
					tr.bresp=axi_vif.m0_bresp;
				end
				else begin
					do @(posedge axi_vif.aclk);
					while (!((axi_vif.m1_bvalid && axi_vif.m1_bready) && (axi_vif.m1_bid == tr.m_awid)));
					$display("[%0t] MASTER 1 B_VALID_RDY Handshake", $time);
					tr.bid=axi_vif.m1_bid;
					tr.bresp=axi_vif.m1_bresp;
				end
				wait fork; // wait for this tr's capture_slave_id (above) to finish too
				tr.display("MASTER MONITOR");
				mon2sb_m.put(tr);
			end
		join_none
	end
endtask
task monitor_read();
	wait (axi_vif.arst_n === 1'b1);

	forever begin
		transaction tr;

		tr = new();
		tr.master_id = master_id;
		tr.axi_op    = AXI_READ;

		//AR PHASE
		if(master_id==0) begin
			do @(posedge axi_vif.aclk);
			while ((axi_vif.m0_arvalid && axi_vif.m0_arready) !== 1'b1);
			tr.m_arid=axi_vif.m0_arid;
			tr.m_araddr=axi_vif.m0_araddr;
			tr.m_arlen=axi_vif.m0_arlen;
			tr.m_arsize=axi_vif.m0_arsize;
			tr.m_arburst=axi_vif.m0_arburst;
		end
		else begin
			do @(posedge axi_vif.aclk);
			while ((axi_vif.m1_arvalid && axi_vif.m1_arready) !== 1'b1);
			tr.m_arid=axi_vif.m1_arid;
			tr.m_araddr=axi_vif.m1_araddr;
			tr.m_arlen=axi_vif.m1_arlen;
			tr.m_arsize=axi_vif.m1_arsize;
			tr.m_arburst=axi_vif.m1_arburst;
		end

		fork
			begin
				bit [DATA_WIDTH-1:0] rdata_q[$];
				bit [1:0]            rresp_q[$];
				bit [TAG_WIDTH-1:0]  rid_q[$];
				bit rlast_seen;
				int beat_cnt;

				rlast_seen = 1'b0;
				beat_cnt   = 0;
				rdata_q.delete();
				rresp_q.delete();
				rid_q.delete();

				fork
					capture_read_slave_id(tr);
					begin
						if(tr.master_id==0) begin
							while(!rlast_seen) begin
								do @(posedge axi_vif.aclk);
								while(!((axi_vif.m0_rvalid && axi_vif.m0_rready) && (axi_vif.m0_rid == tr.m_arid)));
								rid_q.push_back(axi_vif.m0_rid);
								rresp_q.push_back(axi_vif.m0_rresp);
								rdata_q.push_back(axi_vif.m0_rdata);
								rlast_seen=axi_vif.m0_rlast;
							$display("[%0t] MASTER 0 R_VALID_RDY Handshake beat=%0d rlast=%0b", $time, beat_cnt, axi_vif.m0_rlast);
							beat_cnt++;
							end
						end
						else begin
							while(!rlast_seen) begin
								do @(posedge axi_vif.aclk);
								while(!((axi_vif.m1_rvalid && axi_vif.m1_rready) && (axi_vif.m1_rid == tr.m_arid)));
								rid_q.push_back(axi_vif.m1_rid);
								rresp_q.push_back(axi_vif.m1_rresp);
								rdata_q.push_back(axi_vif.m1_rdata);
								rlast_seen=axi_vif.m1_rlast;
							$display("[%0t] MASTER 1 R_VALID_RDY Handshake beat=%0d rlast=%0b", $time, beat_cnt, axi_vif.m1_rlast);
							beat_cnt++;
							end
						end
					end
				join

				tr.rdata=rdata_q;
				tr.rresp=rresp_q;
				tr.rid=rid_q;
				tr.display("MASTER MONITOR");
				mon2sb_m.put(tr);
			end
		join_none
	end
endtask
task capture_slave_id(transaction tr);
	logic [TAG_WIDTH-1:0] expected_tagged_id;
	expected_tagged_id = {tr.master_id, tr.m_awid};
	forever begin
		@(posedge axi_vif.aclk);
		if(tr.master_id==0 && axi_vif.m0_decode_error==1) begin
			tr.decode_err=1'b1;
			return;
		end
		if(tr.master_id==1 && axi_vif.m1_decode_error==1) begin
			tr.decode_err=1'b1;
			return;
		end

		if ((axi_vif.s0_awvalid &&
			axi_vif.s0_awready) === 1'b1 &&
			axi_vif.s0_awid === expected_tagged_id) begin
			tr.slave_id = 1'b0;
			return;
		end
		if ((axi_vif.s1_awvalid &&
			axi_vif.s1_awready) === 1'b1 &&
			axi_vif.s1_awid === expected_tagged_id) begin
			tr.slave_id = 1'b1;
			return;
		end

	end
endtask
task capture_read_slave_id(transaction tr);
	logic [TAG_WIDTH-1:0] expected_tagged_id;
	expected_tagged_id = {tr.master_id, tr.m_arid};
	forever begin
		@(posedge axi_vif.aclk);
		if(tr.master_id==0 && axi_vif.m0_rdecode_error==1) begin
			tr.decode_err=1'b1;
			return;
		end
		if(tr.master_id==1 && axi_vif.m1_rdecode_error==1) begin
			tr.decode_err=1'b1;
			return;
		end

		if ((axi_vif.s0_arvalid &&
			axi_vif.s0_arready) === 1'b1 &&
			axi_vif.s0_arid === expected_tagged_id) begin
			tr.slave_id = 1'b0;
			return;
		end
		if ((axi_vif.s1_arvalid &&
			axi_vif.s1_arready) === 1'b1 &&
			axi_vif.s1_arid === expected_tagged_id) begin
			tr.slave_id = 1'b1;
			return;
		end
	end
endtask


endclass

