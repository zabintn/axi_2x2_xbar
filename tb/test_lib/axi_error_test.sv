import axi_param_pkg::*;

class error_test extends base_test;

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


        // ============================================================
        // TRANSACTION 1 - DECODE ERROR, 4-BEAT BURST
        // ============================================================
        $display("[%0t] GENERATING DECODE ERROR TRANSACTION", $time);

        env_o.agt.gen.run(
            .axi_op     (AXI_WRITE),
            .master_id  (1'b0),
            .m_awaddr   (32'h2000_0010),
            .m_awid     (4'h3),
            .m_awlen    (8'd3),              // 4 beats
            .m_awsize   (3'd3),              // 8 bytes/beat
            .m_awburst  (2'b01),             // INCR

            .m_wdata    ({
                64'h9999_AAAA_BBBB_CCCC,
                64'h5555_6666_7777_8888,
                64'h1111_2222_3333_4444,
                64'hAABB_CCDD_1122_3344
            }),

            .m_wstrb    ({
                8'hFF,
                8'hFF,
                8'hFF,
                8'hFF
            })
        );


        // ============================================================
        // TRANSACTION 2 - NORMAL WRITE
        // ============================================================
        $display("[%0t] GENERATING NORMAL WRITE TRANSACTION", $time);

        env_o.agt.gen.run(
            .axi_op     (AXI_WRITE),
            .master_id  (1'b0),
            .m_awaddr   (32'h0000_0010),
            .m_awid     (4'h5),
            .m_awlen    (8'd0),              // 1 beat
            .m_awsize   (3'd3),              // 8 bytes/beat
            .m_awburst  (2'b01),             // INCR

            .m_wdata    ({
	    64'hDEAD_BEEF_1234_5678}),

            .m_wstrb    ({
                8'hFF
            })
        );

    endtask

endclass
