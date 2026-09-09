`timescale 1ns/1ps
import axi_param_pkg::*;
class env;

        agent agt;
        scoreboard sb;

        mailbox mon2sb_s;
	mailbox mon2sb_m;
	mailbox mon2sb_arb;

        function new(virtual axi_xbar_if axi_vif);
		mon2sb_m=new();
                mon2sb_s=new();
		mon2sb_arb=new();
		$display("[%0t] ENV: before agent", $time);
                agt=new(mon2sb_m, mon2sb_s, mon2sb_arb, axi_vif);
		$display("[%0t] ENV: after agent", $time);
		$display("[%0t] ENV: before scoreboard", $time);       
		sb=new(mon2sb_m, mon2sb_s, mon2sb_arb);
		$display("[%0t] ENV: after scoreboard", $time);
        endfunction
endclass
