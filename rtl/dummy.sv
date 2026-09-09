`timescale 1ns/1ps

module tb_axi_xbar;

    parameter ADDR_WIDTH  = 32;
    parameter DATA_WIDTH  = 64;
    parameter ID_WIDTH    = 4;
    parameter LEN_WIDTH   = 8;
    parameter SIZE_WIDTH  = 3;
    parameter BURST_TYPE  = 2;
    parameter TAG_WIDTH   = ID_WIDTH + 1;

    //============================================================
    // Clock / Reset
    //============================================================

    reg aclk;
    reg arst_n;

    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    initial begin
        arst_n = 0;
        repeat (5) @(posedge aclk);
        arst_n = 1;
    end


    //============================================================
    // M0 AW
    //============================================================

    reg [ADDR_WIDTH-1:0]  m0_awaddr;
    reg [ID_WIDTH-1:0]    m0_awid;
    reg [LEN_WIDTH-1:0]   m0_awlen;
    reg [SIZE_WIDTH-1:0]  m0_awsize;
    reg [BURST_TYPE-1:0]  m0_awburst;
    reg                   m0_awvalid;
    wire                  m0_awready;


    //============================================================
    // M1 AW
    //============================================================

    reg [ADDR_WIDTH-1:0]  m1_awaddr;
    reg [ID_WIDTH-1:0]    m1_awid;
    reg [LEN_WIDTH-1:0]   m1_awlen;
    reg [SIZE_WIDTH-1:0]  m1_awsize;
    reg [BURST_TYPE-1:0]  m1_awburst;
    reg                   m1_awvalid;
    wire                  m1_awready;


    //============================================================
    // S0 AW
    //============================================================

    wire [ADDR_WIDTH-1:0] s0_awaddr;
    wire [TAG_WIDTH-1:0] s0_awid;
    wire [LEN_WIDTH-1:0] s0_awlen;
    wire [SIZE_WIDTH-1:0] s0_awsize;
    wire [BURST_TYPE-1:0] s0_awburst;
    reg                   s0_awready;


    //============================================================
    // S1 AW
    //============================================================

    wire [ADDR_WIDTH-1:0] s1_awaddr;
    wire [TAG_WIDTH-1:0] s1_awid;
    wire [LEN_WIDTH-1:0] s1_awlen;
    wire [SIZE_WIDTH-1:0] s1_awsize;
    wire [BURST_TYPE-1:0] s1_awburst;
    reg                   s1_awready;


    //============================================================
    // M0 W
    //============================================================

    reg [DATA_WIDTH-1:0]  m0_wdata;
    reg [DATA_WIDTH/8-1:0] m0_wstrb;
    reg                    m0_wlast;
    reg                    m0_wvalid;
    wire                   m0_wready;


    //============================================================
    // M1 W
    //============================================================

    reg [DATA_WIDTH-1:0]  m1_wdata;
    reg [DATA_WIDTH/8-1:0] m1_wstrb;
    reg                    m1_wlast;
    reg                    m1_wvalid;
    wire                   m1_wready;


    //============================================================
    // Slave WREADY
    //============================================================

    reg s0_wready;
    reg s1_wready;


    //============================================================
    // M0 B
    //============================================================

    wire [ID_WIDTH-1:0] m0_bid;
    wire [1:0]          m0_bresp;
    wire                m0_bvalid;
    reg                 m0_bready;


    //============================================================
    // M1 B
    //============================================================

    wire [ID_WIDTH-1:0] m1_bid;
    wire [1:0]          m1_bresp;
    wire                m1_bvalid;
    reg                 m1_bready;


    //============================================================
    // Slave B
    //============================================================

    reg [1:0] s0_bresp;
    reg       s0_bvalid;

    reg [1:0] s1_bresp;
    reg       s1_bvalid;


    //============================================================
    // DUT
    //============================================================

    axi_xbar_top #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .LEN_WIDTH  (LEN_WIDTH),
        .SIZE_WIDTH (SIZE_WIDTH),
        .BURST_TYPE (BURST_TYPE),
        .TAG_WIDTH  (TAG_WIDTH)
    ) dut (

        .aclk       (aclk),
        .arst_n     (arst_n),

        //--------------- M0 AW ----------------
        .m0_awaddr  (m0_awaddr),
        .m0_awid    (m0_awid),
        .m0_awlen   (m0_awlen),
        .m0_awsize  (m0_awsize),
        .m0_awburst (m0_awburst),
        .m0_awvalid (m0_awvalid),

        //--------------- M1 AW ----------------
        .m1_awaddr  (m1_awaddr),
        .m1_awid    (m1_awid),
        .m1_awlen   (m1_awlen),
        .m1_awsize  (m1_awsize),
        .m1_awburst (m1_awburst),
        .m1_awvalid (m1_awvalid),

        //--------------- S0 AW ----------------
        .s0_awaddr  (s0_awaddr),
        .s0_awid    (s0_awid),
        .s0_awlen   (s0_awlen),
        .s0_awsize  (s0_awsize),
        .s0_awburst (s0_awburst),
        .s0_awready (s0_awready),

        //--------------- S1 AW ----------------
        .s1_awaddr  (s1_awaddr),
        .s1_awid    (s1_awid),
        .s1_awlen   (s1_awlen),
        .s1_awsize  (s1_awsize),
        .s1_awburst (s1_awburst),
        .s1_awready (s1_awready),

        //--------------- M0 W -----------------
        .m0_wdata   (m0_wdata),
        .m0_wstrb   (m0_wstrb),
        .m0_wlast   (m0_wlast),
        .m0_wvalid  (m0_wvalid),
        .m0_wready  (m0_wready),

        //--------------- M1 W -----------------
        .m1_wdata   (m1_wdata),
        .m1_wstrb   (m1_wstrb),
        .m1_wlast   (m1_wlast),
        .m1_wvalid  (m1_wvalid),
        .m1_wready  (m1_wready),

        //--------------- Slave WREADY ---------
        .s0_wready  (s0_wready),
        .s1_wready  (s1_wready),

        //--------------- M0 B -----------------
        .m0_bid     (m0_bid),
        .m0_bresp   (m0_bresp),
        .m0_bvalid  (m0_bvalid),
        .m0_bready  (m0_bready),

        //--------------- M1 B -----------------
        .m1_bid     (m1_bid),
        .m1_bresp   (m1_bresp),
        .m1_bvalid  (m1_bvalid),
        .m1_bready  (m1_bready),

        //--------------- S0 B -----------------
        .s0_bresp   (s0_bresp),
        .s0_bvalid  (s0_bvalid),

        //--------------- S1 B -----------------
        .s1_bresp   (s1_bresp),
        .s1_bvalid  (s1_bvalid)
    );


    //============================================================
    // Initial values
    //============================================================

/*    initial begin

        m0_awaddr  = '0;
        m0_awid    = '0;
        m0_awlen   = '0;
        m0_awsize  = '0;
        m0_awburst = '0;
        m0_awvalid = 0;

        m1_awaddr  = '0;
        m1_awid    = '0;
        m1_awlen   = '0;
        m1_awsize  = '0;
        m1_awburst = '0;
        m1_awvalid = 0;

        m0_wdata   = '0;
        m0_wstrb   = '0;
        m0_wlast   = 0;
        m0_wvalid  = 0;

        m1_wdata   = '0;
        m1_wstrb   = '0;
        m1_wlast   = 0;
        m1_wvalid  = 0;

        s0_awready = 0;
        s1_awready = 0;

        s0_wready  = 0;
        s1_wready  = 0;

        s0_bresp   = 2'b00;
        s0_bvalid  = 0;

        s1_bresp   = 2'b00;
        s1_bvalid  = 0;

        m0_bready  = 0;
        m1_bready  = 0;

    end 
    */


    //============================================================
    // TEST SEQUENCE
    //============================================================

    initial begin

        wait(arst_n);

        // Give yourself a cycle after reset
        @(posedge aclk);


        //========================================================
        // TEST 1
        // M0 -> S0
        //========================================================

        // Fill in your values here
        m0_awaddr  = 32'h0000_0001;
        m0_awid    = 4'b0101;
        m0_awlen   = 8'd0;
        m0_awsize  = 3'd3;
        m0_awburst = 2'b01;
        m0_awvalid = 1'b1;

        s0_awready = 1'b1;

        @(posedge aclk);

        while (!m0_awready)
            @(posedge aclk);

        m0_awvalid = 1'b0;
        s0_awready = 1'b0;


        //========================================================
        // W CHANNEL
        //========================================================

        m0_wdata  = 64'hDEAD_BEEF_1234_5678;
        m0_wstrb  = 8'hFF;
        m0_wlast  = 1'b1;
        m0_wvalid = 1'b1;

        s0_wready = 1'b1;

        @(posedge aclk);

        while (!m0_wready)
            @(posedge aclk);

        m0_wvalid = 1'b0;
        m0_wlast  = 1'b0;
        s0_wready = 1'b0;


        //========================================================
        // SLAVE GENERATES B RESPONSE
        //========================================================

        // Fill in response
        s0_bresp  = 2'b00;
        s0_bvalid = 1'b1;

        m0_bready = 1'b1;

        @(posedge aclk);

        while (!m0_bvalid)
            @(posedge aclk);

        @(posedge aclk);

        s0_bvalid = 1'b0;
        m0_bready = 1'b0;


        //========================================================
        // TEST 2
        // Put next test here
        //========================================================


        repeat (10) @(posedge aclk);

        $finish;

    end


    //============================================================
    // MONITOR
    //============================================================

    always @(posedge aclk) begin

        if (m0_awvalid && m0_awready)
            $display("[%0t] M0 AW handshake: addr=%h id=%h",
                     $time, m0_awaddr, m0_awid);

        if (m1_awvalid && m1_awready)
            $display("[%0t] M1 AW handshake: addr=%h id=%h",
                     $time, m1_awaddr, m1_awid);

        if (m0_wvalid && m0_wready)
            $display("[%0t] M0 W handshake: data=%h last=%b",
                     $time, m0_wdata, m0_wlast);

        if (m1_wvalid && m1_wready)
            $display("[%0t] M1 W handshake: data=%h last=%b",
                     $time, m1_wdata, m1_wlast);

        if (m0_bvalid && m0_bready)
            $display("[%0t] M0 B handshake: bid=%h resp=%b",
                     $time, m0_bid, m0_bresp);

        if (m1_bvalid && m1_bready)
            $display("[%0t] M1 B handshake: bid=%h resp=%b",
                     $time, m1_bid, m1_bresp);

    end

endmodule
