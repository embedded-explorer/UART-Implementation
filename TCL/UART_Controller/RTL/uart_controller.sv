//----------------------------------------------------------------------------
// Title       : Micro UART Controller
// Design      : UART Controller
// File        : uart_controller.sv
//----------------------------------------------------------------------------
// Description : UART Controller module which binds RX, TX Blocks along with 
//               APB Interface and register set
//----------------------------------------------------------------------------
// Author      :
// Version     : 1.0 - Initial Version
//               2.0 - Added APB Register set
//                   - Moved FIFO instances to register set for convinience
//                   - Added subset of control and status features from 16550
//----------------------------------------------------------------------------

`timescale 1ns/1ns

module uart_controller(
  // Clock and Reset
  input          clk_i           , // reference input clock
  input          rst_n_i         , // active low synchronous reset

  // UART serial Pins                    
  output         uart_tx_o       , // UART TX output Pin
  input          uart_rx_i       , // UART RX input Pin

  // APB Slave Interface
  input          s_apb_psel_i    , // APB Select
  input          s_apb_penable_i , // APB Enable
  input   [7:0]  s_apb_paddr_i   , // APB Address
  input          s_apb_pwrite_i  , // APB Direction
  input   [7:0]  s_apb_pwdata_i  , // APB Write Data
  output  [7:0]  s_apb_prdata_o  , // APB Read Data
  output         s_apb_pready_o    // APB Ready
);

//----------------------------------------------------------------------------
// Internal signal decleration
//----------------------------------------------------------------------------

  logic          rx_clk_en       ; // clock enable pulse 16 times baud rate
  logic          tx_clk_en       ; // clock enable pulse at baud rate
  
  logic          tsr_empty       ; // TX Shift register empty
  logic          rsr_full        ; // RX Shift register filled
  logic  [ 1:0]  word_len        ; // Data word length
  logic          stp_bits        ; // Number of stop bits
  logic          parity_en       ; // Parity enable
  logic          even_parity_sel ; // Enable even parity
  logic  [15:0]  baud_div        ; // RX baud rate divisor

  // TX FIFO interface from TX FIFO to UART TX
  logic  [ 7:0]  tx_fifo_data    ;
  logic          tx_fifo_empty   ;
  logic          tx_fifo_rd_en   ;

  // RX FIFO interface from UART RX to RX FIFO
  logic  [ 9:0]  rx_fifo_data    ;
  logic          rx_fifo_wr_en   ;

  // APB to Native signals
  logic  [ 7:0]  reg_addr        ; // Address from APB to Register set
  logic  [ 7:0]  data_apb_to_reg ; // Data from APB to register set
  logic  [ 7:0]  data_reg_to_apb ; // Data from Register set to APB
  logic          reg_wr_en       ; // Write enable from APB to register set
  logic          reg_rd_en       ; // Read enable from APB to register set
  logic          reg_wr_done     ; // Write done from register set to APB
  logic          reg_rd_done     ; // Read done from register set to APB

//----------------------------------------------------------------------------
// Internal module instantiation
//----------------------------------------------------------------------------

  // Baud Rate generator instance
  baud_rate_gen baud_rate_gen (
    .uart_clk_i         ( clk_i           ),
    .uart_rst_n_i       ( rst_n_i         ),
    .baud_div_i         ( baud_div        ),
    .rx_clk_en_o        ( rx_clk_en       ),
    .tx_clk_en_o        ( tx_clk_en       )
  );

  // UART Transmitter instance
  uart_tx uart_tx (
    .uart_clk_i         ( clk_i           ),
    .uart_rst_n_i       ( rst_n_i         ),
    .tx_clk_en_i        ( tx_clk_en       ),
    .tx_fifo_data_i     ( tx_fifo_data    ),
    .tx_fifo_empty_i    ( tx_fifo_empty   ),
    .tx_fifo_rd_en_o    ( tx_fifo_rd_en   ),
    .word_len_i         ( word_len        ),
    .parity_en_i        ( parity_en       ),
    .even_parity_sel_i  ( even_parity_sel ),
    .stp_bits_i         ( stp_bits        ),
    .tsr_empty_o        ( tsr_empty       ),
    .uart_tx_o          ( uart_tx_o       )
  );

  // UART Receiver instance
  uart_rx uart_rx (
    .uart_clk_i         ( clk_i           ),
    .uart_rst_n_i       ( rst_n_i         ),
    .rx_clk_en_i        ( rx_clk_en       ),
    .rx_fifo_data_o     ( rx_fifo_data    ),
    .rx_fifo_wr_en_o    ( rx_fifo_wr_en   ),
    .word_len_i         ( word_len        ),
    .parity_en_i        ( parity_en       ),
    .even_parity_sel_i  ( even_parity_sel ),
    .stp_bits_i         ( stp_bits        ),
    .rsr_full_o         ( rsr_full        ),
    .uart_rx_i          ( uart_rx_i       )
  );

  // APB to Native interface instance
  apb_interface apb_interface(
    .s_apb_pclk_i       ( clk_i           ),
    .s_apb_presetn_i    ( rst_n_i         ),
    .s_apb_psel_i       ( s_apb_psel_i    ),
    .s_apb_penable_i    ( s_apb_penable_i ),
    .s_apb_paddr_i      ( s_apb_paddr_i   ),
    .s_apb_pwrite_i     ( s_apb_pwrite_i  ),
    .s_apb_pwdata_i     ( s_apb_pwdata_i  ),
    .s_apb_prdata_o     ( s_apb_prdata_o  ),
    .s_apb_pready_o     ( s_apb_pready_o  ),
    .reg_addr_o         ( reg_addr        ),
    .reg_data_o         ( data_apb_to_reg ),
    .reg_data_i         ( data_reg_to_apb ),
    .reg_wr_en_o        ( reg_wr_en       ),
    .reg_rd_en_o        ( reg_rd_en       ),
    .reg_wr_done_i      ( reg_wr_done     ),
    .reg_rd_done_i      ( reg_rd_done     )
  );

  // UART 16550 Based register set instance
  uart_register_set uart_register_set(
    .clk_i              ( clk_i           ),
    .rst_n_i            ( rst_n_i         ),
    .reg_addr_i         ( reg_addr        ),
    .reg_data_i         ( data_apb_to_reg ),
    .reg_data_o         ( data_reg_to_apb ),
    .reg_wr_en_i        ( reg_wr_en       ),
    .reg_rd_en_i        ( reg_rd_en       ),
    .reg_wr_done_o      ( reg_wr_done     ),
    .reg_rd_done_o      ( reg_rd_done     ),
    .rx_fifo_wr_en_i    ( rx_fifo_wr_en   ),
    .rx_fifo_wr_data_i  ( rx_fifo_data    ),
    .tx_fifo_rd_en_i    ( tx_fifo_rd_en   ),
    .tx_fifo_rd_data_o  ( tx_fifo_data    ),
    .tx_fifo_rd_empty_o ( tx_fifo_empty   ),
    .tsr_empty_i        ( tsr_empty       ),
    .rsr_full_i         ( rsr_full        ),
    .word_len_o         ( word_len        ),
    .stp_bits_o         ( stp_bits        ),
    .parity_en_o        ( parity_en       ),
    .even_parity_sel_o  ( even_parity_sel ),
    .baud_div_o         ( baud_div        )
  );

endmodule