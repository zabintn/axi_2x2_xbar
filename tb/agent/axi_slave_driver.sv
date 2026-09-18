import axi_param_pkg::*;

class slave_driver;
  virtual axi_xbar_if axi_vif;
  logic [DATA_WIDTH-1:0] s0_memory [logic[ADDR_WIDTH-1:0]];
  logic [DATA_WIDTH-1:0] s1_memory [logic[ADDR_WIDTH-1:0]];

  function new(virtual axi_xbar_if axi_vif);
    this.axi_vif = axi_vif;
    $display("[%0t] SLAVE CONSTRUCTED", $time);
  endfunction

  task run();
	  axi_vif.s0_rlast <= 1'b0;
    axi_vif.s1_rlast <= 1'b0;
    fork
      run_s0();
      run_s1();
      run_s0_ar();
      run_s1_ar();
    join_none
  endtask

  // S0
  task run_s0();
    logic [TAG_WIDTH-1:0] captured_id;
    logic [ADDR_WIDTH-1:0] captured_addr;
    logic [DATA_WIDTH-1:0] captured_data;
    logic [LEN_WIDTH-1:0]  captured_len;
    logic [SIZE_WIDTH-1:0] captured_size;
    logic [BURST_TYPE-1:0] captured_burst;
    logic [ADDR_WIDTH-1:0] beat_addr;
    int   bytes_per_beat;
    int   beat_cnt;
    bit   wlast_seen;


    forever begin
      // AW phase
      axi_vif.s0_awready <= 1'b1;
      @(posedge axi_vif.aclk);
      while (!(axi_vif.s0_awvalid && axi_vif.s0_awready))
        @(posedge axi_vif.aclk);
	$display("[%0t] AXI S0_AWVALID_RDY HANDSHAKE", $time);
      captured_id = axi_vif.s0_awid;
      captured_addr=axi_vif.s0_awaddr;
      captured_len=axi_vif.s0_awlen;
      captured_size=axi_vif.s0_awsize;
      captured_burst=axi_vif.s0_awburst;
      axi_vif.s0_awready <= 1'b0;

      // W phase

      bytes_per_beat = 1 << captured_size;
      beat_addr      = captured_addr;
      beat_cnt       = 0;
      wlast_seen     = 1'b0;


      axi_vif.s0_wready <= 1'b1;
      axi_vif.s0_wready <= 1'b1;
      while (!wlast_seen) begin
	      @(posedge axi_vif.aclk);
	 	while (!(axi_vif.s0_wvalid && axi_vif.s0_wready))
        	@(posedge axi_vif.aclk);
    $display("[%0t] AXI S0_WVALID_RDY HANDSHAKE", $time);

    captured_data = axi_vif.s0_wdata;
    wlast_seen    = axi_vif.s0_wlast;

    s0_memory[beat_addr] = captured_data;
    $display("[%0t] S0 MEMORY WRITE beat=%0d addr=%h data=%h id=%h",
              $time, beat_cnt, beat_addr, captured_data, captured_id);

    case (captured_burst)
        2'b00: ;
        2'b01: beat_addr = beat_addr + bytes_per_beat;
        2'b10: begin
            int wrap_size;
            logic [ADDR_WIDTH-1:0] wrap_hi, wrap_lo, next_addr;
            wrap_size = bytes_per_beat * (captured_len + 1);
            wrap_lo   = (captured_addr / wrap_size) * wrap_size;
            wrap_hi   = wrap_lo + wrap_size;
            next_addr = beat_addr + bytes_per_beat;
            beat_addr = (next_addr >= wrap_hi) ? wrap_lo : next_addr;
        end
    endcase
    beat_cnt++;
