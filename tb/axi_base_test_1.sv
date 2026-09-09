class base_test_1 extends base_test;
     virtual task apply_reset(int cycles = 2);
        repeat(cycles) @(posedge axi_vif.aclk);
        axi_vif.arst_n = 1'b1;
        repeat(2) @(posedge axi_vif.aclk);
        $display("[%0t] RESET DEASSERTED", $time);
    endtask
    
    function new(
        virtual axi_xbar_if axi_vif
    );
        super.new(axi_vif);
    endfunction
    task run();
    	apply_reset();
	env_o.agt.gen.count = total_transactions;
        env_o.agt.gen.rand_run();
    endtask
endclass
