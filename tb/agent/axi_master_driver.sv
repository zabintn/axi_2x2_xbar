`timescale 1ns/1ps
import axi_param_pkg::*;
class master_driver;
  int unsigned            id;      // 0 or 1
  virtual axi_xbar_if     axi_vif;
  mailbox gen2drv;

  function new(int unsigned id, virtual axi_xbar_if axi_vif, mailbox gen2drv);
    this.id = id; 
    this.axi_vif = axi_vif; 
    this.gen2drv = gen2drv;
  endfunction

  task run();
    forever begin
      transaction tr;
      gen2drv.get(tr);
       $display(
            "[%0t] MASTER_DRIVER%0d received transaction, op=%s",
            $time,
            id,
            tr.axi_op.name()
        );

      case(tr.axi_op)
	      AXI_WRITE: begin
			      do_aw(tr);
			      do_w(tr);
		      fork
			      automatic transaction btr=tr;
		      begin
			      do_b(btr);
			      btr.display("MASTER DRIVER");
		      end
	      	join_none
      		end
	      AXI_READ: begin
		      do_ar(tr);
		      fork
			      automatic transaction rtr=tr;
		      begin
			      do_r(rtr);
			      rtr.display("MASTER DRIVER");
		      end
	      join_none
      end
      endcase
    end
  endtask

  task do_aw(transaction tr);
    @(posedge axi_vif.aclk);
    if (id == 0) begin
      axi_vif.m0_awid    <= tr.m_awid;
      axi_vif.m0_awaddr  <= tr.m_awaddr;
      axi_vif.m0_awlen   <= tr.m_awlen;
      axi_vif.m0_awsize  <= tr.m_awsize;
      axi_vif.m0_awburst <= tr.m_awburst;
      axi_vif.m0_awvalid <= 1'b1;
      do @(posedge axi_vif.aclk); while (!axi_vif.m0_awready);
      axi_vif.m0_awvalid <= 1'b0;
    end else begin
      axi_vif.m1_awid    <= tr.m_awid;
      axi_vif.m1_awaddr  <= tr.m_awaddr;
      axi_vif.m1_awlen   <= tr.m_awlen;
      axi_vif.m1_awsize  <= tr.m_awsize;
      axi_vif.m1_awburst <= tr.m_awburst;
      axi_vif.m1_awvalid <= 1'b1;
      do @(posedge axi_vif.aclk); while (!axi_vif.m1_awready);
      axi_vif.m1_awvalid <= 1'b0;
    end
  endtask

task do_w(transaction tr);
  int num_beats;
  int i;
  num_beats = tr.m_awlen + 1;
  i = 0;

  @(posedge axi_vif.aclk);
  forever begin
    if (id == 0) begin
      axi_vif.m0_wdata  <= tr.m_wdata[i];
      axi_vif.m0_wstrb  <= tr.m_wstrb[i];
      axi_vif.m0_wlast  <= (i == num_beats-1);
      axi_vif.m0_wvalid <= 1'b1;
      @(posedge axi_vif.aclk);
      if (axi_vif.m0_wready) i++;
    end 
    else begin
      axi_vif.m1_wdata  <= tr.m_wdata[i];
      axi_vif.m1_wstrb  <= tr.m_wstrb[i];
      axi_vif.m1_wlast  <= (i == num_beats-1);
      axi_vif.m1_wvalid <= 1'b1;
      @(posedge axi_vif.aclk);
      if (axi_vif.m1_wready) i++;
    end
    if (i == num_beats) break;
  end

  if (id == 0) axi_vif.m0_wvalid <= 1'b0;
  else         axi_vif.m1_wvalid <= 1'b0;
endtask
task do_b(transaction tr);
    if (id == 0) begin
        do @(posedge axi_vif.aclk);
        while (!((axi_vif.m0_bvalid &&
                axi_vif.m0_bready) && (axi_vif.m0_bid == tr.m_awid)));

        tr.bid   = axi_vif.m0_bid;
        tr.bresp = axi_vif.m0_bresp;

	$display("[%0t] MASTER 0 RECEIVED BRESP. BRESP=%0b", $time, tr.bresp);
    end
    else begin
        do @(posedge axi_vif.aclk);
        while (!((axi_vif.m1_bvalid &&
                axi_vif.m1_bready) && (axi_vif.m1_bid == tr.m_awid)));
        tr.bid   = axi_vif.m1_bid;
        tr.bresp = axi_vif.m1_bresp;

	$display("[%0t] MASTER 1 RECEIVED BRESP. BRESP=%0b", $time, tr.bresp);
   end
endtask
task do_ar(transaction tr);
    @(posedge axi_vif.aclk);
    if (id == 0) begin
      axi_vif.m0_arid    <= tr.m_arid;
      axi_vif.m0_araddr  <= tr.m_araddr;
      axi_vif.m0_arlen   <= tr.m_arlen;
      axi_vif.m0_arsize  <= tr.m_arsize;
      axi_vif.m0_arburst <= tr.m_arburst;
      axi_vif.m0_arvalid <= 1'b1;
      do @(posedge axi_vif.aclk); while (!axi_vif.m0_arready);
      axi_vif.m0_arvalid <= 1'b0;
    end else begin
      axi_vif.m1_arid    <= tr.m_arid;
      axi_vif.m1_araddr  <= tr.m_araddr;
      axi_vif.m1_arlen   <= tr.m_arlen;
      axi_vif.m1_arsize  <= tr.m_arsize;
      axi_vif.m1_arburst <= tr.m_arburst;
      axi_vif.m1_arvalid <= 1'b1;
      do @(posedge axi_vif.aclk); while (!axi_vif.m1_arready);
      axi_vif.m1_arvalid <= 1'b0;
    end
    endtask
task do_r(transaction tr);
  int num_beats;
  int i;
  bit rlast_seen;
  num_beats = tr.m_arlen + 1;
  i = 0;
  rlast_seen = 1'b0;

  tr.rdata = new[num_beats];
  tr.rresp = new[num_beats];
  tr.rid   = new[num_beats];

  if (id == 0) axi_vif.m0_rready <= 1'b1;
  else         axi_vif.m1_rready <= 1'b1;

  while (!rlast_seen) begin
    @(posedge axi_vif.aclk);
    if (id == 0) begin
      if ((axi_vif.m0_rvalid && axi_vif.m0_rready) && (axi_vif.m0_rid==tr.m_arid)) begin
        tr.rdata[i] = axi_vif.m0_rdata;
        tr.rresp[i] = axi_vif.m0_rresp;
        tr.rid[i]   = axi_vif.m0_rid;
        rlast_seen  = axi_vif.m0_rlast;
        i++;
      end
    end else begin
      if ((axi_vif.m1_rvalid && axi_vif.m1_rready) && (axi_vif.m1_rid==tr.m_arid)) begin
        tr.rdata[i] = axi_vif.m1_rdata;
        tr.rresp[i] = axi_vif.m1_rresp;
        tr.rid[i]   = axi_vif.m1_rid;
        rlast_seen  = axi_vif.m1_rlast;
        i++;
      end
    end
  end

endtask
endclass
