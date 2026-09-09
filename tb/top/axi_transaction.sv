import axi_param_pkg::*;

class transaction;
  rand axi_opt                axi_op;	
  rand bit                    master_id;
  bit                         slave_id;
  bit 			      decode_err = 1'b0;

  //AW CHANNEL
  rand bit [ADDR_WIDTH-1:0]   m_awaddr;
  randc bit [ID_WIDTH-1:0]     m_awid;
  rand bit [LEN_WIDTH-1:0]    m_awlen;
  rand bit [SIZE_WIDTH-1:0]   m_awsize;
  rand bit [BURST_TYPE-1:0]   m_awburst;

  bit [31:0] m_awaddr_beat[];

  rand bit [DATA_WIDTH-1:0]   m_wdata[];
  rand bit [DATA_WIDTH/8-1:0] m_wstrb[];

  bit [TAG_WIDTH-1:0]         bid;
  bit [1:0]                   bresp;

  //AR CHANNEL
  rand bit [ADDR_WIDTH-1:0]   m_araddr;
  randc bit [ID_WIDTH-1:0]     m_arid;
  rand bit [LEN_WIDTH-1:0]    m_arlen;
  rand bit [SIZE_WIDTH-1:0]   m_arsize;
  rand bit [BURST_TYPE-1:0]   m_arburst;

  //R CHANNEL

  bit [DATA_WIDTH-1:0] rdata[];
  bit [TAG_WIDTH-1:0] rid[];
  bit [1:0] rresp[];
  int signed expected_slave_id;


function void display(string tag);
    string wdata_str, wstrb_str;
    string rdata_str, rid_str, rresp_str;
    case(axi_op)
        AXI_WRITE: begin
            if (decode_err)
                $display("[%0t] [%s] mst_id=%0d awid=%0d awaddr=%0h DECODE_ERROR bresp=%0b bid=%0b",
                    $time, tag, master_id, m_awid, m_awaddr, bresp, bid);
            else begin
                wdata_str = "";
                wstrb_str = "";
                foreach (m_wdata[i])
                    wdata_str = {wdata_str, $sformatf("%0h ", m_wdata[i])};
                foreach (m_wstrb[i])
                    wstrb_str = {wstrb_str, $sformatf("%0h ", m_wstrb[i])};

                $display("[%0t] [%0s] mst_id=%0d s_id=%0b awaddr=%0h awid=%0b awlen=%0d awsize=%0d awburst=%0d wdata=[%s] wstrb=[%s] bresp=%0b bid=%0b",
                    $time, tag, master_id, slave_id, m_awaddr, m_awid, m_awlen, m_awsize, m_awburst, wdata_str, wstrb_str, bresp, bid);
            end
        end
        AXI_READ: begin
	       	    rresp_str="";
		    rid_str="";
		    rdata_str = "";
		    foreach (rid[i])
			    rid_str={rid_str, $sformatf("%0h", rid[i])};
		    foreach (rresp[i])
			    rresp_str={rresp_str, $sformatf("%0h", rresp[i])};
		    foreach (rdata[i])
			    rdata_str={rdata_str, $sformatf("%0h", rdata[i])};


		if (decode_err) begin
		                   $display("[%0t] [%s] mst_id=%0d arid=%0d araddr=%0h DECODE_ERROR rresp=[%s] rid=[%s] rdata=[%s]",
                    $time, tag, master_id, m_arid, m_araddr, rresp_str, rid_str, rdata_str);
	    end
            else begin
		  		   
                $display("[%0t] [%s] READ mst_id=%0d s_id=%0d araddr=%0h arid=%0d arlen=%0d arsize=%0d arburst=%0d rid=[%s] rresp=[%s] rdata=[%s]",
                    $time, tag, master_id, slave_id, m_araddr, m_arid, m_arlen, m_arsize, m_arburst, rid_str, rresp_str, rdata_str);
	    end
    end
    endcase
endfunction


endclass
