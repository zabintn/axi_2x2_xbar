class slave_agent;
    int id;
    slave_driver  sdrv;
    slave_monitor smon;
    mailbox mon2sb_s;
    virtual axi_xbar_if axi_vif;

    function new(int id, virtual axi_xbar_if axi_vif, mailbox mon2sb_s);
        this.id       = id;
        this.axi_vif  = axi_vif;
        this.mon2sb_s = mon2sb_s;
        sdrv = new(id, axi_vif);
        smon = new(id, mon2sb_s, axi_vif);
    endfunction

    task run();
        fork
            sdrv.run();
            smon.run();
        join_none
    endtask
endclass
