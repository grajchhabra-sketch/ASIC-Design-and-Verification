# ASIC Design & Verification Portfolio

This repository contains my ASIC RTL Design and Design Verification projects developed using **Verilog**, **SystemVerilog**, **UVM**, **SystemVerilog Assertions (SVA)**, **Functional Coverage**, **Python**, and **TCL**.

The projects focus on industry-relevant digital design concepts including **RISC-V Processor Design**, **AXI Interconnects**, **DDR Memory Controllers**, **Clock Domain Crossing (CDC)**, and **Verification Methodologies**.

---

## Repository Structure

```
ASIC-Design-and-Verification
│
├── RISC-V 5-Stage Pipelined Processor (RV32I)
│
├── AXI-MultiMaster-Memory-Subsystem
│
├── DDR Memory Controller
│
└── README.md
```

---

# Projects

---

## 1. RISC-V 5-Stage Pipelined Processor (RV32I)

### Overview

Designed and implemented a synthesizable **32-bit RV32I 5-stage pipelined processor** supporting hazard detection, data forwarding, and branch/jump control.

### Features

- RV32I ISA support
- 5-stage pipeline
    - IF
    - ID
    - EX
    - MEM
    - WB
- Hazard Detection Unit
- Data Forwarding Unit
- Branch Flush Logic
- Register File
- ALU
- Immediate Generator
- Control Unit
- Program Counter
- Pipeline Registers

### Verification

- SystemVerilog Testbench
- UVM Verification Environment
- Functional Coverage
- SystemVerilog Assertions (SVA)
- Python/TCL Regression Automation

### Results

- 88.58% Functional Coverage
- 100% Code Coverage
- Zero UVM Errors
- Zero Assertion Failures

---

## 2. AXI Multi-Master Memory Subsystem

### Overview

Designed a **3-Master, 1-Slave AXI4 Memory Subsystem** integrating arbitration, asynchronous FIFOs, and memory access management.

### Features

- AXI4 Protocol
- Three AXI Masters
- Single AXI Slave
- Round-Robin Arbitration
- Gray-Code Asynchronous FIFOs
- 256×32 AXI Memory
- Clock Domain Crossing (CDC)
- Shared Memory Access

### Verification

Developed a complete UVM verification environment including

- Driver
- Monitor
- Scoreboard
- Coverage Collector
- Assertions
- Constrained-Random Testing

### Verification Results

- 30,200+ Transactions
- 100% Functional Coverage
- 100% Assertion Pass Rate
- Zero UVM Errors/Fatals

---

## 3. DDR Memory Controller

### Overview

Designed a parameterized **128-bit DDR Memory Controller** implementing command scheduling, bank management, refresh logic, and read/write datapaths.

### Features

- FR-FCFS Scheduling
- Bank State Management
- Refresh Controller
- Read Datapath
- Write Datapath
- Address Mapping
- Command FIFO
- Timing Control

Supported Commands

- ACTIVATE
- PRECHARGE
- READ
- WRITE
- REFRESH

### Verification

- Directed Verification
- SystemVerilog Assertions
- Waveform Analysis

### Current Status

- RTL Development (In Progress)
- UVM Verification (Planned)

---

# Technical Skills

## RTL Design

- Verilog
- SystemVerilog
- FSM Design
- Pipeline Architecture
- CDC
- Parameterized RTL

## Verification

- UVM
- SystemVerilog Assertions (SVA)
- Functional Coverage
- Constrained Random Verification
- Scoreboarding
- Regression Automation

## Protocols

- AXI4
- UART
- SPI

## Languages

- Python
- Tcl

## Tools

- Vivado
- ModelSim
- GTKWave
- Synopsys VCS (EDA Playground)

---

# Future Work

- APB Verification Environment
- AXI VIP Integration
- DDR UVM Verification
- Cache Controller
- RISC-V Interrupt Support
- Advanced UVM (RAL, Factory, Virtual Sequencer)

---

# About Me

I am an Electronics and Communication Engineering undergraduate passionate about **ASIC RTL Design**, **Design Verification**, **Computer Architecture**, and **RISC-V**.

My interests include:

- RTL Design
- UVM Verification
- High-Speed Digital Systems
- Processor Design
- Memory Controllers
- Low-Power ASIC Design

---

