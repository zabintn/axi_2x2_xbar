import axi_param_pkg::*;

class base_test;

    env env_o;
    virtual axi_xbar_if axi_vif;
    int total_transactions;

    function new(virtual axi_xbar_if axi_vif);
    	this.axi_vif=axi_vif;
	total_transactions=5;
        $display("[%0t] INSIDE THE BASE TEST CONSTRUCTOR", $time);
        env_o = new(axi_vif);
    endfunction
    
    virtual task apply_reset(int cycles = 2);
        axi_vif.arst_n = 1'b0;
        repeat(cycles) @(posedge axi_vif.aclk);
        axi_vif.arst_n = 1'b1;
    endtask
    
    virtual task run();
	apply_reset();
	env_o.agt.gen.count = total_transactions;
        env_o.agt.gen.rand_run();
    endtask

endclass	
