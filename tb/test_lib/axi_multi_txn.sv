import axi_param_pkg::*;
class multi_test extends base_test;

    function new(virtual axi_xbar_if axi_vif);
        super.new(axi_vif);
        total_transactions = 7;
    endfunction

    virtual task apply_reset(int cycles = 2);
        axi_vif.arst_n = 1'b0;
        $display("[%0t] RESET ASSERTED", $time);
        repeat(cycles)
            @(posedge axi_vif.aclk);
        axi_vif.arst_n = 1'b1;
        repeat(2)
            @(posedge axi_vif.aclk);
        $display("[%0t] RESET DEASSERTED", $time);
    endtask

    task run();
        apply_reset();
	        $display("[%0t] GROUP 1: SAME MASTER, SAME SLAVE, MULTIPLE IDs", $time);
        fork
            env_o.agt.gen.run(
                .axi_op     (AXI_WRITE),
                .master_id  (1'b0),
                .m_awaddr   (32'h0000_0010),
                .m_awid     (4'h1),
                .m_awlen    (8'd0),
                .m_awsize   (3'd3),
                .m_awburst  (2'b01),
                .m_wdata    ({64'hAAAA_AAAA_AAAA_AAAA}),
                .m_wstrb    ({8'hFF})
            );
            env_o.agt.gen.run(
                .axi_op     (AXI_WRITE),
                .master_id  (1'b0),
                .m_awaddr   (32'h0000_0020),
                .m_awid     (4'h2),
                .m_awlen    (8'd0),
                .m_awsize   (3'd3),
                .m_awburst  (2'b01),
                .m_wdata    ({64'hBBBB_BBBB_BBBB_BBBB}),
                .m_wstrb    ({8'hFF})
            );
            env_o.agt.gen.run(
                .axi_op     (AXI_WRITE),
                .master_id  (1'b0),
                .m_awaddr   (32'h0000_0030),
                .m_awid     (4'h3),
                .m_awlen    (8'd0),
                .m_awsize   (3'd3),
                .m_awburst  (2'b01),
                .m_wdata    ({64'hCCCC_CCCC_CCCC_CCCC}),
                .m_wstrb    ({8'hFF})
            );
        join

        repeat(20) @(posedge axi_vif.aclk);

        $display("[%0t] GROUP 2: SAME MASTER, DIFFERENT SLAVES", $time);
        fork
            env_o.agt.gen.run(
                .axi_op     (AXI_WRITE),
                .master_id  (1'b0),
                .m_awaddr   (32'h0000_0040),   // -> slave0
                .m_awid     (4'h4),
                .m_awlen    (8'd0),
                .m_awsize   (3'd3),
                .m_awburst  (2'b01),
                .m_wdata    ({64'hDDDD_DDDD_DDDD_DDDD}),
                .m_wstrb    ({8'hFF})
            );
            env_o.agt.gen.run(
                .axi_op     (AXI_WRITE),
                .master_id  (1'b0),
                .m_awaddr   (32'h2000_0040),   // -> decode error
                .m_awid     (4'h5),
                .m_awlen    (8'd0),
                .m_awsize   (3'd3),
                .m_awburst  (2'b01),
                .m_wdata    ({64'hEEEE_EEEE_EEEE_EEEE}),
                .m_wstrb    ({8'hFF})
            );
        join

        repeat(20) @(posedge axi_vif.aclk);

        $display("[%0t] GROUP 3: TWO MASTERS, SAME SLAVE, CONCURRENT", $time);
        fork
            env_o.agt.gen.run(
                .axi_op     (AXI_WRITE),
                .master_id  (1'b0),
                .m_awaddr   (32'h0000_0050),
                .m_awid     (4'h6),
                .m_awlen    (8'd0),
                .m_awsize   (3'd3),
                .m_awburst  (2'b01),
                .m_wdata    ({64'h1111_1111_1111_1111}),
                .m_wstrb    ({8'hFF})
            );
            env_o.agt.gen.run(
                .axi_op     (AXI_WRITE),
                .master_id  (1'b1),
                .m_awaddr   (32'h0000_0060),
                .m_awid     (4'h7),
                .m_awlen    (8'd0),
                .m_awsize   (3'd3),
                .m_awburst  (2'b01),
                .m_wdata    ({64'h2222_2222_2222_2222}),
                .m_wstrb    ({8'hFF})
            );
        join

        repeat(50) @(posedge axi_vif.aclk);

        $display("[%0t] MULTI-OUTSTANDING TEST COMPLETE", $time);
	$finish;
endtask    

endclass
