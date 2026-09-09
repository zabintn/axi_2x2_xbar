`timescale 1ns/1ps
import axi_param_pkg::*;

class partial_contention_test extends base_test;

    function new(virtual axi_xbar_if axi_vif);
        super.new(axi_vif);
        total_transactions = 20; 
    endfunction

    task automatic master0_stream();
        for (int round = 0; round < total_transactions; round++) begin
            automatic bit         to_s0 = (round % 2 == 0);
            automatic bit [31:0]  addr0 = to_s0 ? (32'h0000_0010 + round*32'h20)
                                                  : (32'h1000_0010 + round*32'h20); // S1 range
            automatic bit [3:0]   id    = round[3:0];
            env_o.agt.gen.run(
                .axi_op(AXI_WRITE), .master_id(1'b0),
                .m_awaddr(addr0), .m_awid(id),
                .m_awlen(8'd0), .m_awsize(3'd3), .m_awburst(2'b01),
                .m_wdata({64'hAAAA_AAAA_AAAA_AAAA}), .m_wstrb({8'hFF})
            );
            $display("[%0t] M0 round %0d -> %s", $time, round, to_s0 ? "S0" : "S1");
        end
    endtask

    // M1 always targets S0.
    task automatic master1_stream();
        for (int round = 0; round < total_transactions; round++) begin
            automatic bit [31:0] addr1 = 32'h0000_0018 + round*32'h20;
            automatic bit [3:0]  id    = round[3:0];
            env_o.agt.gen.run(
                .axi_op(AXI_WRITE), .master_id(1'b1),
                .m_awaddr(addr1), .m_awid(id),
                .m_awlen(8'd0), .m_awsize(3'd3), .m_awburst(2'b01),
                .m_wdata({64'hBBBB_BBBB_BBBB_BBBB}), .m_wstrb({8'hFF})
            );
        end
    endtask

    virtual task run();
        apply_reset();
        $display("[%0t] STARTING PARTIAL CONTENTION TEST (M1->S0 fixed, M0 alternates S0/S1)", $time);
        fork
            master0_stream();
            master1_stream();
        join
        $display("[%0t] PARTIAL CONTENTION TEST COMPLETE", $time);
    endtask

endclass
