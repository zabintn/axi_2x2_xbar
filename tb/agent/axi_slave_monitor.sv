`timescale 1ns/1ps

import axi_param_pkg::*;

class slave_monitor;
    int unsigned slave_id;
    mailbox mon2sb_s;
    virtual axi_xbar_if axi_vif;

    // Observe the three write channels independently.
    mailbox aw_seen;
    mailbox w_seen;
    mailbox b_seen;

    function new(
        int unsigned slave_id,
        mailbox mon2sb_s,
        virtual axi_xbar_if axi_vif
    );
        this.slave_id = slave_id;
        this.mon2sb_s = mon2sb_s;
        this.axi_vif  = axi_vif;

        aw_seen = new();
        w_seen  = new();
        b_seen  = new();

        $display("[%0t] SLAVE MONITOR CONSTRUCTED", $time);
    endfunction

    task run();
        fork
            monitor_write();
            monitor_read();
        join_none
    endtask

    task monitor_write();
        fork
            collect_aw();
            collect_w();
            collect_b();
            join_write();
        join
    endtask

    task collect_aw();
        forever begin
            transaction tr;
            logic [TAG_WIDTH-1:0] tagged_id;

            tr = new();
            tr.axi_op   = AXI_WRITE;
            tr.slave_id = slave_id;

            if (slave_id == 0) begin
                @(posedge axi_vif.aclk iff
                  (axi_vif.s0_awvalid && axi_vif.s0_awready));
                tagged_id    = axi_vif.s0_awid;
                tr.m_awaddr  = axi_vif.s0_awaddr;
                tr.m_awlen   = axi_vif.s0_awlen;
                tr.m_awsize  = axi_vif.s0_awsize;
                tr.m_awburst = axi_vif.s0_awburst;
            end
            else begin
                @(posedge axi_vif.aclk iff
                  (axi_vif.s1_awvalid && axi_vif.s1_awready));
                tagged_id    = axi_vif.s1_awid;
                tr.m_awaddr  = axi_vif.s1_awaddr;
                tr.m_awlen   = axi_vif.s1_awlen;
                tr.m_awsize  = axi_vif.s1_awsize;
                tr.m_awburst = axi_vif.s1_awburst;
            end

            tr.m_awid    = tagged_id[ID_WIDTH-1:0];
            tr.master_id = tagged_id[TAG_WIDTH-1];
            aw_seen.put(tr);
        end
    endtask

    task collect_w();
        forever begin
            transaction tr;
            bit last;
	    bit [DATA_WIDTH-1:0]   wdata_q[$];
            bit [DATA_WIDTH/8-1:0] wstrb_q[$];
            tr        = new();
            tr.axi_op = AXI_WRITE;
            last      = 1'b0;

            // W has no ID in AXI4. WLAST defines the burst boundary.
            while (!last) begin
                if (slave_id == 0) begin
                    @(posedge axi_vif.aclk iff
                      (axi_vif.s0_wvalid && axi_vif.s0_wready));
                    wdata_q.push_back(axi_vif.s0_wdata);
                    wstrb_q.push_back(axi_vif.s0_wstrb);
		      last = axi_vif.s0_wlast;
                end
                else begin
                    @(posedge axi_vif.aclk iff
                      (axi_vif.s1_wvalid && axi_vif.s1_wready));
                    wdata_q.push_back(axi_vif.s1_wdata);
                    wstrb_q.push_back(axi_vif.s1_wstrb);
		      last = axi_vif.s1_wlast;
                end
            end
	    tr.m_wdata = wdata_q;
            tr.m_wstrb = wstrb_q;
            w_seen.put(tr);
        end
    endtask

    task collect_b();
        forever begin
            transaction tr;

            tr          = new();
            tr.axi_op   = AXI_WRITE;
            tr.slave_id = slave_id;

            if (slave_id == 0) begin
                @(posedge axi_vif.aclk iff
                  (axi_vif.s0_bvalid && axi_vif.s0_bready));
                tr.bid   = axi_vif.s0_bid;
                tr.bresp = axi_vif.s0_bresp;
            end
            else begin
                @(posedge axi_vif.aclk iff
                  (axi_vif.s1_bvalid && axi_vif.s1_bready));
                tr.bid   = axi_vif.s1_bid;
                tr.bresp = axi_vif.s1_bresp;
            end

            b_seen.put(tr);
        end
    endtask

    task join_write();
        transaction aw_q[$];
        transaction w_q[$];
        transaction b_q[$];
        transaction waiting_for_b[bit [TAG_WIDTH-1:0]][$];
        transaction tmp;
        transaction tr;
        bit [TAG_WIDTH-1:0] tag;
        int i;

        forever begin
            @(posedge axi_vif.aclk);

            while (aw_seen.try_get(tmp)) aw_q.push_back(tmp);
            while (w_seen.try_get(tmp))  w_q.push_back(tmp);
            while (b_seen.try_get(tmp))  b_q.push_back(tmp);

            // AXI4 W bursts correspond to AW transactions in acceptance order.
            while ((aw_q.size() != 0) && (w_q.size() != 0)) begin
                tr  = aw_q.pop_front();
                tmp = w_q.pop_front();
                tr.m_wdata = tmp.m_wdata;
                tr.m_wstrb = tmp.m_wstrb;
                tag = {tr.master_id, tr.m_awid};
                waiting_for_b[tag].push_back(tr);
            end

            // B may have been captured before AW/W assembly reached this point.
            i = 0;
            while (i < b_q.size()) begin
                tag = b_q[i].bid;
                if (waiting_for_b.exists(tag) &&
                    (waiting_for_b[tag].size() != 0)) begin
                    tr = waiting_for_b[tag].pop_front();
                    tr.bid   = b_q[i].bid;
                    tr.bresp = b_q[i].bresp;
                    b_q.delete(i);

                    if (waiting_for_b[tag].size() == 0)
                        waiting_for_b.delete(tag);

                    tr.display("SLAVE MONITOR");
                    mon2sb_s.put(tr);
                end
                else begin
                    i++;
                end
            end
        end
    endtask

    task monitor_read();
        forever begin
            transaction tr;
            logic [TAG_WIDTH-1:0] tagged_id;
            bit [DATA_WIDTH-1:0] rdata_q[$];
            bit [1:0]            rresp_q[$];
            bit [TAG_WIDTH-1:0]  rid_q[$];
            bit rlast_seen;
            int beat_cnt;

            tr = new();
            tr.axi_op   = AXI_READ;
            tr.slave_id = slave_id;
            rlast_seen  = 1'b0;
            beat_cnt    = 0;

            if (slave_id == 0) begin
                do @(posedge axi_vif.aclk);
                while (!((axi_vif.s0_arvalid === 1'b1) &&
                         (axi_vif.s0_arready === 1'b1)));
                tagged_id    = axi_vif.s0_arid;
                tr.m_araddr  = axi_vif.s0_araddr;
                tr.m_arlen   = axi_vif.s0_arlen;
                tr.m_arsize  = axi_vif.s0_arsize;
                tr.m_arburst = axi_vif.s0_arburst;
            end
            else begin
                do @(posedge axi_vif.aclk);
                while (!((axi_vif.s1_arvalid === 1'b1) &&
                         (axi_vif.s1_arready === 1'b1)));
                tagged_id    = axi_vif.s1_arid;
                tr.m_araddr  = axi_vif.s1_araddr;
                tr.m_arlen   = axi_vif.s1_arlen;
                tr.m_arsize  = axi_vif.s1_arsize;
                tr.m_arburst = axi_vif.s1_arburst;
            end
            tr.m_arid    = tagged_id[ID_WIDTH-1:0];
            tr.master_id = tagged_id[TAG_WIDTH-1];

            fork
                begin
                    if (slave_id == 0) begin
                        while (!rlast_seen) begin
                            do @(posedge axi_vif.aclk);
                            while (!(axi_vif.s0_rvalid && axi_vif.s0_rready));
                            rdata_q.push_back(axi_vif.s0_rdata);
                            rid_q.push_back(axi_vif.s0_rid);
                            rresp_q.push_back(axi_vif.s0_rresp);
                            rlast_seen = axi_vif.s0_rlast;
                            $display("[%0t] SLAVE 0 R_VALID_RDY Handshake beat=%0d rlast=%0b",
                                     $time, beat_cnt, axi_vif.s0_rlast);
                            beat_cnt++;
                        end
                    end
                    else begin
                        while (!rlast_seen) begin
                            do @(posedge axi_vif.aclk);
                            while (!(axi_vif.s1_rvalid && axi_vif.s1_rready));
                            rdata_q.push_back(axi_vif.s1_rdata);
                            rid_q.push_back(axi_vif.s1_rid);
                            rresp_q.push_back(axi_vif.s1_rresp);
                            rlast_seen = axi_vif.s1_rlast;
                            $display("[%0t] SLAVE 1 R_VALID_RDY Handshake beat=%0d rlast=%0b",
                                     $time, beat_cnt, axi_vif.s1_rlast);
                            beat_cnt++;
                        end
                    end

                    tr.rdata = rdata_q;
                    tr.rresp = rresp_q;
                    tr.rid   = rid_q;

                    tr.display("SLAVE MONITOR");
                    mon2sb_s.put(tr);
                end
            join_none
        end
    endtask
endclass

