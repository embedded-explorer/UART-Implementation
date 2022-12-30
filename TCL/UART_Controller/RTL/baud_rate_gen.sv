//----------------------------------------------------------------------------
// Title       : Micro UART Controller
// Design      : Baud Rate Generator
// File        : baud_rate_gen.sv 
//----------------------------------------------------------------------------
// Description : This module generates 
//               clock enable pulse 16 times baud rate for UART RX and
//               clock enable pulse at baud rate for UART TX
//----------------------------------------------------------------------------
// Author      :
// Version     : 1.0 - Initial Version
//               2.0 - Renamed output ports and restructured
//                     Take RX Divisor vaue from register set
//----------------------------------------------------------------------------

`timescale 1ns/1ns

module baud_rate_gen(
  input                  uart_clk_i        , // reference input clock
  input                  uart_rst_n_i      , // active low synchronous reset
  input          [15:0]  baud_div_i        , // RX baud rate divisor from register set
  output  logic          rx_clk_en_o       , // clock enable pulse 16 times baud rate
  output  logic          tx_clk_en_o         // clock enable pulse at baud rate
);

//----------------------------------------------------------------------------
// Internal signal decleration
//----------------------------------------------------------------------------

  logic [15:0] rx_count; // count number of clock cycles in 16x baud period
  logic [ 3:0] tx_count; // count number of rx enable ticks within baud period

//----------------------------------------------------------------------------
// Sequential Logic
//----------------------------------------------------------------------------

  // Clock enable pulse generation for tx and rx
  always_ff @(posedge uart_clk_i) begin
    if (!uart_rst_n_i) begin
    // Clear counters and clock enable on reset
      rx_count    <= 16'b0 ;
      tx_count    <= 4'b0  ;
      rx_clk_en_o <= 1'b0  ;
      tx_clk_en_o <= 1'b0  ;
    end else begin
      if (rx_count >= (baud_div_i-1)) begin
      // When rx_count is reached to RX divisor value
        rx_count     <= 16'b0 ; // clear rx count
        rx_clk_en_o  <= 1'b1  ; // generate clock enable for rx
        if(tx_count == 4'hF) begin
        // When tx_count reaches 16
          tx_count    <= 4'h0 ; // clear tx count
          tx_clk_en_o <= 1'b1 ; // generate clock enable for tx
        end else begin
        // When tx_count is below 16
          tx_count     <= tx_count + 1'b1 ; // increment tx count
          tx_clk_en_o  <= 1'b0            ;
        end
      end else begin
      // If rx count is not yet reache to RX divisor value 
        rx_count    <= rx_count + 1'b1 ; // increment rx count
        tx_count    <= tx_count        ; // tx count is unchanged
        rx_clk_en_o <= 1'b0            ;
        tx_clk_en_o <= 1'b0            ;
      end
    end
  end

endmodule