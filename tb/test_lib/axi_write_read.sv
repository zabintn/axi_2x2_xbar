class write_read_test extends base_test;

    function new(virtual axi_xbar_if axi_vif);
        super.new(axi_vif);

        // One WRITE + one READ
        total_transactions = 2;
    endfunction


    virtual task apply_reset(int cycles = 2);

        axi_vif.arst_n = 1'b0;

        $display("[%0t] RESET ASSERTED", $time);

        repeat (cycles)
            @(posedge axi_vif.aclk);

        axi_vif.arst_n = 1'b1;

        repeat (2)
            @(posedge axi_vif.aclk);

        $display("[%0t] RESET DEASSERTED", $time);

    endtask


    task run();

        apply_reset();
        $display("[%0t] GENERATING DIRECTED WRITE TRANSACTION", $time);

        env_o.agt.gen.run(
            .axi_op     (AXI_WRITE),
            .master_id  (1'b0),

            .m_awaddr   (32'h0000_0010),
            .m_awid     (4'h3),
            .m_awlen    (8'd1),
            .m_awsize   (3'd3),
            .m_awburst  (2'b01),

            .m_wdata    ({64'hAABB_CCDD_1122_3344, 64'hAABB_CCDD_1122_3344}),
            .m_wstrb    ({8'hFF, 8'hFF})
        );

        $display("[%0t] GENERATING DIRECTED READ TRANSACTION", $time);

        env_o.agt.gen.read_run(
            .axi_op     (AXI_READ),
            .master_id  (1'b0),

            .m_araddr   (32'h0000_0010),
            .m_arid     (4'h4),
            .m_arlen    (8'd1),
            .m_arsize   (3'd3),
            .m_arburst  (2'b01)
        );

        repeat (30)
            @(posedge axi_vif.aclk);


        $display("[%0t] WRITE -> READBACK TEST COMPLETE", $time);

        $finish;

    endtask

endclass

