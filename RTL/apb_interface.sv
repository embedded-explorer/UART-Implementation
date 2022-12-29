//----------------------------------------------------------------------------
// Title       : Micro UART Controller
// Design      : APB Interface
// File        : apb_interface.sv
//----------------------------------------------------------------------------
// Description : APB Interface used to access Register Set
//----------------------------------------------------------------------------
// Version     : 1.0 - Initial Version
//                     5 cycles are required to complete write transaction
//                     5 cycles are required to complete read transaction
//----------------------------------------------------------------------------

`timescale 1ns / 1ns

module apb_interface(
  // Clock and Reset Signals
  input                  s_apb_pclk_i    , // reference input clock
  input                  s_apb_presetn_i , // active low synchronous reset

  // APB Slave Interface
  input                  s_apb_psel_i    , // APB Select
  input                  s_apb_penable_i , // APB Enable
  input          [ 7:0]  s_apb_paddr_i   , // APB Address
  input                  s_apb_pwrite_i  , // APB Direction, 1-Write, 0-Read
  input          [ 7:0]  s_apb_pwdata_i  , // APB Write Data
  output  logic  [ 7:0]  s_apb_prdata_o  , // APB Read Data
  output  logic          s_apb_pready_o  , // APB Ready

  // Register Set Interface
  output  logic  [ 7:0]  reg_addr_o      , // Register address
  output  logic  [ 7:0]  reg_data_o      , // Write data output
  input          [ 7:0]  reg_data_i      , // Read data input
  output  logic          reg_wr_en_o     , // Register write enable
  output  logic          reg_rd_en_o     , // Register read enable
  input                  reg_wr_done_i   , // Register write done
  input                  reg_rd_done_i     // Register read done
);

//----------------------------------------------------------------------------
// Custom data types
//----------------------------------------------------------------------------

  // FSM State Encoding
  typedef enum logic [3:0]{
    S_IDLE   = 4'b0001,
    S_SETUP  = 4'b0010,
    S_WRITE  = 4'b0100,
    S_READ   = 4'b1000
  } state_coding_t;

  state_coding_t fsm_state ; // FSM current state register
  
//----------------------------------------------------------------------------
// Combinational Logic
//----------------------------------------------------------------------------

  assign reg_data_o     = s_apb_pwdata_i ; // write data
  assign reg_addr_o     = s_apb_paddr_i  ; // APB address
  assign s_apb_prdata_o = reg_data_i     ; // Read data
  
//----------------------------------------------------------------------------
// Finite State Machine
//----------------------------------------------------------------------------

  // Single FSM Block
  always_ff @(posedge s_apb_pclk_i) begin
    if (!s_apb_presetn_i) begin
    // Clear on reset
      reg_wr_en_o    <= 1'b0   ;
      reg_rd_en_o    <= 1'b0   ;
      s_apb_pready_o <= 1'b0   ;
      fsm_state      <= S_IDLE ;
    end else begin
      case(fsm_state)
        S_IDLE   : begin
          s_apb_pready_o <= 1'b0 ;
          if(s_apb_psel_i) begin
          // When slave is selected 
            fsm_state <= S_SETUP ; // Move to Setup state
          end
        end
        S_SETUP  : begin
          if(s_apb_penable_i) begin
          // When enable signal is received
            if(s_apb_pwrite_i) begin
            // when write signal is high
              fsm_state   <= S_WRITE  ; // Move to Write state
              reg_wr_en_o <= 1'b1     ; // Generate write enable
            end else begin
              fsm_state   <= S_READ   ; // Move to Read state
              reg_rd_en_o <= 1'b1     ; // Generate read enable
            end
          end
        end
        S_WRITE  : begin
          reg_wr_en_o <= 1'b0    ;
          if(reg_wr_done_i) begin
          // On receiving write done from register set
            fsm_state      <= S_IDLE ; // Move to Idle state
            s_apb_pready_o <= 1'b1   ;
          end
        end
        S_READ   : begin
          reg_rd_en_o  <= 1'b0   ;
          if(reg_rd_done_i) begin
          // On receiving read done from register set
            fsm_state      <= S_IDLE ; // Move to Idle state
            s_apb_pready_o <= 1'b1   ;
          end
        end
        default : begin
        end
      endcase
    end
  end
  
endmodule