end
axi_vif.s0_wready <= 1'b0;    

      // B phase
      axi_vif.s0_bid    <= captured_id;
      axi_vif.s0_bresp  <= 2'b00;
      axi_vif.s0_bvalid <= 1'b1;
      do @(posedge axi_vif.aclk); while (!axi_vif.s0_bready);

      axi_vif.s0_bvalid <= 1'b0;

      $display("[%0t] SLAVE0 sent B resp, id=%0d", $time, captured_id[ID_WIDTH-1:0]);

    end
  endtask

  // S1
task run_s1();
    logic [TAG_WIDTH-1:0]  captured_id;
    logic [ADDR_WIDTH-1:0] captured_addr;
    logic [DATA_WIDTH-1:0] captured_data;
    logic [LEN_WIDTH-1:0]  captured_len;
    logic [SIZE_WIDTH-1:0] captured_size;
    logic [BURST_TYPE-1:0] captured_burst;
    logic [ADDR_WIDTH-1:0] beat_addr;
    int   bytes_per_beat;
    int   beat_cnt;
    bit   wlast_seen;

    forever begin
      axi_vif.s1_awready <= 1'b1;
      @(posedge axi_vif.aclk);
      while (!(axi_vif.s1_awvalid && axi_vif.s1_awready))
        @(posedge axi_vif.aclk);
      $display("[%0t] AXI S1_AWVALID_RDY HANDSHAKE", $time);
      captured_id    = axi_vif.s1_awid;
      captured_addr  = axi_vif.s1_awaddr;
      captured_len   = axi_vif.s1_awlen;
      captured_size  = axi_vif.s1_awsize;
      captured_burst = axi_vif.s1_awburst;
      axi_vif.s1_awready <= 1'b0;

      bytes_per_beat = 1 << captured_size;
      beat_addr      = captured_addr;
      beat_cnt       = 0;
      wlast_seen     = 1'b0;

      axi_vif.s1_wready <= 1'b1;
      while (!wlast_seen) begin
        @(posedge axi_vif.aclk);
        while (!(axi_vif.s1_wvalid && axi_vif.s1_wready))
          @(posedge axi_vif.aclk);

        captured_data = axi_vif.s1_wdata;
        wlast_seen    = axi_vif.s1_wlast;

        s1_memory[beat_addr] = captured_data;
        $display("[%0t] S1 MEMORY WRITE beat=%0d addr=%h data=%h id=%h",
                  $time, beat_cnt, beat_addr, captured_data, captured_id);

        case (captured_burst)
          2'b00: ; // FIXED: address unchanged
          2'b01: beat_addr = beat_addr + bytes_per_beat; // INCR
          2'b10: begin // WRAP
            int wrap_size;
            logic [ADDR_WIDTH-1:0] wrap_lo, wrap_hi, next_addr;
            wrap_size = bytes_per_beat * (captured_len + 1);
            wrap_lo   = (captured_addr /wrap_size) * wrap_size;
            wrap_hi   = wrap_lo + wrap_size;
            next_addr = beat_addr + bytes_per_beat;
            beat_addr = (next_addr >= wrap_hi) ? wrap_lo : next_addr;
          end
        endcase
        beat_cnt++;
      end
      axi_vif.s1_wready <= 1'b0;

      axi_vif.s1_bid    <= captured_id;
      axi_vif.s1_bresp  <= 2'b00;
      axi_vif.s1_bvalid <= 1'b1;
      do @(posedge axi_vif.aclk); while (!axi_vif.s1_bready);
      axi_vif.s1_bvalid <= 1'b0;
      $display("[%0t] SLAVE1 sent B resp, id=%0d", $time, captured_id[ID_WIDTH-1:0]);
    end
endtask

