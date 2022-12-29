//----------------------------------------------------------------------------
// Title       : Micro UART Controller
// Design      : Basic Testbench for UART TX
// File        : uart_tx_tb.sv
//----------------------------------------------------------------------------
// Description : Minimal testbench for UART TX
//----------------------------------------------------------------------------
// Version     : 1.0 - Initial Version
//----------------------------------------------------------------------------

`timescale 1ns/1ns

module uart_tx_tb();

//----------------------------------------------------------------------------
// Parameter Declerations
//----------------------------------------------------------------------------

  localparam CLK_P     = 10       ; // Clock period 10 ns
  localparam CLK_F     = 100000000; // Clock frequency 100MHz
  localparam BAUD_RATE = 115200   ; // Required Baud Rate

//----------------------------------------------------------------------------
// Internal signal decleration
//---------------------------------------------------------------------------- 
  logic          uart_clk_i        ;
  logic          uart_rst_n_i      ;

  logic  [15:0]  baud_div_i        ;
  logic          rx_clk_en_o       ;
  logic          tx_clk_en_o       ;

  logic          tx_clk_en_i       ;
  logic  [ 7:0]  tx_fifo_data_i    ;
  logic          tx_fifo_empty_i   ;
  logic          tx_fifo_rd_en_o   ;
  logic  [ 1:0]  word_len_i        ;
  logic          parity_en_i       ;
  logic          even_parity_sel_i ;
  logic          stp_bits_i        ;
  logic          tsr_empty_o       ;
  logic          uart_tx_o         ;

//----------------------------------------------------------------------------
// Instantiation
//----------------------------------------------------------------------------
  
  // UART TX Instance
  uart_tx uart_tx(.*);
  
  // Baud Rate Generator Instance
  baud_rate_gen baud_rate_gen(.*);

//----------------------------------------------------------------------------
// Driving Inputs
//----------------------------------------------------------------------------
  
  // Provide TX Clock Enable
  assign tx_clk_en_i = tx_clk_en_o;
  
  // Clock generation
  initial begin
    uart_clk_i = 1'b0;
    forever #(CLK_P/2) uart_clk_i = ~uart_clk_i;
  end
  
  // Task to initialize all inputs to known values
  task initialize;
    begin
      $display(" Intializing all Inputs to known values");
      uart_rst_n_i      <= 1'b0 ;
      baud_div_i        <= 16'h0;
      tx_fifo_data_i    <= 8'h0 ;
      tx_fifo_empty_i   <= 1'b1 ;
      word_len_i        <= 2'h0 ;
      parity_en_i       <= 1'b0 ;
      even_parity_sel_i <= 1'b0 ;
      stp_bits_i        <= 1'b0 ;
    end
  endtask

  // Task for providing inputs to UART TX
  // send_data(data, word_len, parity, even_parity_sel, stp_bits);
  task send_data(
    input [7:0] data            , // Data to be transmitted
    input [1:0] word_len        , // Number of Data bits to be transmitted
    input       parity_en       , // Enable parity
    input       even_parity_sel , // Select even parity
    input       stp_bits          // Number of stop bits
  );
    begin
      // Provide data and control inputs to UART TX
      @(posedge uart_clk_i);
      tx_fifo_data_i    <= data            ;
      tx_fifo_empty_i   <= 1'b0            ;
      word_len_i        <= word_len        ;
      parity_en_i       <= parity_en       ;
      even_parity_sel_i <= even_parity_sel ;
      stp_bits_i        <= stp_bits        ;
      
      // Wait until data is read by UART TX
      @(posedge uart_clk_i);
      wait(tx_fifo_rd_en_o);
      
      // Clear input data
      @(posedge uart_clk_i);
      tx_fifo_data_i    <= 8'h0            ;
      tx_fifo_empty_i   <= 1'b1            ;
      
      // Wait until data trasnfer completes
      @(posedge uart_clk_i);
      wait(tsr_empty_o);
      
      // Clear the control inputs
      word_len_i        <= 2'h0 ;
      parity_en_i       <= 1'b0 ;
      even_parity_sel_i <= 1'b0 ;
      stp_bits_i        <= 1'b0 ;
    end
  endtask
  
  // Initial Block for driving the inputs
  initial begin
    $display("------------------------------------------------------------------------");
    $display("--------------------------- UART TX Simulation -------------------------");
    $display("------------------------------------------------------------------------");
    initialize         ; // Initialize

    #100;
    uart_rst_n_i  <= 1'b1; // Remove from reset
    
    // Set baud rate divisor value
    baud_div_i    <= (CLK_F/(BAUD_RATE*16));
    
    // 8 data bits, Parity disabled, 1 stop bit
    send_data(8'h23, 2'b11, 0, 0, 0);
    
    // 8 data bits, Odd Parity, 1 stop bit
    //send_data(8'h23, 2'b11, 1, 0, 0);
    
    // 8 data bits, Even Parity, 1 stop bit
    //send_data(8'h23, 2'b11, 1, 1, 0);
    
    // 8 data bits, Parity disabled, 2 stop bit
    //send_data(8'h23, 2'b11, 0, 0, 1);
    
    // 8 data bits, Odd Parity, 2 stop bit
    //send_data(8'h23, 2'b11, 1, 0, 1);
    
    // 8 data bits, Even Parity, 2 stop bit
    //send_data(8'h23, 2'b11, 1, 1, 1);
    
    // 7 data bits, Parity disabled, 1 stop bit
    //send_data(8'h23, 2'b10, 0, 0, 0);
    
    // 7 data bits, Odd Parity, 1 stop bit
    //send_data(8'h23, 2'b10, 1, 0, 0);
    
    // 7 data bits, Even Parity, 1 stop bit
    //send_data(8'h23, 2'b10, 1, 1, 0);
    
    // 7 data bits, Parity disabled, 2 stop bit
    //send_data(8'h23, 2'b10, 0, 0, 1);
    
    // 7 data bits, Odd Parity, 2 stop bit
    //send_data(8'h23, 2'b10, 1, 0, 1);
    
    // 7 data bits, Even Parity, 2 stop bit
    //send_data(8'h23, 2'b10, 1, 1, 1);

  end

endmodule