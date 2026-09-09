package axi_env_pkg;

    import axi_param_pkg::*;

   `include "../top/axi_transaction.sv"
   `include "../env/axi_reference_model.sv"
   `include "../seq_lib/axi_sequencer.sv"
   `include "../agent/axi_master_driver.sv"
   `include "../agent/axi_slave_driver.sv"
   `include "../agent/axi_master_monitor.sv"
   `include "../agent/axi_slave_monitor.sv"
   `include "../agent/axi_arbitration_monitor.sv"
   `include "../agent/axi_agent.sv"
   
   `include "../env/axi_scoreboard.sv" 
   `include "../env/axi_env.sv"

endpackage
