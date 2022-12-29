//----------------------------------------------------------------------------
// Title       : Micro UART Controller
// Design      : Baud Rate Generator Testbench
// File        : baud_rate_gen_tb.sv
//----------------------------------------------------------------------------
// Description : Minimal testbench for Baud Rate Generator
//----------------------------------------------------------------------------
// Version     : 1.0 - Initial Version
//----------------------------------------------------------------------------

`timescale 1ns/1ns

module baud_rate_gen_tb();

//----------------------------------------------------------------------------
// Parameter Declerations
//----------------------------------------------------------------------------

  localparam CLK_P     = 10       ; // Clock period 10 ns
  localparam CLK_F     = 100000000; // Clock frequency 100MHz
  localparam BAUD_RATE = 115200   ; // Required Baud Rate
  
//----------------------------------------------------------------------------
// Internal signal decleration
//----------------------------------------------------------------------------

  logic          uart_clk_i      ;
  logic          uart_rst_n_i    ;
  logic  [15:0]  baud_div_i      ;
  logic          rx_clk_en_o     ;
  logic          tx_clk_en_o     ;
  
//----------------------------------------------------------------------------
// Instantiation
//----------------------------------------------------------------------------

  baud_rate_gen baud_rate_gen(.*);
  
//----------------------------------------------------------------------------
// Driving Inputs
//----------------------------------------------------------------------------

  // Clock generation
  initial begin
    uart_clk_i = 1'b0;
    forever #(CLK_P/2) uart_clk_i = ~uart_clk_i;
  end
  
  // Initial Block for driving the inputs
  initial begin
    $display("------------------------------------------------------------------------");
    $display("--------------------- Baud Rate Generator Simulation -------------------");
    $display("------------------------------------------------------------------------");
    
    // Initially make all inputs 0
    uart_rst_n_i  <= 1'b0 ;
    baud_div_i    <= 16'h0;
    
    #100;
    uart_rst_n_i  <= 1'b1                  ; // Remove applied reset
    baud_div_i    <= (CLK_F/(BAUD_RATE*16)); // Set baud rate divisor value
    
  end

endmodule