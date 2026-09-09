`timescale 1ns/1ps
import axi_param_pkg::*;
import axi_env_pkg::*;
import axi_test_lib_pkg::*;
module tb_top;

	//clock generation
	
	base_test test;
	write_path_test wt;
	burst_write_test bwt;
	read_path_test rt;
	arb_test at;
	error_test et;
	write_read_test wrt;
	no_contention_test noc;
	partial_contention_test pc;
	multi_test mt;
	reset_test rst;

	axi_xbar_if axi_vif();

	initial begin
		axi_vif.aclk=1'b0;
	end
	always #5 axi_vif.aclk = ~axi_vif.aclk;
	
	axi_xbar_top DUT (.aclk(axi_vif.aclk), 
		.arst_n(axi_vif.arst_n), 
		.m0_awaddr(axi_vif.m0_awaddr), 
		.m0_awid(axi_vif.m0_awid),
		.m0_awlen(axi_vif.m0_awlen), .m0_awsize(axi_vif.m0_awsize),
		.m0_awburst(axi_vif.m0_awburst), .m0_awvalid(axi_vif.m0_awvalid),
		.m0_awready(axi_vif.m0_awready),
		.m0_slave_sel(axi_vif.m0_slave_sel),
		.m1_awaddr(axi_vif.m1_awaddr), .m1_awid(axi_vif.m1_awid),
		.m1_awlen(axi_vif.m1_awlen), .m1_awsize(axi_vif.m1_awsize),
		.m1_awburst(axi_vif.m1_awburst), .m1_awvalid(axi_vif.m1_awvalid),
		.m1_awready(axi_vif.m1_awready),
		.m1_slave_sel(axi_vif.m1_slave_sel),
		.s0_awaddr(axi_vif.s0_awaddr), .s0_awid(axi_vif.s0_awid),
		.s0_awlen(axi_vif.s0_awlen), .s0_awsize(axi_vif.s0_awsize),
		.s0_awburst(axi_vif.s0_awburst), .s0_awready(axi_vif.s0_awready),
		.s0_awvalid(axi_vif.s0_awvalid),
		.s1_awaddr(axi_vif.s1_awaddr), .s1_awid(axi_vif.s1_awid),
		.s1_awlen(axi_vif.s1_awlen), .s1_awsize(axi_vif.s1_awsize),
		.s1_awburst(axi_vif.s1_awburst), .s1_awready(axi_vif.s1_awready),
		.s1_awvalid(axi_vif.s1_awvalid), .m0_decode_error(axi_vif.m0_decode_error), .m1_decode_error(axi_vif.m1_decode_error),
		.m0_wdata(axi_vif.m0_wdata), .m0_wstrb(axi_vif.m0_wstrb), 
		.m0_wlast(axi_vif.m0_wlast),
		.m0_wvalid(axi_vif.m0_wvalid), .m0_wready(axi_vif.m0_wready),	
		.m1_wdata(axi_vif.m1_wdata), .m1_wstrb(axi_vif.m1_wstrb), 
		.m1_wlast(axi_vif.m1_wlast),
		.m1_wvalid(axi_vif.m1_wvalid), .m1_wready(axi_vif.m1_wready),
		.s0_wvalid(axi_vif.s0_wvalid), .s1_wvalid(axi_vif.s1_wvalid),
		.s0_wready(axi_vif.s0_wready), .s1_wready(axi_vif.s1_wready),
		.s0_wdata(axi_vif.s0_wdata), .s0_wstrb(axi_vif.s0_wstrb),.s0_wlast(axi_vif.s0_wlast),
		.s1_wdata(axi_vif.s1_wdata), .s1_wstrb(axi_vif.s1_wstrb), .s1_wlast(axi_vif.s1_wlast),
		.m0_bid(axi_vif.m0_bid), .m0_bresp(axi_vif.m0_bresp), 
		.m0_bvalid(axi_vif.m0_bvalid), .m0_bready(axi_vif.m0_bready),
		.s0_bresp(axi_vif.s0_bresp), .s0_bvalid(axi_vif.s0_bvalid), 
		.s0_bready(axi_vif.s0_bready), .s0_bid(axi_vif.s0_bid),	
		.m1_bid(axi_vif.m1_bid), .m1_bresp(axi_vif.m1_bresp), 
		.m1_bvalid(axi_vif.m1_bvalid), .m1_bready(axi_vif.m1_bready),
		.s1_bresp(axi_vif.s1_bresp), .s1_bvalid(axi_vif.s1_bvalid),
		.s1_bready(axi_vif.s1_bready), .s1_bid(axi_vif.s1_bid), 
		.m0_araddr(axi_vif.m0_araddr), 
		.m0_arid(axi_vif.m0_arid),
		.m0_arlen(axi_vif.m0_arlen), 
		.m0_arsize(axi_vif.m0_arsize), 
		.m0_arburst(axi_vif.m0_arburst), 
		.m0_arvalid(axi_vif.m0_arvalid), 
		.m0_arready(axi_vif.m0_arready),		
		.m1_araddr(axi_vif.m1_araddr), 
		.m1_arid(axi_vif.m1_arid),
		.m1_arlen(axi_vif.m1_arlen), 
		.m1_arsize(axi_vif.m1_arsize), 
		.m1_arburst(axi_vif.m1_arburst), 
		.m1_arvalid(axi_vif.m1_arvalid), 
		.m1_arready(axi_vif.m1_arready),	
		.s0_araddr(axi_vif.s0_araddr), 
		.s0_arid(axi_vif.s0_arid),
		.s0_arlen(axi_vif.s0_arlen), 
		.s0_arsize(axi_vif.s0_arsize), 
		.s0_arburst(axi_vif.s0_arburst), 
		.s0_arvalid(axi_vif.s0_arvalid), 
		.s0_arready(axi_vif.s0_arready),		
		.s1_araddr(axi_vif.s1_araddr), 
		.s1_arid(axi_vif.s1_arid),
		.s1_arlen(axi_vif.s1_arlen), 
		.s1_arsize(axi_vif.s1_arsize), 
		.s1_arburst(axi_vif.s1_arburst), 
		.s1_arvalid(axi_vif.s1_arvalid), 
		.s1_arready(axi_vif.s1_arready),
		.s0_rlast(axi_vif.s0_rlast), 
		.s1_rlast(axi_vif.s1_rlast),
		.s0_rlocked(axi_vif.s0_rlocked),
                .s0_rowner(axi_vif.s0_rowner),
                .s1_rlocked(axi_vif.s1_rlocked),
                .s1_rowner(axi_vif.s1_rowner),

                .m0_rdecode_error(axi_vif.m0_rdecode_error),
                .m1_rdecode_error(axi_vif.m1_rdecode_error),

                .s0_rid(axi_vif.s0_rid),
                .s0_rdata(axi_vif.s0_rdata),
                .s0_rresp(axi_vif.s0_rresp),
                .s0_rvalid(axi_vif.s0_rvalid),
                .s0_rready(axi_vif.s0_rready),

                .s1_rid(axi_vif.s1_rid),
                .s1_rdata(axi_vif.s1_rdata),
                .s1_rresp(axi_vif.s1_rresp),
                .s1_rvalid(axi_vif.s1_rvalid),
                .s1_rready(axi_vif.s1_rready),

                .m0_rready(axi_vif.m0_rready),
                .m1_rready(axi_vif.m1_rready),

                .m0_rid(axi_vif.m0_rid),
                .m0_rdata(axi_vif.m0_rdata),
                .m0_rresp(axi_vif.m0_rresp),
                .m0_rlast(axi_vif.m0_rlast),
                .m0_rvalid(axi_vif.m0_rvalid),

                .m1_rid(axi_vif.m1_rid),
                .m1_rdata(axi_vif.m1_rdata),
                .m1_rresp(axi_vif.m1_rresp),
                .m1_rlast(axi_vif.m1_rlast),
                .m1_rvalid(axi_vif.m1_rvalid)
                );		


		task run_test();
			if ($test$plusargs("WT")) begin
				$display("[%0t] RUNNING WRITE PATH TEST", $time);
				wt = new(axi_vif);
				test = wt;
			end	
			else if ($test$plusargs("AT")) begin
				$display("[%0t] RUNNING ARBITATION TEST", $time);
				at = new(axi_vif);
				test = at;
			end
			else if ($test$plusargs("RT")) begin
				$display("[%0t] RUNNING READ TEST", $time);
				rt = new(axi_vif);
				test = rt;
			end
			else if ($test$plusargs("ET")) begin
				$display("[%0t] RUNNING ERROR TEST", $time);
				et = new(axi_vif);
				test = et;
			end
			else if ($test$plusargs("WRT")) begin
				$display("[%0t] RUNNING MEMORY TEST", $time);
				wrt = new(axi_vif);
				test = wrt;
			end
			else if ($test$plusargs("NOC")) begin
				$display("[%0t] RUNNING CONCURRENT MASTER-SLAVE TEST", $time);
				noc = new(axi_vif);
				test = noc;
			end
			else if ($test$plusargs("PC")) begin
                                $display("[%0t] RUNNING PARTIAL CONTENTION TEST", $time);
                                pc = new(axi_vif);
                                test = pc;
                        end

			else if ($test$plusargs("MT")) begin
                                $display("[%0t] RUNNING MULTIPLE OUTSTANDING TRANSACTION TEST", $time);
                                mt = new(axi_vif);
                                test = mt;
                        end
			else if ($test$plusargs("BWT")) begin
                                $display("[%0t] RUNNING BURST WRITE PATH TEST", $time);
                                bwt = new(axi_vif);
                                test = bwt;
                        end
			else if ($test$plusargs("RST")) begin
                                $display("[%0t] RUNNING RESET TEST", $time);
                                rst = new(axi_vif);
                                test = rst;
                        end
			


			else if ($test$plusargs("BT")) begin
				$display("[%0t] RUNNING BASE TEST", $time);
				test = new(axi_vif);
			end

		
			else begin
				$display("[%0t] RUNNING DEFAULT BASE TEST", $time);
				test = new(axi_vif);
			end
		endtask

		initial begin
			$dumpfile("waveform.vcd");
			$dumpvars(1, tb_top);
		end
		   


		initial begin
			run_test();
			test.env_o.sb.expected_transactions = test.total_transactions;
			fork
				test.env_o.agt.run();
				test.env_o.sb.run();
			join_none

			test.run();
			@(test.env_o.sb.done);
			$display("[%0t] ALL TRANSACTIONS MONITORED", $time);
			#20;
		$finish;
		end
endmodule	



