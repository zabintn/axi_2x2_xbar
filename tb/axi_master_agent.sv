class master_agent;
    int id;
    master_driver  mdrv;
    master_monitor mmon;
    mailbox gen2drv;
    mailbox mon2sb_m;
    virtual axi_xbar_if axi_vif;

    function new(int id, virtual axi_xbar_if axi_vif, mailbox gen2drv, mailbox mon2sb_m);
        this.id       = id;
        this.axi_vif  = axi_vif;
        this.gen2drv  = gen2drv;
        this.mon2sb_m = mon2sb_m;
        mdrv = new(id, axi_vif, gen2drv);
        mmon = new(id, mon2sb_m, axi_vif);
    endfunction

    task drive_bready();
        forever begin
            @(posedge axi_vif.aclk);
            if (id == 0) begin
                axi_vif.m0_bready <= 1'b1;
                axi_vif.m0_rready <= 1'b1;
            end else begin
                axi_vif.m1_bready <= 1'b1;
                axi_vif.m1_rready <= 1'b1;
            end
        end
    endtask

    task run();
        fork
            mdrv.run();
            mmon.run();
            drive_bready();
        join_none
    endtask
endclass
