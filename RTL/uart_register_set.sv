//----------------------------------------------------------------------------
// Title       : Micro UART Controller
// Design      : UART Register Set
// File        : uart_register_set.sv
//----------------------------------------------------------------------------
// Description : Subset of 16550 UART Register Set Implementation
//----------------------------------------------------------------------------
// Version     : 1.0 - Interrupt and Modem control signals are not implemented                
//----------------------------------------------------------------------------

`timescale 1ns / 1ns

module uart_register_set(
  // Clock and Reset Signals
  input                  clk_i              , // reference input clock
  input                  rst_n_i            , // active low synchronous reset

  // APB Interface Signals             
  input          [ 7:0]  reg_addr_i         , // Register address
  input          [ 7:0]  reg_data_i         , // Write data input
  output  logic  [ 7:0]  reg_data_o         , // Read data output 
  input                  reg_wr_en_i        , // Register write enable
  input                  reg_rd_en_i        , // Register read enable
  output  logic          reg_wr_done_o      , // Register write done
  output  logic          reg_rd_done_o      , // Register read done

  // Control and status signals
  input                  rx_fifo_wr_en_i    , // RX FIFO write enable 
  input          [ 9:0]  rx_fifo_wr_data_i  , // RX FIFO write data

  input                  tx_fifo_rd_en_i    , // TX FIFO read enable
  output  logic  [ 7:0]  tx_fifo_rd_data_o  , // TX FIFO read data
  output  logic          tx_fifo_rd_empty_o , // TX FIFO read empty
  
  // Control and Status
  input                  tsr_empty_i        , // Transmitter shift register empty
  input                  rsr_full_i         , // Receiver shift register full
  output  logic  [ 1:0]  word_len_o         , // Word length
  output  logic          stp_bits_o         , // Number of stop bits
  output  logic          parity_en_o        , // Parity enable
  output  logic          even_parity_sel_o  , // Enable even parity
  output  logic  [15:0]  baud_div_o           // Baud rate divisor
);

//----------------------------------------------------------------------------
// Parameter Declerations
//----------------------------------------------------------------------------

  // Register Offset Address
  localparam  [7:0] THR_RBR_DLL = 8'h00; // Transmit Holding Register
                                         // Receive Buffer Register
                                         // Divisor Latch LSB
  localparam  [7:0] IER_DLM     = 8'h01; // Interrupt Enable Register
                                         // Divisor Latch MSB
  localparam  [7:0] IIR_FCR     = 8'h02; // Interrupt Identification Register
                                         // FIFO Control Register
  localparam  [7:0] LCR         = 8'h03; // Line Control Register
  localparam  [7:0] MCR         = 8'h04; // Modem Control Register
  localparam  [7:0] LSR         = 8'h05; // Line Status Register
  localparam  [7:0] MSR         = 8'h06; // Modem Status Register
  localparam  [7:0] SCR         = 8'h07; // Scratch Register

//----------------------------------------------------------------------------
// Internal signal decleration
//----------------------------------------------------------------------------

  logic         clr_tx_fifo      ; // Clear TX FIFO 
  logic         clr_rx_fifo      ; // Clear RX FIFO

  // RX FIFO Signals  
  logic         rx_fifo_rst_n    ;
  logic         rx_fifo_rd_en    ;
  logic  [9:0]  rx_fifo_rd_data  ;
  logic         rx_fifo_rd_empty ;
  logic         rx_fifo_wr_full  ;
  
  // TX FIFO Signals
  logic         tx_fifo_rst_n    ;
  logic         tx_fifo_wr_en    ;
  logic  [7:0]  tx_fifo_wr_data  ;
  logic         tx_fifo_wr_full  ;
  
  // Subset of 16550 UART Registers implemented
  logic  [7:0]  fifo_cntrl_reg   ; // FIFO Control register
                                   // FCR[  0] - 1-FIFO Enable, 0-FIFO Disable
                                   // FCR[  1] - 1-Resets RX FIFO
                                   // FCR[  2] - 1-Resets TX FIFO
                                   // FCR[7:6] - 00- 1 Byte trigger
                                   //          - 01- 4 Byte trigger
                                   //          - 10- 8 Byte trigger
                                   //          - 11-14 Byte trigger

  logic  [7:0]  line_ctrl_reg    ; // Line control register
                                   // LCR[1:0] - 00- 5 bits/char
                                   //            01- 6 bits/char
                                   //            10- 7 bits/char
                                   //            11- 8 bits/char
                                   // LCR[  2] - 0- 1 Stop bit, 1- 2 or 1.5 stop bit if 5 char is selected
                                   // LCR[  3] - 0-Parity disable, 1-parity enable
                                   // LCR[  4] - 0-odd parity, 1-even parity
                                   // LCR[  5] - Stik parity
                                   // LCR[  6] - 0-disable break, 1-enable break - Unimplimented
                                   // LCR[  7] - 0-disable divisor access, 1-enable divisor access

  logic  [7:0]  line_sts_reg     ; // Line status register
                                   // LSR[0] Data ready
                                   // LSR[1] Overrun error
                                   // LSR[2] Parity error
                                   // LSR[3] Framing error
                                   // LSR[4] Break interrupt
                                   // LSR[5] Transmit holding register empty
                                   // LSR[6] Transmitter empty
                                   // LSR[7] Receiver FIFO error

  logic  [7:0]  scratch_reg      ; // Scratch register
  logic  [7:0]  div_latch_lsb    ; // Divisor Latch LSB
  logic  [7:0]  div_latch_msb    ; // Divisor Latch MSB
  

//----------------------------------------------------------------------------
// Combinational Logic
//----------------------------------------------------------------------------
  
  // Reset TX FIFO on receiving global reset or clear from register
  assign tx_fifo_rst_n = (rst_n_i & !clr_tx_fifo);
  
  // Reset RX FIFO on receiving global reset orclear from register
  assign rx_fifo_rst_n = (rst_n_i & !clr_rx_fifo);
  
  // Assign TX FIFO reset field of FIFO control register
  assign clr_tx_fifo = fifo_cntrl_reg[2];
  
  // Assign RX FIFO reset field of FIFO control register
  assign clr_rx_fifo = fifo_cntrl_reg[1];
  
  // Assign Baud rate divisor from internal registers
  assign baud_div_o        = {div_latch_msb, div_latch_lsb};
  
  // Assign word length from internal register
  assign word_len_o        = line_ctrl_reg[1:0];
  
  // Assign number of stop bits enabled from internal register
  assign stp_bits_o        = line_ctrl_reg[2];
  
  // Assign parity enable from internal register
  assign parity_en_o       = line_ctrl_reg[3];
  
  // Assign parity type from internal register
  assign even_parity_sel_o = line_ctrl_reg[4];
  
  // Assign data ready bit-0 of LSR when data is avilable in RX FIFO
  assign line_sts_reg[0] = !rx_fifo_rd_empty;
  
  // Assign parity error bit-2 of LSR 
  // Revealed when data present at top of FIFO is associated with parity error
  assign line_sts_reg[2] = rx_fifo_rd_data[8];
  
  // Assign frame error bit-3 of LSR 
  // Revealed when data present at top of FIFO is associated with frame error
  assign line_sts_reg[3] = rx_fifo_rd_data[9];
  
  // Unimplemented bit of LSR bit-4 is tied to 0
  assign line_sts_reg[4] = 1'b0;
  
  // Assign tx fifo empty bit-5 of LSR when TX FIFO is empty
  assign line_sts_reg[5] = tx_fifo_rd_empty_o;
  
  // Assign tx idle bit-6 of LSR when bot TX FIFO and transmit shift register are empty
  assign line_sts_reg[6] = (tx_fifo_rd_empty_o && tsr_empty_i);
  
  // Assign error in rx fifo data when there are any errors in RX FIFO data
  assign line_sts_reg[7] = (rx_fifo_rd_data[9] || rx_fifo_rd_data[8]);

//----------------------------------------------------------------------------
// Sequential Logic
//----------------------------------------------------------------------------

  // Register Write Logic
  always_ff @(posedge clk_i) begin
    if(!rst_n_i) begin
    // Clear the registers upon reset
      tx_fifo_wr_en       <= 1'b0;
      tx_fifo_wr_data     <= 8'h0;
      div_latch_lsb       <= 8'h0;
      div_latch_msb       <= 8'h0;
      fifo_cntrl_reg[  0] <= 1'b0;
      fifo_cntrl_reg[7:3] <= 5'h0;
      line_ctrl_reg       <= 8'h0;
      scratch_reg         <= 8'h0;
    end else begin
      if(reg_wr_en_i) begin
      // When register write is requested through APB
        case(reg_addr_i)
        // Write data to the registers addressed
        
          THR_RBR_DLL : begin
            if(line_ctrl_reg[7]) begin
            // When divisor access is enabled, write to DLL
              div_latch_lsb <= reg_data_i;
            end else begin
            // When divisor access is disabled, write data to TX FIFO(THR)
              tx_fifo_wr_en   <= 1'b1       ;
              tx_fifo_wr_data <= reg_data_i ;
            end
          end     

          IER_DLM : begin
            if(line_ctrl_reg[7]) begin
            // When divisor access is enabled, write to DLM
              div_latch_msb <= reg_data_i;
            end
            // When divisor access is disabled, write data to IER
            // Interrupt feature is unimplemented
          end     
          
          IIR_FCR : begin
          // FIFOs are always enabled, DMA mode is unimplemented
            fifo_cntrl_reg[  0] <= 1'b1                   ;
            fifo_cntrl_reg[7:3] <= {reg_data_i[7:6], 3'h0};
          end
          
          LCR     : begin
            line_ctrl_reg <= reg_data_i;
          end     
 
          SCR     : begin
            scratch_reg <= reg_data_i;
          end     

        endcase
      end else begin
        tx_fifo_wr_en <= 1'b0;
      end
    end
  end
  
  // FIFO Control register RX FIFO Clear bit handling
  // This bit is set through APB by writing 1 and is self clearing
  always_ff @(posedge clk_i) begin
    if(!rx_fifo_rst_n) begin
    // Clear the bit on application of rx fifo reset
      fifo_cntrl_reg[1] <= 1'b0;
    end else begin
      if(reg_wr_en_i) begin
      // When register write is requested through APB
        if(reg_addr_i == IIR_FCR) begin
        // When FIFO control register is addressed
          fifo_cntrl_reg[1] <= reg_data_i[1]; // Set value written through APB
        end
      end
    end
  end
  
  // FIFO Control register TX FIFO Clear bit handling
  // This bit is set by user by writing 1 and self clearing
  always_ff @(posedge clk_i) begin
    if(!tx_fifo_rst_n) begin
    // Clear the bit on application of tx fifo reset
      fifo_cntrl_reg[2] <= 1'b0;
    end else begin
      if(reg_wr_en_i) begin
      // When register write is requested through APB
        if(reg_addr_i == IIR_FCR) begin
        // When FIFO control register is addressed
          fifo_cntrl_reg[2] <= reg_data_i[2]; // Set value written through APB
        end
      end
    end
  end

  // Register Read Logic
  always_ff @(posedge clk_i) begin
    if(!rst_n_i) begin
    // Clear the signals upon reset
      reg_data_o    <= 8'h0;
      rx_fifo_rd_en <= 1'b0;
    end else begin
      if(reg_rd_en_i) begin
      // When register read is requested through APB
        case(reg_addr_i)
        // Read data from the registers addressed
        
          THR_RBR_DLL : begin
            if(line_ctrl_reg[7]) begin
            // When divisor access is enabled, read from DLL
              reg_data_o    <= div_latch_lsb;
            end else if(!rx_fifo_rd_empty) begin
            // When divisor access is disabled
            // Read data from RX FIFO(RBR) if data is avilable
              reg_data_o    <= rx_fifo_rd_data;
              rx_fifo_rd_en <= 1'b1;
            end
          end
          
          IER_DLM : begin
            if(line_ctrl_reg[7]) begin
            // When divisor access is enabled, read from DLM
              reg_data_o <= div_latch_msb;
            end
            // When divisor access is disabled, read from IER
            // Interrupt feature is unimplemented
          end
          
          LCR     : begin
            reg_data_o <= line_ctrl_reg;
          end

          LSR     : begin
            reg_data_o <= line_sts_reg;
          end

          SCR     : begin
            reg_data_o <= scratch_reg;
          end
          
        endcase
      end else begin
        rx_fifo_rd_en <= 1'b0;
      end
    end
  end
  
  // Overrun error handling
  always_ff @(posedge clk_i) begin
    if(!rst_n_i) begin
      line_sts_reg[1] <= 1'b0;
    end else begin
      if (rx_fifo_wr_full) begin
      // Check whether FIFO is full
        if(rsr_full_i) begin
        // When RX FIFO is full and receiver shift register is full
          line_sts_reg[1] <= 1'b1; // overrun error is generated
        end
      end else begin
      // Clear overrun error when FIFO is not full
        line_sts_reg[1] <= 1'b0;
      end
    end
  end
  
  // Read Write Done generation
  always_ff @(posedge clk_i) begin
    if(!rst_n_i) begin
      reg_wr_done_o <= 1'b0;
      reg_rd_done_o <= 1'b0;
    end else begin
    // 1 Cycle after read/ write request generate read/ write done
      reg_wr_done_o <= reg_wr_en_i;
      reg_rd_done_o <= reg_rd_en_i;
    end
  end

//----------------------------------------------------------------------------
// Internal module decleration
//----------------------------------------------------------------------------

  // Transmit FIFO
  sync_fwft_fifo #(
    .DATA_WIDTH      (8                   ), // Data width is 8
    .ADDR_WIDTH      (4                   )  // Depth = 16, bits required to index 4
  ) tx_fifo (                             
    .fifo_clk_i      ( clk_i              ), // Input clock     
    .fifo_rst_n_i    ( tx_fifo_rst_n      ), // Input active low reset  
    .fifo_wr_en_i    ( tx_fifo_wr_en      ), // FIFO write enable
    .fifo_data_i     ( tx_fifo_wr_data    ), // FIFO write data
    .fifo_full_o     ( tx_fifo_wr_full    ), // FIFO write full
    .fifo_rd_en_i    ( tx_fifo_rd_en_i    ), // FIFO read enable
    .fifo_data_o     ( tx_fifo_rd_data_o  ), // FIFO read data
    .fifo_empty_o    ( tx_fifo_rd_empty_o )  // FIFO read empty
  );

  // Receive FIFO
  sync_fwft_fifo #(
    .DATA_WIDTH      (10                  ), // Data width is 10
    .ADDR_WIDTH      (4                   )  // Depth = 16, bits required to index 4
  ) rx_fifo (                           
    .fifo_clk_i      ( clk_i              ), // Input clock     
    .fifo_rst_n_i    ( rx_fifo_rst_n      ), // Input active low reset
    .fifo_wr_en_i    ( rx_fifo_wr_en_i    ), // FIFO write enable 
    .fifo_data_i     ( rx_fifo_wr_data_i  ), // FIFO write data        
    .fifo_full_o     ( rx_fifo_wr_full  ), // FIFO write full
    .fifo_rd_en_i    ( rx_fifo_rd_en      ), // FIFO read enable
    .fifo_data_o     ( rx_fifo_rd_data    ), // FIFO read data  
    .fifo_empty_o    ( rx_fifo_rd_empty   )  // FIFO read empty
  );

endmodule