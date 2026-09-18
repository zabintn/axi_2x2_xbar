
import axi_param_pkg::*;

class arb_monitor;
    virtual axi_xbar_if axi_vif;
    refmodel ref_model;
    mailbox mon2sb_arb;

    typedef struct packed {
        bit valid;
        bit target_slave;
    } pend_s;

    pend_s aw_pending[2];
    pend_s ar_pending[2];

    function new(virtual axi_xbar_if axi_vif, mailbox mon2sb_arb);
        this.axi_vif    = axi_vif;
        this.mon2sb_arb = mon2sb_arb;
        ref_model       = new();
        aw_pending[0] = '0; aw_pending[1] = '0;
        ar_pending[0] = '0; ar_pending[1] = '0;
        $display("[%0t] ARB MONITOR CONSTRUCTED", $time);
    endfunction

    task run();
        forever begin
            @(posedge axi_vif.aclk);
  
  	    track_grant();    // exit events + check
  
	    track_accept();   // entry events
  
        end
    endtask

    task track_accept();
        refmodel::decode_result_s d;

        if (axi_vif.m0_awvalid && axi_vif.m0_awready) begin
            d = ref_model.decode_addr(axi_vif.m0_awaddr);
            if (!d.decode_err) begin
                aw_pending[0].valid        = 1'b1;
                aw_pending[0].target_slave = d.slave_id;
            end
        end
        if (axi_vif.m1_awvalid && axi_vif.m1_awready) begin
            d = ref_model.decode_addr(axi_vif.m1_awaddr);
            if (!d.decode_err) begin
                aw_pending[1].valid        = 1'b1;
                aw_pending[1].target_slave = d.slave_id;
            end
        end
        if (axi_vif.m0_arvalid && axi_vif.m0_arready) begin
            d = ref_model.decode_addr(axi_vif.m0_araddr);
            if (!d.decode_err) begin
                ar_pending[0].valid        = 1'b1;
                ar_pending[0].target_slave = d.slave_id;
            end
        end
        if (axi_vif.m1_arvalid && axi_vif.m1_arready) begin
            d = ref_model.decode_addr(axi_vif.m1_araddr);
            if (!d.decode_err) begin
                ar_pending[1].valid        = 1'b1;
                ar_pending[1].target_slave = d.slave_id;
            end
        end
    endtask

    task track_grant();
        check_grant_on_slave(1'b0);
        check_grant_on_slave(1'b1);
    endtask

    task check_grant_on_slave(bit slave_id);
        bit aw_grant, ar_grant, aw_winner, ar_winner, m0_aw_req, m1_aw_req, m0_ar_req, m1_ar_req;

        if (slave_id == 1'b0) begin
            aw_grant = axi_vif.s0_awvalid && axi_vif.s0_awready;
            ar_grant = axi_vif.s0_arvalid && axi_vif.s0_arready;
        end else begin
            aw_grant = axi_vif.s1_awvalid && axi_vif.s1_awready;
            ar_grant = axi_vif.s1_arvalid && axi_vif.s1_arready;
        end

        m0_aw_req = aw_pending[0].valid && aw_pending[0].target_slave == slave_id;
        m0_ar_req = ar_pending[0].valid && ar_pending[0].target_slave == slave_id;
        m1_aw_req = aw_pending[1].valid && aw_pending[1].target_slave == slave_id;
        m1_ar_req = ar_pending[1].valid && ar_pending[1].target_slave == slave_id;

        if (aw_grant) begin
            aw_winner = (slave_id == 1'b0) ? axi_vif.s0_awid[TAG_WIDTH-1] : axi_vif.s1_awid[TAG_WIDTH-1];
            push_event(0, slave_id, m0_aw_req, m1_aw_req, aw_winner);
            aw_pending[aw_winner].valid = 1'b0;
        end
        if (ar_grant) begin
            ar_winner = (slave_id == 1'b0) ? axi_vif.s0_arid[TAG_WIDTH-1] : axi_vif.s1_arid[TAG_WIDTH-1];
            push_event(1, slave_id, m0_ar_req, m1_ar_req, ar_winner);
            ar_pending[ar_winner].valid = 1'b0;
        end
    endtask

    task push_event(bit axi_op, bit slave_id, bit m0_req, bit m1_req, bit observed_winner);
        arb_event_s evt;
	evt.axi_op          = axi_op;
        evt.slave_id        = slave_id;
        evt.m0_requesting   = m0_req;
        evt.m1_requesting   = m1_req;
        evt.observed_winner = observed_winner;
        $display("[%0t] ARB MONITOR: slave=%0d m0_req=%0d m1_req=%0d winner=%0d",
                  $time, slave_id, m0_req, m1_req, observed_winner);
        mon2sb_arb.put(evt);
    endtask
endclass

