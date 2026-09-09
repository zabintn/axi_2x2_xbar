`timescale 1ns/1ps
import axi_param_pkg::*;

class no_contention_test extends base_test;

    function new(virtual axi_xbar_if axi_vif);
        super.new(axi_vif);
        total_transactions = 1;
    endfunction

    virtual task run();
        apply_reset();

        $display(
            "[%0t] STARTING NO CONTENTION TEST",
            $time
        );

        // Submit both transactions before the same rising edge.
        for (int round = 0; round < total_transactions; round++) begin
            automatic bit [31:0] addr0 = 32'h0000_0010 + round*32'h8;
            automatic bit [31:0] addr1 = 32'h1000_0010 + round*32'h8;
            automatic bit [3:0]  id    = round[3:0];
	    automatic bit [63:0] slave_addr=round[0];
	   
	    if (slave_addr == 1'b0) begin
            // Round: M0 -> S0, M1 -> S1
            addr0 = 32'h0000_0010 + round*32'h8;
            addr1 = 32'h1000_0010 + round*32'h8;
    	end
        else begin
            // Round: M0 -> S1, M1 -> S0
            addr0 = 32'h1000_0010 + round*32'h8;
            addr1 = 32'h0000_0010 + round*32'h8;
        end
	
	@(negedge axi_vif.aclk);

        fork
            begin : master0_request
                env_o.agt.gen.run(
	            .axi_op(AXI_WRITE),
                    .master_id  (1'b0),
                    .m_awaddr   (addr0),
                    .m_awid     (id),
                    .m_awlen    (8'd0),
                    .m_awsize   (3'd3),
                    .m_awburst  (2'b01),
                    .m_wdata    ({64'hAAAA_AAAA_AAAA_AAAA}),
                    .m_wstrb    ({8'hFF})
                );
            end

            begin : master1_request
                env_o.agt.gen.run(
		    .axi_op(AXI_WRITE),
                    .master_id  (1'b1),
                    .m_awaddr   (addr1),
                    .m_awid     (id),
                    .m_awlen    (8'd0),
                    .m_awsize   (3'd3),
                    .m_awburst  (2'b01),
                    .m_wdata    ({64'hBBBB_BBBB_BBBB_BBBB}),
                    .m_wstrb    ({8'hFF})
                );
            end
        join
end
        $display(
            "[%0t] BOTH S0 ARBITRATION REQUESTS SUBMITTED",
            $time
        );
    endtask

endclass
