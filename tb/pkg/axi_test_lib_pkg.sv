package axi_test_lib_pkg;
	import axi_param_pkg::*;
	import axi_env_pkg::*;
	`include "../test_lib/axi_base_test.sv"
       	`include "../test_lib/axi_write_test.sv"
	`include "../test_lib/axi_read_test.sv"
	`include "../test_lib/axi_error_test.sv"
	`include "../test_lib/axi_write_read.sv"
	`include "../test_lib/axi_arbitation_test.sv"
	`include "../test_lib/axi_no_contention_test.sv"
	`include "../test_lib/axi_partial_contention_test.sv"
	`include "../test_lib/axi_multi_txn.sv"
	`include "../test_lib/axi_burst_write.sv"
	`include "../test_lib/axi_reset_test.sv"
endpackage
