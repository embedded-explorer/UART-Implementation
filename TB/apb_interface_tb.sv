//----------------------------------------------------------------------------
// Title       : Micro UART Controller
// Design      : APB Interface Testbench
// File        : apb_interface_tb.sv
//----------------------------------------------------------------------------
// Description : Minimal testbench for APB Interface
//               along with simple register set
//----------------------------------------------------------------------------
// Version     : 1.0 - Initial Version
//----------------------------------------------------------------------------

`timescale 1ns/1ns

//----------------------------------------------------------------------------
// Basic Register Set Used for simulating APB Interface
// Consists of 4 Registers with Read Write Capabiliy
//----------------------------------------------------------------------------

module apb_register_set(
  // Clock and Reset Signals
  input                 clk_i            , // Input Clock
  input                 rst_n_i          , // Active low input reset
 
  // APB Interface Signals           
  input          [7:0]  reg_addr_i       , // Register address
  input          [7:0]  reg_data_i       , // Write data input
  output  logic  [7:0]  reg_data_o       , // Read data output 
  input                 reg_wr_en_i      , // Register write enable
  input                 reg_rd_en_i      , // Register read enable
  output  logic         reg_wr_done_o    , // Register write done
  output  logic         reg_rd_done_o      // Register read done
);

//----------------------------------------------------------------------------
// Parameter Declerations
//----------------------------------------------------------------------------

  // Register Offset Address
  localparam [7:0] SLV_REG_0 = 8'h00; // Register - 0
  localparam [7:0] SLV_REG_1 = 8'h01; // Register - 1
  localparam [7:0] SLV_REG_2 = 8'h02; // Register - 2
  localparam [7:0] SLV_REG_3 = 8'h03; // Register - 3

//----------------------------------------------------------------------------
// Internal signal decleration
//----------------------------------------------------------------------------

  logic  [7:0]  slv_reg_0; // Register - 0
  logic  [7:0]  slv_reg_1; // Register - 1
  logic  [7:0]  slv_reg_2; // Register - 2
  logic  [7:0]  slv_reg_3; // Register - 3

//----------------------------------------------------------------------------
// Sequential Logic
//----------------------------------------------------------------------------

  // Register Write Logic
  always_ff @(posedge clk_i) begin
    if(!rst_n_i) begin
    // Clear the registers upon reset
      slv_reg_0   <= 8'h0;
      slv_reg_1   <= 8'h0;
      slv_reg_2   <= 8'h0;
      slv_reg_3   <= 8'h0;
    end else begin
      if(reg_wr_en_i) begin
      // When register write is requested by user
        case(reg_addr_i[7:0])
        // Write data to the registers addressed
          SLV_REG_0 : slv_reg_0 <= reg_data_i;
          SLV_REG_1 : slv_reg_1 <= reg_data_i;
          SLV_REG_2 : slv_reg_2 <= reg_data_i;
          SLV_REG_3 : slv_reg_3 <= reg_data_i;
        endcase
      end
    end
  end

  // Register Read Logic
  always_ff @(posedge clk_i) begin
    if(!rst_n_i) begin
    // Clear on reset
      reg_data_o    <= 8'h0;
    end else begin
      if(reg_rd_en_i) begin
      // When register read is requested by user
        case(reg_addr_i[7:0])
        // Write data to the registers addressed
          SLV_REG_0 : reg_data_o <= slv_reg_0;
          SLV_REG_1 : reg_data_o <= slv_reg_1;
          SLV_REG_2 : reg_data_o <= slv_reg_2;
          SLV_REG_3 : reg_data_o <= slv_reg_3;
        endcase
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
endmodule

module apb_interface_tb();

  parameter CLK_P = 10; // 100MHz input clock
  
  logic          clk_i           ; // Clock
  logic          rst_n_i         ; // Reset
                                 ;
  logic          s_apb_psel_i    ; // APB Select
  logic          s_apb_penable_i ; // APB Enable
  logic   [7:0]  s_apb_paddr_i   ; // APB Address
  logic          s_apb_pwrite_i  ; // APB Direction
  logic   [7:0]  s_apb_pwdata_i  ; // APB Write Data
  logic   [7:0]  s_apb_prdata_o  ; // APB Read Data
  logic          s_apb_pready_o  ; // APB Ready
                                 ;
  logic   [7:0]  reg_addr        ; // Address from APB to Register set
  logic   [7:0]  data_apb_to_reg ; // Data from APB to register set
  logic   [7:0]  data_reg_to_apb ; // Data from Register set to APB
  logic          reg_wr_en       ; // Write enable from APB to register set
  logic          reg_rd_en       ; // Read enable from APB to register set
  logic          reg_wr_done     ; // Write done from register set to APB
  logic          reg_rd_done     ; // Read done from register set to APB
  
//----------------------------------------------------------------------------
// Instantiation
//----------------------------------------------------------------------------

  // Instantiate APB Interface
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
  
  // Instantiate Basic APB Register Set Module
  apb_register_set apb_register_set(
    .clk_i              ( clk_i           ),
    .rst_n_i            ( rst_n_i         ),
    .reg_addr_i         ( reg_addr        ),
    .reg_data_i         ( data_apb_to_reg ),
    .reg_data_o         ( data_reg_to_apb ),
    .reg_wr_en_i        ( reg_wr_en       ),
    .reg_rd_en_i        ( reg_rd_en       ),
    .reg_wr_done_o      ( reg_wr_done     ),
    .reg_rd_done_o      ( reg_rd_done     )
  );

//----------------------------------------------------------------------------
// Driving Inputs
//----------------------------------------------------------------------------
  
  // Clock generation
  initial begin
    clk_i = 1'b0;
    forever #(CLK_P/2) clk_i = ~clk_i;
  end
  
  // Task to initialize all inputs at starting
  task initialize;
    begin
      rst_n_i         <= 1'b0  ;
      s_apb_psel_i    <= 1'b0  ;
      s_apb_penable_i <= 1'b0  ;
      s_apb_paddr_i   <= 8'h0  ;
      s_apb_pwrite_i  <= 1'b0  ;
      s_apb_pwdata_i  <= 32'h0 ;
    end
  endtask
  
  // Task for writing data
  task write_data(
    input [7:0]   addr_i, // Address where data needs to be written
    input [7:0]   data_i  // Data to be written using APB interface
  );
    begin
      @(posedge clk_i);
      s_apb_psel_i    <= 1'b1;
      s_apb_paddr_i   <= addr_i;
      s_apb_pwdata_i  <= data_i;
      s_apb_pwrite_i  <= 1'b1;
      @(posedge clk_i);
      s_apb_penable_i <= 1'b1;
      wait(s_apb_pready_o);
      @(posedge clk_i);
      s_apb_psel_i    <= 1'b0;
      s_apb_paddr_i   <= 8'h0;
      s_apb_pwrite_i  <= 1'b0;
      s_apb_penable_i <= 1'b0;
      s_apb_pwdata_i  <= 32'h0;
    end
  endtask
  
  // Task for reading data
  task read_data(
    input  [7:0] addr_i // Address from where data needs to be read
  );
    begin
      @(posedge clk_i);
      s_apb_psel_i    <= 1'b1;
      s_apb_paddr_i   <= addr_i;
      s_apb_pwrite_i  <= 1'b0;
      @(posedge clk_i);
      s_apb_penable_i <= 1'b1;
      wait(s_apb_pready_o);
      @(posedge clk_i);
      s_apb_psel_i    <= 1'b0;
      s_apb_paddr_i   <= 8'h0;
      s_apb_pwrite_i  <= 1'b0;
      s_apb_penable_i <= 1'b0;
    end
  endtask
  
  // Initial Block for driving the inputs
  initial begin
    $display("------------------------------------------------------------------------");
    $display("------------------------ APB Interface Simulation ----------------------");
    $display("------------------------------------------------------------------------");
    initialize;

    #100;
    rst_n_i = 1'b1;
    
    // Write 32 to Register - 0 and read back the data
    write_data(8'h0, 8'h32);
    read_data (8'h0       );
    
    // Write 48 to Register - 1 and read back the data
    //write_data(8'h1, 8'h48);
    //read_data (8'h1       );
    
    // Write 25 to Register - 3 and read back the data
    //write_data(8'h2, 8'h25);
    //read_data (8'h2       );
    
    // Write 12 to Register - 4 and read back the data
    //write_data(8'h3, 8'h12);
    //read_data (8'h3       );
    
    #100;
    $finish;
    
  end

endmodule