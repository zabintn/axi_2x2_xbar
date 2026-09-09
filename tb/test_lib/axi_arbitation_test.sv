class arb_test extends base_test;

    function new(virtual axi_xbar_if axi_vif);
        super.new(axi_vif);
        total_transactions = 2;
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
        // RESET
        apply_reset();

        $display("[%0t] ARBITRATION TEST - SINGLE ROUND", $time);

        // MASTER 0 -> SLAVE 0
        $display("[%0t] GENERATING M0 -> S0 TRANSACTION", $time);
        env_o.agt.gen.run(
            .axi_op     (AXI_WRITE),
            .master_id  (1'b0),
            .m_awaddr   (32'h0000_0010),
            .m_awid     (4'h1),
            .m_awlen    (8'h0),
            .m_awsize   (3'd3),
            .m_awburst  (2'b01),
            .m_wdata    ('{64'hAAAA_BBBB_CCCC_DDDD}),
            .m_wstrb    ('{8'hFF})
        );

        // MASTER 1 -> SAME SLAVE (SLAVE 0)
        $display("[%0t] GENERATING M1 -> S0 TRANSACTION", $time);
        env_o.agt.gen.run(
            .axi_op     (AXI_WRITE),
            .master_id  (1'b1),
            .m_awaddr   (32'h0000_0020),
            .m_awid     (4'h2),
            .m_awlen    (8'h0),
            .m_awsize   (3'd3),
            .m_awburst  (2'b01),
            .m_wdata    ('{64'h1111_2222_3333_4444}),
            .m_wstrb    ('{8'hFF})
        );
    endtask

endclass
