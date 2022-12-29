//----------------------------------------------------------------------------
// Title       : Micro UART Controller
// Design      : Synchronous FWFT FIFO Testbench
// File        : sync_fwft_fifo_tb.sv
//----------------------------------------------------------------------------
// Description : Minimal testbench for Synchronous FWFT FIFO
//----------------------------------------------------------------------------
// Version     : 1.0 - Initial Version
//----------------------------------------------------------------------------

`timescale 1ns/1ns

module sync_fwft_fifo_tb();

//----------------------------------------------------------------------------
// Parameter Declerations
//----------------------------------------------------------------------------

  localparam CLK_P     = 10       ; // Clock period 10 ns
  
//----------------------------------------------------------------------------
// Internal signal decleration
//----------------------------------------------------------------------------

  logic          fifo_clk_i   ;
  logic          fifo_rst_n_i ;
  logic          fifo_wr_en_i ;
  logic    [7:0] fifo_data_i  ;
  logic          fifo_full_o  ;
  logic          fifo_rd_en_i ;
  logic    [7:0] fifo_data_o  ;
  logic          fifo_empty_o ;
  
//----------------------------------------------------------------------------
// Instantiation
//----------------------------------------------------------------------------

  sync_fwft_fifo sync_fwft_fifo(.*);
  
//----------------------------------------------------------------------------
// Driving Inputs
//----------------------------------------------------------------------------

  // Clock generation
  initial begin
    fifo_clk_i = 1'b0;
    forever #(CLK_P/2) fifo_clk_i = ~fifo_clk_i;
  end

  // Task for writing data
  task write_data(
    input [7:0]   data
  );
    begin
      @(posedge fifo_clk_i);
      fifo_wr_en_i <= 1'b1;
      fifo_data_i  <= data;
      @(posedge fifo_clk_i);
      fifo_wr_en_i <= 1'b0;
    end
  endtask

  // Task for reading data
  task read_data;
    begin
      @(posedge fifo_clk_i);
      fifo_rd_en_i <= 1'b1;
      @(posedge fifo_clk_i);
      fifo_rd_en_i <= 1'b0;
    end
  endtask
  
  // Initial Block for driving the inputs
  initial begin
    $display("------------------------------------------------------------------------");
    $display("------------------- Synchronous FWFT FIFO Simulation -------------------");
    $display("------------------------------------------------------------------------");
    
    // Initially make all inputs 0
    fifo_rst_n_i  <= 1'b0 ;
    fifo_wr_en_i  <= 1'b0 ;
    fifo_data_i   <= 8'h0 ;
    fifo_rd_en_i  <= 1'b0 ;
    
    #100;
    fifo_rst_n_i  <= 1'b1; // Remove applied reset
    
    // Test Case - 1 Basic Write Read Test
    write_data(8'h64);
    read_data        ;

    // Test Case - 2 Write to Full FIFO
    //repeat (17) write_data({$random}%256);
      
    // Test Case - 3 Simultanenous Read Write
    //fork
    //  repeat (5) write_data({$random}%256);
    //  repeat (5) read_data;
    //join
    
  end

endmodule