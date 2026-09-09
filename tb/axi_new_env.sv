class env;
    master_agent m_agent0, m_agent1;
    slave_agent  s_agent0, s_agent1;
    generator    gen;
    mailbox gen2drv0, gen2drv1;
    mailbox mon2sb_s, mon2sb_m;
    virtual axi_xbar_if axi_vif;

    function new(mailbox mon2sb_m, mailbox mon2sb_s, virtual axi_xbar_if axi_vif);
        this.mon2sb_m = mon2sb_m;
        this.mon2sb_s = mon2sb_s;
        this.axi_vif  = axi_vif;

        gen2drv0 = new();
        gen2drv1 = new();

        m_agent0 = new(0, axi_vif, gen2drv0, mon2sb_m);
        m_agent1 = new(1, axi_vif, gen2drv1, mon2sb_m);
        s_agent0 = new(0, axi_vif, mon2sb_s);
        s_agent1 = new(1, axi_vif, mon2sb_s);

        gen = new(gen2drv0, gen2drv1);
    endfunction

    task run();
        fork
            m_agent0.run();
            m_agent1.run();
            s_agent0.run();
            s_agent1.run();
        join_none
    endtask
endclass
