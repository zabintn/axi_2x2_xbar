class write_path_test extends base_test;

    function new(virtual axi_xbar_if axi_vif);
        super.new(axi_vif);
	total_transactions=1;
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
        // DIRECTED AW TRANSACTION
        $display("[%0t] GENERATING DIRECTED AW TRANSACTION", $time);

        env_o.agt.gen.run(
	    .axi_op     (AXI_WRITE),	
	    .master_id  (1'b1),
            .m_awaddr  (32'h1000_0010),
            .m_awid    (4'h3),
            .m_awlen   (8'h0),
            .m_awsize  (3'd3),
            .m_awburst (2'b10),
	    .m_wdata    ('{64'hAABB_CCDD_1122_3344}),
			.m_wstrb    ('{8'hFF})       
			);

    endtask

endclass
