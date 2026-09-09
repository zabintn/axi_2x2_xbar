`timescale 1ns/1ps
import axi_param_pkg::*;

class scoreboard;

    mailbox mon2sb_m;
    mailbox mon2sb_s;
    mailbox mon2sb_arb;

    int expected_transactions;
    int received_transactions;
    int pass_count;
    int fail_count;
    event done;

    refmodel ref_model;

    transaction pending_mtr[bit [TAG_WIDTH:0]];
    transaction pending_str[bit [TAG_WIDTH:0]];

    function new(mailbox mon2sb_m, mailbox mon2sb_s, mailbox mon2sb_arb);
        this.mon2sb_m = mon2sb_m;
        this.mon2sb_s = mon2sb_s;
	this.mon2sb_arb = mon2sb_arb;
        received_transactions = 0;
        pass_count = 0;
        fail_count = 0;
        ref_model = new();
    endfunction

    function void check(bit cond, string what, string exp_s, string act_s);
        if (cond) begin
            pass_count++;
            $display("[%0t] SCOREBOARD MATCH: %s expected = %s, actual =%s", $time, what, exp_s, act_s);
        end
        else begin
            fail_count++;
            $display("[%0t] SCOREBOARD MISMATCH: %s  expected=%s actual=%s",
                      $time, what, exp_s, act_s);
        end
    endfunction

    function bit [TAG_WIDTH:0] get_tag(transaction tr);
        bit [ID_WIDTH-1:0] id;
        id = (tr.axi_op == AXI_WRITE) ? tr.m_awid : tr.m_arid;
        return {tr.axi_op, tr.master_id, id};
    endfunction

    // all comparison logic for one transaction
    function void compare(transaction mtr, transaction str);
        refmodel::decode_result_s exp;
        refmodel::decode_response exp_master;

        exp = ref_model.predict_decode(mtr);

        check(exp.decode_err == mtr.decode_err,
              "decode_err", $sformatf("%0d", exp.decode_err), $sformatf("%0d", mtr.decode_err));

        if (exp.decode_err) begin
            if (mtr.axi_op == AXI_WRITE) begin
                check(mtr.bresp == exp.exp_resp, "bresp (decode error)", $sformatf("%0b", exp.exp_resp), $sformatf("%0b", mtr.bresp));
            end 
	    else begin
                foreach (mtr.rresp[i])
			check(mtr.rresp[i] == exp.exp_resp, $sformatf("rresp[%0d] (decode error)", i), $sformatf("%0b", exp.exp_resp),
                          $sformatf("%0b", mtr.rresp[i]));
            end
        end
        else begin
            check(exp.slave_id == mtr.slave_id,
                  "slave_id",
                  $sformatf("%0d", exp.slave_id),
                  $sformatf("%0d", mtr.slave_id));

            if (mtr.axi_op == AXI_WRITE) begin
                //===========================AW CHANNEL==========================
                check(mtr.m_awaddr == str.m_awaddr, "awaddr passthrough", $sformatf("%0h", mtr.m_awaddr), $sformatf("%0h", str.m_awaddr));
                check(mtr.m_awlen == str.m_awlen, "awlen passthrough", $sformatf("%0d", mtr.m_awlen), $sformatf("%0d", str.m_awlen));
                check(mtr.m_awsize == str.m_awsize, "awsize passthrough", $sformatf("%0d", mtr.m_awsize), $sformatf("%0d", str.m_awsize));
                check(mtr.m_awburst == str.m_awburst, "awburst passthrough", $sformatf("%0d", mtr.m_awburst), $sformatf("%0d", str.m_awburst));

                //==========================W CHANNEL============================
                check(mtr.m_wdata.size() == str.m_wdata.size(), "wdata size check", $sformatf("%0h", mtr.m_wdata.size()), $sformatf("%0h", str.m_wdata.size()));
                if (mtr.m_wdata.size() == str.m_wdata.size()) begin
                    foreach (mtr.m_wdata[i])
                        check(mtr.m_wdata[i] == str.m_wdata[i], $sformatf("wdata passthrough beat=%0d", i), $sformatf("%0h", mtr.m_wdata[i]), $sformatf("%0h", str.m_wdata[i]));
                end

                check(mtr.m_wstrb.size() == str.m_wstrb.size(), "wstrb size check", $sformatf("%0h", mtr.m_wstrb.size()), $sformatf("%0h", str.m_wstrb.size()));
                if (mtr.m_wstrb.size() == str.m_wstrb.size()) begin
                    foreach (mtr.m_wstrb[i])
                        check(mtr.m_wstrb[i] == str.m_wstrb[i], $sformatf("wstrb passthrough beat=%0d", i), $sformatf("%0h", mtr.m_wstrb[i]), $sformatf("%0h", str.m_wstrb[i]));
                end

                //========================RESPONSE================================
                check(mtr.bresp == str.bresp, "bresp passthrough", $sformatf("%0b", str.bresp), $sformatf("%0b", mtr.bresp));

                exp_master = ref_model.predict_master(str.bid);
                check(exp_master.master_id == mtr.master_id,
                      "response routed to correct master (write)",
                      $sformatf("%0d", exp_master.master_id),
                      $sformatf("%0d", mtr.master_id));
            end
            else begin
                //===========================AR CHANNEL==========================
                check(mtr.m_araddr == str.m_araddr, "araddr passthrough", $sformatf("%0h", mtr.m_araddr), $sformatf("%0h", str.m_araddr));
                check(mtr.m_arlen == str.m_arlen, "arlen passthrough", $sformatf("%0d", mtr.m_arlen), $sformatf("%0d", str.m_arlen));
                check(mtr.m_arsize == str.m_arsize, "arsize passthrough", $sformatf("%0d", mtr.m_arsize), $sformatf("%0d", str.m_arsize));
                check(mtr.m_arburst == str.m_arburst, "arburst passthrough", $sformatf("%0d", mtr.m_arburst), $sformatf("%0d", str.m_arburst));

                //===========================R CHANNEL============================
                check(mtr.rdata.size() == str.rdata.size(), "rdata size check", $sformatf("%0d", mtr.rdata.size()), $sformatf("%0d", str.rdata.size()));
                if (mtr.rdata.size() == str.rdata.size()) begin
                    foreach (mtr.rdata[i])
                        check(mtr.rdata[i] == str.rdata[i], $sformatf("rdata passthrough beat=%0d", i), $sformatf("%0h", mtr.rdata[i]), $sformatf("%0h", str.rdata[i]));
                end

                check(mtr.rresp.size() == str.rresp.size(), "rresp size check", $sformatf("%0d", mtr.rresp.size()), $sformatf("%0d", str.rresp.size()));
                if (mtr.rresp.size() == str.rresp.size()) begin
                    foreach (mtr.rresp[i])
                        check(mtr.rresp[i] == str.rresp[i], $sformatf("rresp passthrough beat=%0d", i), $sformatf("%0b", str.rresp[i]), $sformatf("%0b", mtr.rresp[i]));
                end

                foreach (str.rid[i]) begin
                    exp_master = ref_model.predict_master(str.rid[i]);
                    check(exp_master.master_id == mtr.master_id,
                          $sformatf("response routed to correct master (read beat %0d)", i),
                          $sformatf("%0d", exp_master.master_id),
                          $sformatf("%0d", mtr.master_id));
                end
            end
        end

        received_transactions++;
        mtr.display("SCOREBOARD-M");
        if (!mtr.decode_err) str.display("SCOREBOARD-S");

        $display("[%0t] SCOREBOARD: Transaction %0d received. pass=%0d fail=%0d",
                  $time, received_transactions, pass_count, fail_count);

        if (received_transactions >= expected_transactions) begin
            $display("[%0t] SCOREBOARD: Expected %0d transactions completed, PASS=%0d FAIL=%0d",
                      $time, expected_transactions, pass_count, fail_count);
            ->done;
        end

	if(fail_count==0)
		$display("[%0t] ALL PASS. Total transactions: %0d" , $time, received_transactions);
	else 
		$display("[%0t] ERROR FOUND. FAIL COUNT=%0d PASS COUNT=%0d TOTAL TESTS=%0d", $time, fail_count, pass_count, fail_count+pass_count);
    endfunction

    task run();
        fork
            // master-side  loop
            forever begin
                transaction mtr;
                bit [TAG_WIDTH:0] tag;
                refmodel::decode_result_s exp;

                mon2sb_m.get(mtr);
                exp = ref_model.predict_decode(mtr);

                if (exp.decode_err) begin
                    compare(mtr, null);
                end else begin
                    tag = get_tag(mtr);
                    if (pending_str.exists(tag)) begin
                        compare(mtr, pending_str[tag]);
                        pending_str.delete(tag);
                    end else begin
                        pending_mtr[tag] = mtr;
                    end
                end
            end

            // slave-side draining loop
            forever begin
                transaction str;
                bit [TAG_WIDTH:0] tag;

                mon2sb_s.get(str);
                tag = get_tag(str);
                if (pending_mtr.exists(tag)) begin
                    compare(pending_mtr[tag], str);
                    pending_mtr.delete(tag);
                end else begin
                    pending_str[tag] = str;
                end
            end

            // arbitration checking loop
            forever begin
                arb_event_s evt;
                int predicted;
                mon2sb_arb.get(evt);

		
			if (evt.axi_op==0) begin
				if (evt.m0_requesting && evt.m1_requesting) begin
					predicted = ref_model.predict_write_winner(evt.slave_id, evt.m0_requesting, evt.m1_requesting);
					check(predicted == evt.observed_winner, 
					$sformatf("arbitration winner (slave %0d)", evt.slave_id), 
					$sformatf("%0d", predicted),
					$sformatf("%0d", evt.observed_winner));
				end
				ref_model.update_w_arb_state(evt.slave_id, evt.observed_winner);
			end

			else if (evt.axi_op==1) begin
				if (evt.m0_requesting && evt.m1_requesting) begin
					predicted = ref_model.predict_read_winner(evt.slave_id, evt.m0_requesting, evt.m1_requesting);
					check(predicted == evt.observed_winner, 
						$sformatf("arbitration winner (slave %0d)", evt.slave_id), 
						$sformatf("%0d", predicted),
						$sformatf("%0d", evt.observed_winner));
				end
                ref_model.update_r_arb_state(evt.slave_id, evt.observed_winner);
                end
            end

        join_none
    endtask
endclass
