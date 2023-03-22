# APB Based 16550D Minimal UART Controller Implementation
Documents implementation of UART Controller using System-Verilog and Testing using Arty-S7 FPGA

    .
	├── APP                           # SDK Bare-Metal Application
	│   └── uart_test.c               # Micro-Blaze Application for Testing UART Controller on FPGA
	├── DOC                           # Documentation
	│   └── UART-Implementation.pdf   # Detailed Document
    ├── RTL                           # RTL Design Files
    │   ├── apb_interface.sv          # APB Completer Implementation
    │   ├── baud_rate_gen.sv          # Baud Rate Generator Implementation
    │   ├── sync_fwft_fifo.sv         # Synchronous First Word Fall Through FIFO Implementation
    │   ├── uart_controller.sv        # UART Controller Top Module
    │   ├── uart_register_set.sv      # Minimal 16550D Register Set Implementation
    │   ├── uart_rx.sv                # UART Transmitter Implementation
    │   └── uart_tx.sv                # UART Receiver Implementation
    ├── TB                            # Individual Testbench Files
	│   ├── apb_interface_tb.sv       # Testbench for Testing APB Completer
    │   ├── baud_rate_gen_tb.sv       # Testbench for Testing Baud Rate Generator
    │   ├── sync_fwft_fifo_tb.sv      # Testbench for Testing Synchronous FWFT FIFO
    │   ├── uart_controller_tb.sv     # Testbench for UART Controller Top Module
    │   ├── uart_rx.sv                # Testbench for UART Transmitter
    │   └── uart_tx.sv                # Testbench for UART Receiver
	└── TCL                           # Vivado 18.3 Project Script Targeting Arty S7 50 FPGA
        ├── UART_Controller           # UART Controller IP Package for Vivado Block Design
        ├── design_1.tcl              # TCL Script for Creating Vivado Project
        └── io_constraints.xdc        # IO Constraints file