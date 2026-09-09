`timescale 1ns/1ps

class generator;
	
	mailbox gen2drv0;
	mailbox gen2drv1;
	int count;
	int unsigned next_read_id[2];

	function new(mailbox gen2drv0, mailbox gen2drv1);
		this.gen2drv0=gen2drv0;
		this.gen2drv1=gen2drv1;
		next_read_id[0] = 0;
		next_read_id[1] = 0;
		$display("GENERATOR CONSTRUCTED");
	endfunction

	task rand_run();
		for (int i=0; i<count; i++) begin
			transaction tr;
			tr = new();
		assert (tr.randomize() with {
        m_awaddr < 32'h1FFF_FFFF;
        m_awaddr[2:0] == 3'b000;
        m_awlen   == 8'd1;
        m_awsize  == 3'd3;
        m_awburst == 2'b01;
        m_wdata.size() == m_awlen + 1;   
        m_wstrb.size() == m_awlen + 1; 
        m_araddr < 32'h1FFF_FFFF;
        m_araddr[2:0] == 3'b000;
        m_arlen   == 8'd1;
        m_arsize  == 3'd3;
        m_arburst == 2'b01;
        }) else
        $fatal(1, "Transaction randomization failed");
			// Unique ARID for each master
            		tr.m_arid = next_read_id[tr.master_id];
            		next_read_id[tr.master_id]++;

			tr.display("SEQUENCER");
			if (tr.master_id==0)
				gen2drv0.put(tr);
			else 
				gen2drv1.put(tr);
		end
	endtask
	
	task run(
		axi_opt axi_op,
		bit master_id,
		bit [31:0] m_awaddr,
		bit [3:0]  m_awid,
		bit [7:0]  m_awlen   = 8'd0,
		bit [2:0]  m_awsize  = 3'd3,
		bit [1:0]  m_awburst = 2'b01,
		bit [63:0] m_wdata[],
		bit [7:0] m_wstrb[]
		);
		
		transaction tr;
		
		tr = new();
		tr.axi_op    = axi_op;
		tr.master_id = master_id;
		tr.m_awaddr  = m_awaddr;
		tr.m_awaddr_beat = new[m_awlen+1];
		tr.m_awaddr_beat[0] = m_awaddr;
		for (int i = 1; i <= m_awlen; i++)
			tr.m_awaddr_beat[i] = calc_beat_addr(tr.m_awaddr_beat[i-1], m_awburst, m_awsize, m_awlen);
		tr.m_awid    = m_awid;
		tr.m_awlen   = m_awlen;
		tr.m_awsize  = m_awsize;
		tr.m_awburst = m_awburst;
		tr.m_wdata   = m_wdata;
		tr.m_wstrb   = m_wstrb;
		if (m_wdata.size() != m_awlen+1 || m_wstrb.size() != m_awlen+1)
			$fatal(1, "m_wdata/m_wstrb size (%0d/%0d) does not match awlen+1 (%0d)", m_wdata.size(), m_wstrb.size(), m_awlen+1);
		tr.display("GEN-DIRECTED");
		if (tr.master_id==0) 
			gen2drv0.put(tr);
		else gen2drv1.put(tr);
	endtask
	task read_run(
		axi_opt axi_op,
		bit master_id,
		bit [31:0] m_araddr,
		bit [3:0]  m_arid,
		bit [7:0]  m_arlen   = 8'd0,
		bit [2:0]  m_arsize  = 3'd3,
		bit [1:0]  m_arburst = 2'b01
		);
		
		transaction tr;
		
		tr = new();
		tr.axi_op    = axi_op;
		tr.master_id = master_id;
		tr.m_araddr  = m_araddr;
		tr.m_arid    = m_arid;
		tr.m_arlen   = m_arlen;
		tr.m_arsize  = m_arsize;
		tr.m_arburst = m_arburst;

		tr.display("GEN-DIRECTED");
		if (tr.master_id==0) 
			gen2drv0.put(tr);
		else gen2drv1.put(tr);
	endtask
	
endclass



