class read_error_test extends base_test;

    function new(virtual axi_xbar_if axi_vif);
        super.new(axi_vif);
        total_transactions = 1;
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
        int timeout;

        apply_reset();

        $display("[%0t] GENERATING DIRECTED AR TRANSACTION", $time);
        env_o.agt.gen.read_run(
            .axi_op     (AXI_READ),
            .master_id  (1'b1),
            .m_araddr   (32'h2000_0010),
            .m_arid     (4'h3),
            .m_arlen    (8'd4),
            .m_arsize   (3'd3),
            .m_arburst  (2'b01)
        );

        timeout = 0;
        while (!(axi_vif.m1_rvalid && axi_vif.m1_rready && axi_vif.m1_rlast)) begin
            @(posedge axi_vif.aclk);
            timeout++;
            if (timeout > 50)
                $fatal(1, "[%0t] TIMEOUT waiting for R response on M1", $time);
        end

        $display("[%0t] R DATA RECEIVED: rid=%0h rdata=%0h",
                  $time, axi_vif.m1_rid, axi_vif.m1_rdata);

        $display("[%0t] GENERATING FOLLOW-UP AR TRANSACTION (post-error check)", $time);
        env_o.agt.gen.read_run(
            .axi_op     (AXI_READ),
            .master_id  (1'b1),
            .m_araddr   (32'h1000_0020),
            .m_arid     (4'h4),
            .m_arlen    (8'd4),
            .m_arsize   (3'd3),
            .m_arburst  (2'b01)
        );

        timeout = 0;
        while (!(axi_vif.m1_rvalid && axi_vif.m1_rready && axi_vif.m1_rlast)) begin
            @(posedge axi_vif.aclk);
            timeout++;
            if (timeout > 50)
                $fatal(1, "[%0t] TIMEOUT waiting for R response on M1 (follow-up)", $time);
        end

        $display("[%0t] FOLLOW-UP R DATA RECEIVED: rid=%0h rdata=%0h",
                  $time, axi_vif.m1_rid, axi_vif.m1_rdata);

        repeat (5)
            @(posedge axi_vif.aclk);

        $display("[%0t] AR-R READ TEST COMPLETE", $time);
        $finish;
    endtask
endclass