//ERROR RESPONSE
  task run_m0_err();
  logic [ID_WIDTH-1:0] err_id;

  forever begin
    @(posedge axi_vif.aclk);

    if (axi_vif.m0_decode_error) begin

      err_id = axi_vif.m0_awid;

      $display("[%0t] SLAVE(err) M0 decode error, id=%0d",
               $time, err_id);

      // Accept the W beat

      // Wait for W handshake
      do begin
        @(posedge axi_vif.aclk);
      end while (!(axi_vif.m0_wvalid &&
                   axi_vif.m0_wready &&
                   axi_vif.m0_wlast));


      // Return DECERR
      axi_vif.m0_bid    <= err_id;
      axi_vif.m0_bresp  <= 2'b11;
      axi_vif.m0_bvalid <= 1'b1;

      // Wait for B handshake
      do begin
        @(posedge axi_vif.aclk);
      end while (!axi_vif.m0_bready);

      axi_vif.m0_bvalid <= 1'b0;

      $display("[%0t] SLAVE(err) M0 sent DECERR, id=%0d",
               $time, err_id);
    end
  end
endtask


task run_m1_err();
  logic [ID_WIDTH-1:0] err_id;

  forever begin
    @(posedge axi_vif.aclk);

    if (axi_vif.m1_decode_error) begin

      err_id = axi_vif.m1_awid;

      $display("[%0t] SLAVE(err) M1 decode error, id=%0d",
               $time, err_id);

      // Accept the W beat

      // Wait for W handshake
      do begin
        @(posedge axi_vif.aclk);
      end while (!(axi_vif.m1_wvalid &&
                   axi_vif.m1_wready &&
                   axi_vif.m1_wlast));


      // Return DECERR
      axi_vif.m1_bid    <= err_id;
      axi_vif.m1_bresp  <= 2'b11;
      axi_vif.m1_bvalid <= 1'b1;

      // Wait for B handshake
      do begin
        @(posedge axi_vif.aclk);
      end while (!axi_vif.m1_bready);

      axi_vif.m1_bvalid <= 1'b0;

      $display("[%0t] SLAVE(err) M1 sent DECERR, id=%0d",
               $time, err_id);
    end
  end
endtask

//===============================READ PATh ==============================

task run_s0_ar();
    logic [TAG_WIDTH-1:0]  captured_id;
    logic [ADDR_WIDTH-1:0] captured_addr;
    logic [LEN_WIDTH-1:0]  captured_len;
    logic [SIZE_WIDTH-1:0] captured_size;
    logic [BURST_TYPE-1:0] captured_burst;
    logic [ADDR_WIDTH-1:0] beat_addr;
    logic [DATA_WIDTH-1:0] read_data;
    int bytes_per_beat;
    int beat_cnt;

    forever begin
        axi_vif.s0_arready <= 1'b1;
        @(posedge axi_vif.aclk);
        while (!(axi_vif.s0_arvalid && axi_vif.s0_arready))
            @(posedge axi_vif.aclk);
        $display("[%0t] AXI S0_ARVALID_RDY HANDSHAKE", $time);
        captured_id    = axi_vif.s0_arid;
        captured_addr  = axi_vif.s0_araddr;
        captured_len   = axi_vif.s0_arlen;
        captured_size  = axi_vif.s0_arsize;
        captured_burst = axi_vif.s0_arburst;
        axi_vif.s0_arready <= 1'b0;

        bytes_per_beat = 1 << captured_size;
        beat_addr      = captured_addr;

        for (beat_cnt = 0; beat_cnt <= captured_len; beat_cnt++) begin
            if (s0_memory.exists(beat_addr)) begin
                read_data = s0_memory[beat_addr];
                $display("[%0t] MEMORY READ DONE beat=%0d addr=%0h data=%0h id=%0d",
                          $time, beat_cnt, beat_addr, read_data, captured_id);
            end
            else begin
                read_data = 64'hBAAD_F00D_1234_5678;
                $display("[%0t] MEMORY READ MISS beat=%0d addr=%0h -> default data id=%0d",
                          $time, beat_cnt, beat_addr, captured_id);
            end

            axi_vif.s0_rid    <= captured_id;
            axi_vif.s0_rresp  <= 2'b00;
            axi_vif.s0_rdata  <= read_data;
            axi_vif.s0_rlast  <= (beat_cnt == captured_len);
            axi_vif.s0_rvalid <= 1'b1;
            do @(posedge axi_vif.aclk); while (!axi_vif.s0_rready);
            axi_vif.s0_rvalid <= 1'b0;

            case (captured_burst)
                2'b00: ; // FIXED
                2'b01: beat_addr = beat_addr + bytes_per_beat; // INCR
                2'b10: begin // WRAP
                    int wrap_size;
                    logic [ADDR_WIDTH-1:0] wrap_lo, wrap_hi, next_addr;
                    wrap_size = bytes_per_beat * (captured_len + 1);
                    wrap_lo   = (captured_addr / wrap_size) * wrap_size;
                    wrap_hi   = wrap_lo + wrap_size;
                    next_addr = beat_addr + bytes_per_beat;
                    beat_addr = (next_addr >= wrap_hi) ? wrap_lo : next_addr;
                end
            endcase
        end
    end
