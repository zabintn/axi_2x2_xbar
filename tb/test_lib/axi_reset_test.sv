class reset_test extends base_test;

    function new(virtual axi_xbar_if axi_vif);
        super.new(axi_vif);
        total_transactions = 0;
    endfunction

    virtual task apply_reset(int cycles = 2);

        axi_vif.arst_n = 1'b0;
        $display("[%0t] RESET ASSERTED", $time);

        repeat(cycles)
            @(posedge axi_vif.aclk);

        check_reset_values("DURING RESET");

        axi_vif.arst_n = 1'b1;

        repeat(2)
            @(posedge axi_vif.aclk);

        $display("[%0t] RESET DEASSERTED", $time);

        check_reset_values("AFTER RESET DEASSERT");

    endtask


    task check_reset_values(string phase);

        bit pass = 1'b1;

        if (axi_vif.m0_awvalid !== 1'b0) begin
            pass = 0;
            $display("FAIL: m0_awvalid=%0b expected 0", axi_vif.m0_awvalid);
        end
	else $display("PASS: m0_awvalid=%0b expected 0", axi_vif.m0_awvalid);

        if (axi_vif.m1_awvalid !== 1'b0) begin
            pass = 0;
            $display("FAIL: m1_awvalid=%0b expected 0", axi_vif.m1_awvalid);
        end

	else $display("PASS: m1_awvalid=%0b expected 0", axi_vif.m1_awvalid);

        if (axi_vif.m0_wvalid !== 1'b0) begin
            pass = 0;
            $display("FAIL: m0_wvalid=%0b expected 0", axi_vif.m0_wvalid);
        end

	else $display("PASS: m0_wvalid=%0b expected 0", axi_vif.m0_wvalid);

        if (axi_vif.m1_wvalid !== 1'b0) begin
            pass = 0;
            $display("FAIL: m1_wvalid=%0b expected 0", axi_vif.m1_wvalid);
        end
	else $display("PASS: m1_wvalid=%0b expected 0", axi_vif.m1_wvalid);
        
	if (axi_vif.s0_bvalid !== 1'b0) begin
            pass = 0;
            $display("FAIL: s0_bvalid=%0b expected 0", axi_vif.s0_bvalid);
        end

	else $display("PASS: s0_bvalid=%0b expected 0", axi_vif.s0_bvalid);
        if (axi_vif.s1_bvalid !== 1'b0) begin
            pass = 0;
            $display("FAIL: s1_bvalid=%0b expected 0", axi_vif.s1_bvalid);
        end
	else $display("PASS: s1_bvalid=%0b expected 0", axi_vif.s1_wvalid);
        if (axi_vif.s0_rvalid !== 1'b0) begin
            pass = 0;
            $display("FAIL: s0_rvalid=%0b expected 0", axi_vif.s0_rvalid);
        end

	else $display("PASS: s0_rvalid=%0b expected 0", axi_vif.s0_rvalid);
        if (axi_vif.s1_rvalid !== 1'b0) begin
            pass = 0;
            $display("FAIL: s1_rvalid=%0b expected 0", axi_vif.s1_rvalid);
        end

	else $display("PASS: s1_rvalid=%0b expected 0", axi_vif.s1_rvalid);
        if (pass)
            $display("[%0t] RESET CHECK PASSED: %s", $time, phase);
        else
            $display("[%0t] RESET CHECK FAILED: %s", $time, phase);

    endtask


    task run();

        $display("[%0t] RUNNING RESET TEST", $time);

        apply_reset();

        $display("[%0t] RESET TEST COMPLETE", $time);

        $finish;

    endtask

endclass
