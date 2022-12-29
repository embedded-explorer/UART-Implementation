//----------------------------------------------------------------------------
// Title       : Micro UART Controller
// Design      : Synchronous FWFT FIFO
// File        : sync_fwft_fifo.sv
//----------------------------------------------------------------------------
// Description : Prametrized Synchronous First Word Fall Through FIFO
//               read and write pointers are used for empty and full detection
//----------------------------------------------------------------------------
// Version     : 1.0 - Initial Version 
//                   - after empty is low read data is avilable next cycle
//               2.0 - Handled empty signal properly
//----------------------------------------------------------------------------

`timescale 1ns/1ns

module sync_fwft_fifo#(
  parameter [31:0] DATA_WIDTH = 8                 , // FIFO data width
  parameter [31:0] ADDR_WIDTH = 4                   // FIFO depth = 2**ADDR_WIDTH
)(
  // Clock and Reset
  input                            fifo_clk_i     , // reference input clock
  input                            fifo_rst_n_i   , // active low synchronous reset

  input                            fifo_wr_en_i   , // FIFO write enable
  input          [DATA_WIDTH-1:0]  fifo_data_i    , // FIFO write data
  output  logic                    fifo_full_o    , // FIFO write full

  input                            fifo_rd_en_i   , // FIFO read enable
  output  logic  [DATA_WIDTH-1:0]  fifo_data_o    , // FIFO read data
  output  logic                    fifo_empty_o     // FIFO read empty
);

//----------------------------------------------------------------------------
// Internal signal decleration
//----------------------------------------------------------------------------

  // Memory array decleration
  logic  [DATA_WIDTH-1:0] fifo [0:(2**ADDR_WIDTH)-1] ; 

  logic  [  ADDR_WIDTH:0] wr_ptr     ; // Write pointer
  logic  [  ADDR_WIDTH:0] rd_ptr     ; // Read pointer
  logic  [ADDR_WIDTH-1:0] rd_ptr_nxt ; // Points 1 loaction ahead of read pointer

  logic  read_en  ; // Internal read enable
  logic  write_en ; // Internal write enable
  
  logic  fifo_empty  ; // Internal fifo empty
  logic  fifo_empty_d; // Delayed fifo empty

//----------------------------------------------------------------------------
// Combinational Logic
//----------------------------------------------------------------------------

  // Read enable, when fifo is not empty and read enable is received form user
  assign read_en  = fifo_rd_en_i && !fifo_empty_o;

  // Write enable, when fifo is not full and write enable is received form user
  assign write_en = fifo_wr_en_i && !fifo_full_o ;

  // FIFO is empty when read pointer catches up with write pointer
  assign fifo_empty   = (wr_ptr == rd_ptr);
  
  // Make empty low along with data, and empty high as soon as FIFO is empty
  assign fifo_empty_o = fifo_empty | fifo_empty_d;

  // FIFO is full when MSB of write and read pointer are not equal, but lower bits are equal
  assign fifo_full_o  = (wr_ptr == {~rd_ptr[ADDR_WIDTH], rd_ptr[ADDR_WIDTH-1:0]}); 

  // Point 1 location ahead of read pointer
  assign rd_ptr_nxt = rd_ptr[ADDR_WIDTH-1:0] + 1'b1;

//----------------------------------------------------------------------------
// Sequential Logic
//----------------------------------------------------------------------------

  // FIFO write and pointer updation logic
  always_ff @(posedge fifo_clk_i) begin
    if(!fifo_rst_n_i) begin
      wr_ptr      <= 'h0;
      rd_ptr      <= 'h0;
    end else begin
      // Upon valid write enable
      if(write_en) begin
        wr_ptr                       <= wr_ptr + 1'b1 ; // increment write pointer
        fifo[wr_ptr[ADDR_WIDTH-1:0]] <= fifo_data_i   ; // write data to FIFO
      end
      // Upon valid read enable
      if(read_en) begin
        rd_ptr <= rd_ptr + 1'b1 ; // increment read pointer
      end
    end
  end

  // Read data logic
  always_ff @(posedge fifo_clk_i) begin
    fifo_data_o  <= read_en ? fifo[rd_ptr_nxt] : fifo[rd_ptr[ADDR_WIDTH-1:0]];
  end
  
  // Delay empty signal to match with data
  always_ff @(posedge fifo_clk_i) begin
    fifo_empty_d <= fifo_empty;
  end

endmodule