endtask

task run_s1_ar();
    logic [TAG_WIDTH-1:0]  captured_id;
    logic [ADDR_WIDTH-1:0] captured_addr;
    logic [LEN_WIDTH-1:0]  captured_len;
    logic [SIZE_WIDTH-1:0] captured_size;
    logic [BURST_TYPE-1:0] captured_burst;
    logic [ADDR_WIDTH-1:0] beat_addr;
    logic [DATA_WIDTH-1:0] read_data;
    int bytes_per_beat;
    int beat_cnt;

    forever begin
        axi_vif.s1_arready <= 1'b1;
        @(posedge axi_vif.aclk);
        while (!(axi_vif.s1_arvalid && axi_vif.s1_arready))
            @(posedge axi_vif.aclk);
        $display("[%0t] AXI S0_ARVALID_RDY HANDSHAKE", $time);
        captured_id    = axi_vif.s1_arid;
        captured_addr  = axi_vif.s1_araddr;
        captured_len   = axi_vif.s1_arlen;
        captured_size  = axi_vif.s1_arsize;
        captured_burst = axi_vif.s1_arburst;
        axi_vif.s1_arready <= 1'b0;

        bytes_per_beat = 1 << captured_size;
        beat_addr      = captured_addr;

        for (beat_cnt = 0; beat_cnt <= captured_len; beat_cnt++) begin
            if (s1_memory.exists(beat_addr)) begin
                read_data = s1_memory[beat_addr];
                $display("[%0t] MEMORY READ DONE beat=%0d addr=%0h data=%0h id=%0d",
                          $time, beat_cnt, beat_addr, read_data, captured_id);
            end
            else begin
                read_data = 64'hBAAD_F00D_1234_5678;
                $display("[%0t] MEMORY READ MISS beat=%0d addr=%0h -> default data=%0h",
                          $time, beat_cnt, beat_addr, read_data);
            end

            axi_vif.s1_rid    <= captured_id;
            axi_vif.s1_rresp  <= 2'b00;
            axi_vif.s1_rdata  <= read_data;
            axi_vif.s1_rlast  <= (beat_cnt == captured_len);
            axi_vif.s1_rvalid <= 1'b1;
            do @(posedge axi_vif.aclk); while (!axi_vif.s1_rready);
            axi_vif.s1_rvalid <= 1'b0;

            case (captured_burst)
                2'b00: ; // FIXED
                2'b01: beat_addr = beat_addr + bytes_per_beat; // INCR
                2'b10: begin // WRAP
                    int wrap_size;
                    logic [ADDR_WIDTH-1:0] wrap_lo, wrap_hi, next_addr;
                    wrap_size = bytes_per_beat * (captured_len + 1);
                    wrap_lo   = (captured_addr / wrap_size) * wrap_size;
                    wrap_hi   = wrap_lo + wrap_size;
                    next_addr = beat_addr + bytes_per_beat;
                    beat_addr = (next_addr >= wrap_hi) ? wrap_lo : next_addr;
                end
            endcase
        end
    end
endtask



endclass
