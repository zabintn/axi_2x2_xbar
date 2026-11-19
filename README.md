The Advanced eXtensible Interface (AXI) protocol is a high-performance, synchronous interface specification in ARM's AMBA family for on-chip communication for SoC (System On Chip) and FPGA (Field Programmable Gate Array) designs. An interconnect routes memory-mapped read/write transactions for all masters and slaves.

This project is a complete design of an AXI4 Interconnect (2 master and 2 slaves) with round robin-based arbitration, error response handling, and multiple outstanding transaction support for single-beat and multi-beat transfers. Contains original microarchitecture from scratch, RTL design on Systemverilog, and class-based hierarchical testbench for verification. Capable of supporting three types of bursts: FIXED, INCR, and WRAP. Specifications are as follows:

Num masters: 2
Num slaves: 2
Data Width: 64
ID Width: 4
Slave Address Map: 
  S0: 0x0000_0000-0x0FFF_FFFF
  S1: 0x1000_0000-1xFFF_FFFF
  
The design supports all functionalities of the AXI4 channels and transaction types save for the following signals: LOCK, PROT, QOS, and CACHE.

#### Microarchitecture Design

Complete top-level microarchitecture design for the 2x2 AXI Crossbar:

<img width="787" height="722" alt="image" src="https://github.com/user-attachments/assets/85661557-4024-4e7d-b808-5b12906ee622" />

A clearer picture of read/write transaction can be seen in the following diagrams:

## WRITE PATH

<img width="817" height="621" alt="image" src="https://github.com/user-attachments/assets/b39d5d9f-3513-4c21-8c8f-c645956b16ce" />

## WRITE RESPONSE PATH

<img width="743" height="555" alt="image" src="https://github.com/user-attachments/assets/6df9b2ab-d381-45d9-9aa1-e670f133f3cc" />

## READ PATH

<img width="796" height="600" alt="image" src="https://github.com/user-attachments/assets/4099c231-1ad5-4ae7-9ece-13a1f3f84937" />
