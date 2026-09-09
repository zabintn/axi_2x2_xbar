# ----------------------------------------
# Vivado xsim-based Makefile
# Compile -> Elaborate -> Simulate flow
# ----------------------------------------
REGRESS_DIR = regress_results
TESTLIST ?= ET AT NOC WT RT WRT BT
NUM_RUNS ?= 1
TEST ?= base_test
SEED_BASE ?=1

RTL_DIR   = ../rtl
TB_DIR    = .
SIM_DIR   = .

TOP       = tb_top
SNAPSHOT  = tb_top_snap
RTL_SRC = $(RTL_DIR)/axi_fifo.sv \
          $(RTL_DIR)/axi_round_robin.sv \
          $(RTL_DIR)/axi_response_arbiter.sv \
          $(RTL_DIR)/id_decoder.sv \
          $(RTL_DIR)/axi_id_tagger.sv \
          $(RTL_DIR)/addr_decoder.sv \
          $(RTL_DIR)/axi_write_error.sv \
          $(RTL_DIR)/axi_read_error.sv \
          $(RTL_DIR)/axi_aw.sv \
          $(RTL_DIR)/axi_wchannel.sv \
          $(RTL_DIR)/axi_bchannel.sv \
          $(RTL_DIR)/axi_archannel.sv \
          $(RTL_DIR)/axi_rchannel.sv \
          $(RTL_DIR)/axi_xbar.sv

TB_SRC = $(TB_DIR)/compile.f

.PHONY: compile elaborate simulate run clean regress regress_report

# Step 1: Compile RTL + testbench sources
compile:
	xvlog --sv $(RTL_SRC) -f $(TB_SRC)

# Step 2: Elaborate design into a simulation snapshot
elaborate: compile
	xelab $(TOP) -s $(SNAPSHOT) 

# Step 3: Run simulation
simulate: elaborate
	xsim $(SNAPSHOT) -gui -testplusarg $(TEST)

# Step 3-b: Run simulation without gui
dispsim: elaborate
	xsim $(SNAPSHOT) -runall -testplusarg $(TEST)

# Convenience target: does all three in order
allg: compile elaborate simulate

#All 3 without gui

all: compile elaborate dispsim

regress: compile elaborate
	@mkdir -p $(REGRESS_DIR)
	@rm -f $(REGRESS_DIR)/summary.log
	@for t in $(TESTLIST); do \
		for i in $$(seq 1 $(NUM_RUNS)); do \
			seed=$$(( $(SEED_BASE) + i )); \
			echo "=== Running $$t (run $$i/$(NUM_RUNS)) seed=$$seed ==="; \
		xsim $(SNAPSHOT) -runall -testplusarg $$t -sv_seed $$seed \
		-log $(REGRESS_DIR)/$${t}_run$${i}.log; \
		if grep -q "SCOREBOARD:.*FAIL=0" $(REGRESS_DIR)/$${t}_run$${i}.log; then \
			echo "$$t (run $$i seed=$$seed) : PASS" | tee -a $(REGRESS_DIR)/summary.log; \
		else \
			echo "$$t (run $$i seed=$$seed)  : FAIL" | tee -a $(REGRESS_DIR)/summary.log; \
		fi; \
	done; \
	done
	@echo ""; echo "=== REGRESSION SUMMARY ==="; cat $(REGRESS_DIR)/summary.log

clean:
	rm -rf xsim.dir *.log *.jou *.pb *.wdb .Xil xelab.pb webtalk*
