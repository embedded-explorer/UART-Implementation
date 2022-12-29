# APB Based Minimal 16550D UART Controller Implementation
Documents implementation of UART Controller using System-Verilog and Testing using Arty-S7 FPGA

.
├── RTL                        # RTL Design Files
│   ├── apb_interface          # APB Completer Implementation
│   ├── baud_rate_gen          # Baud Rate Generator Implementation
│   ├── sync_fwft_fifo         # Synchronous First Word Fall Through FIFO Implementation
│   ├── uart_controller        # UART Controller Top Module
│   ├── uart_register_set      # Minimal 16550D Register Set Implementation
│   ├── uart_rx                # UART Transmitter Implementation
│   └── uart_tx                # UART Receiver Implementation
└── TB
