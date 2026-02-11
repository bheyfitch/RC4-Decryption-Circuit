# RC4-Decryption-Hardware-Accelerator

FPGA-based parallel hardware accelerator that brute-forces the RC4 stream cipher using multi-core architecture.

**Overview**

This project implements a four-core parallel RC4 brute-force engine on FPGA. Each core searches a unique portion of the keyspace, reducing overall key discovery time. The system automatically detects valid keys and halts execution upon success.

**Architecture**

- Four independent FSM-based RC4 decryption cores

- Keyspace partitioning logic for parallel search

- Shared datapath with arbitration

- Global control and termination signaling

**Implementation**

- Designed and implemented RTL in SystemVerilog

- Coordinated multi-core synchronization and resource sharing

- Integrated termination logic for key detection

**Verification**

- Developed self-checking SystemVerilog testbenches

- Verified multi-core coordination and corner cases in ModelSim

- Validated behavior prior to FPGA deployment

**Tools**

SystemVerilog, Quartus Prime, ModelSim
