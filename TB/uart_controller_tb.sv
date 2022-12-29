//----------------------------------------------------------------------------
// Title       : Micro UART Controller
// Design      : Basic Testbench for Micro UART Controller
// File        : uart_controller_tb.sv
//----------------------------------------------------------------------------
// Description : Minimal testbench for UART Controller
//----------------------------------------------------------------------------
// Version     : 1.0 - Initial Version
//----------------------------------------------------------------------------

`timescale 1ns/1ns

module uart_controller_tb();

//----------------------------------------------------------------------------
// Parameter Declerations
//----------------------------------------------------------------------------

  localparam CLK_F = 100000000; // Clock frequency 10MHz
  localparam CLK_P = 10       ; // Clock period 10 ns

  // Register Offset Address
  localparam  [7:0] THR_RBR_DLL = 8'h00;
  localparam  [7:0] IER_DLM     = 8'h01;
  localparam  [7:0] IIR_FCR     = 8'h02;
  localparam  [7:0] LCR         = 8'h03;
  localparam  [7:0] MCR         = 8'h04;
  localparam  [7:0] LSR         = 8'h05;
  localparam  [7:0] MSR         = 8'h06;
  localparam  [7:0] SCR         = 8'h07;
  
//----------------------------------------------------------------------------
// Internal signal decleration
//---------------------------------------------------------------------------- 
  logic         clk_i           ;
  logic         rst_n_i         ;
  logic         uart_tx_o       ;
  logic         uart_rx_i       ;
  logic         s_apb_psel_i    ;
  logic         s_apb_penable_i ;
  logic  [7:0]  s_apb_paddr_i   ;
  logic         s_apb_pwrite_i  ;
  logic  [7:0]  s_apb_pwdata_i  ;
  logic  [7:0]  s_apb_prdata_o  ;
  logic         s_apb_pready_o  ;
  
//----------------------------------------------------------------------------
// Instantiation
//----------------------------------------------------------------------------

  uart_controller uart_controller(.*);

//----------------------------------------------------------------------------
// Driving Inputs
//----------------------------------------------------------------------------
  
  // Loopback transmitted data
  assign uart_rx_i = uart_tx_o;
  
  // Clock generation
  initial begin
    clk_i = 1'b0;
    forever #(CLK_P/2) clk_i = ~clk_i;
  end
  
  // Task to initialize all inputs to 0
  task initialize;
    begin
      $display(" Intializing all Inputs to known values");
      rst_n_i         <= 1'b0 ;
      s_apb_psel_i    <= 1'b0 ;
      s_apb_penable_i <= 1'b0 ;
      s_apb_paddr_i   <= 8'h0 ;
      s_apb_pwrite_i  <= 1'b0 ;
      s_apb_pwdata_i  <= 32'h0;
    end
  endtask
  
  // Task for application of reset
  task reset(
    input [7:0] duration_i
  );
    begin
      $display(" Entering Reset State ");
      @(posedge clk_i)
      rst_n_i <= 1'b0; // Apply reset
      # duration_i   ; // Stay in reset state for given duration
      @(posedge clk_i)
      rst_n_i <= 1'b1; // Remove reset
      $display(" Exiting Reset State \n");
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
    input  [7:0] addr_i, // Address from where data needs to be read
    output [7:0] data_o  // Data received through APB interface
  );
    begin
      @(posedge clk_i);
      s_apb_psel_i    <= 1'b1;
      s_apb_paddr_i   <= addr_i;
      s_apb_pwrite_i  <= 1'b0;
      @(posedge clk_i);
      s_apb_penable_i <= 1'b1;
      wait(s_apb_pready_o);
      data_o <= s_apb_prdata_o;
      @(posedge clk_i);
      s_apb_psel_i    <= 1'b0;
      s_apb_paddr_i   <= 8'h0;
      s_apb_pwrite_i  <= 1'b0;
      s_apb_penable_i <= 1'b0;
    end
  endtask
  
  // Task for setting required baud rate
  task set_baud_rate(
    input  [32:0]  baud_rate // Required Baud Rate
  );
    // divisor = clock freq / (16 * baud_rate)
    logic [15:0] divisor = (CLK_F/(baud_rate*16));
    begin
      $display("------------------------------------------------------------------------");
      $display(" Setting Baud Rate to: %0d ", baud_rate);
      $display(" DLL = %02h ", divisor[7:0]);
      $display(" DLM = %02h ", divisor[15:8]);
      $display("------------------------------------------------------------------------\n");
      write_data(LCR, 8'h80); // Enable divisor access
      write_data(THR_RBR_DLL, divisor[ 7:0]); // Set lower byte of divisor
      write_data(IER_DLM, divisor[15:8]); // Set upper bytpe of divisor
      write_data(LCR, 8'h00); // Disable divisor access
    end
  endtask
  
  // Task for configuring line control register
  task set_lcr(
    input  [7:0]  config_data // Data to be written to LCR
  );
    begin
      $display(" Configuring Line Status Register");
      $display(" Data Word Length: %0d Bits", config_data[1:0]+5);
      $display(" Stop Bits       : %0d Bits", config_data[2]+1);
      $display(" Parity          : %0s", config_data[3] ? "Enabled" : "Disabled");
      $display(" Parity Type     : %0s\n", config_data[4] ? "Even" : "Odd");
      write_data(LCR, config_data);
    end
  endtask
  
  // Task for writing data to transmit holding register
  task set_thr(
    input  [7:0]  config_data // Data to be written to THR
  );
    begin
      $display(" Transmit Data: %02h", config_data);
      write_data(THR_RBR_DLL, config_data);
    end
  endtask
  
  // Task for clearing FIFOs
  task clear_fifos();
    begin
      $display(" Clearing TX and RX FIFOs");
      write_data(IIR_FCR, 8'h06);
    end
  endtask
  
  // Task for reading data from receive buffer register
  task get_rbr();
    logic  [7:0] reg_val;
    begin
      forever begin
        read_data(LSR, reg_val);
        if(reg_val[0])begin
        // Wait until data is avilable to read RBR
          read_data(THR_RBR_DLL, reg_val); // Read RBR
          $display(" Received Data: %02h", reg_val);
          break;
        end
        @(posedge clk_i);
      end
    end
  endtask

  // Task for checking parity error
  task check_parity_error();
    logic  [7:0] reg_val;
    begin
      forever begin
        read_data(LSR, reg_val);
        if(reg_val[0] == 1) begin
        // Wait until data is avilable to read status
          if(reg_val[2]) $display(" Parity Error Detected ");
          break;
        end
        @(posedge clk_i);
      end
    end
  endtask
  
  // Task for checking frame error
  task check_frame_error();
    logic  [7:0] reg_val;
    begin
      forever begin
        read_data(LSR, reg_val);
        if(reg_val[0] == 1) begin
        // Wait until data is avilable to read status
          if(reg_val[3]) $display(" Frame Error Detected ");
          break;
        end
        @(posedge clk_i);
      end
    end
  endtask

  // Task for checking overrun error
  task check_overrun_error();
    logic  [7:0] reg_val;
    begin
      forever begin
        read_data(LSR, reg_val);
        if(reg_val[1] == 1) begin
        // Wait until overrun error is detected
          $display(" Overrun Error Detected ");
          break;
        end
        @(posedge clk_i);
      end
    end
  endtask
  
  // Test Case - 1 basic test case
  task test_case_01();
    begin
      $display("------------------------------------------------------------------------");
      $display("----------------------- Test Case - 01 Basic Test ----------------------");
      $display("------------------------------------------------------------------------");
      set_lcr(8'h03)     ; // Set LCR, 8 Word, 1 Stop, No parity
      set_thr(8'h22)     ; // Send data - 22h
      get_rbr()          ; // Read received data
      $display("------------------------------------------------------------------------\n");
    end
  endtask
  
  // Test Case - 2 Continuous send receive
  task test_case_02();
    begin
      $display("------------------------------------------------------------------------");
      $display("------------------ Test Case - 02 Continuous Read Write ----------------");
      $display("------------------------------------------------------------------------");
      set_lcr(8'h03)                   ; // Set LCR, 8 Word, 1 Stop, No parity
      repeat(16) set_thr({$random}%256); // Send random data
      repeat(16) get_rbr()             ; // Read received data
      $display("------------------------------------------------------------------------\n");
    end
  endtask
  
  // Test Case - 3 Check Parity error
  task test_case_03();
    begin
      $display("------------------------------------------------------------------------");
      $display("------------------ Test Case - 03 Parity Error Checking ----------------");
      $display("------------------------------------------------------------------------");
      // Manually send parity as 1'b0 by changing in uart tx module
      set_lcr(8'h0B)      ; // Set LCR, 8 Word, 1 Stop, Odd parity
      set_thr(8'h22)      ; // Send data - 22h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display();
      set_thr(8'h23)      ; // Send data - 23h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display("------------------------------------------------------------------------");
      set_lcr(8'h1B)      ; // Set LCR, 8 Word, 1 Stop, Even parity
      set_thr(8'h22)      ; // Send data - 22h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display();
      set_thr(8'h23)      ; // Send data - 23h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display("------------------------------------------------------------------------");
      set_lcr(8'h0A)      ; // Set LCR, 7 Word, 1 Stop, Odd parity
      set_thr(8'h22)      ; // Send data - 22h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display();
      set_thr(8'h23)      ; // Send data - 23h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display("------------------------------------------------------------------------");
      set_lcr(8'h1A)      ; // Set LCR, 7 Word, 1 Stop, Even parity
      set_thr(8'h22)      ; // Send data - 22h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display();
      set_thr(8'h23)      ; // Send data - 23h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display("------------------------------------------------------------------------");
      set_lcr(8'h0F)      ; // Set LCR, 8 Word, 2 Stop, Odd parity
      set_thr(8'h22)      ; // Send data - 22h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display();
      set_thr(8'h23)      ; // Send data - 23h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display("------------------------------------------------------------------------");
      set_lcr(8'h1F)      ; // Set LCR, 8 Word, 2 Stop, Even parity
      set_thr(8'h22)      ; // Send data - 22h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display();
      set_thr(8'h23)      ; // Send data - 23h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display("------------------------------------------------------------------------");
      set_lcr(8'h0E)      ; // Set LCR, 7 Word, 2 Stop, Odd parity
      set_thr(8'h22)      ; // Send data - 22h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display();
      set_thr(8'h23)      ; // Send data - 23h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display("------------------------------------------------------------------------");
      set_lcr(8'h1E)      ; // Set LCR, 7 Word, 2 Stop, Even parity
      set_thr(8'h22)      ; // Send data - 22h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display();
      set_thr(8'h23)      ; // Send data - 23h
      check_parity_error(); // Check for parity error
      get_rbr()           ; // Read received data
      $display("------------------------------------------------------------------------\n");
    end
  endtask
  
  task test_case_04();
    begin
      $display("------------------------------------------------------------------------");
      $display("------------------ Test Case - 04 Frame Error Checking -----------------");
      $display("------------------------------------------------------------------------");
      // Manually send stop bit as 1'b0 by changing in uart tx module
      set_lcr(8'h03)      ; // Set LCR, 8 Word, 1 Stop, No parity
      set_thr(8'h22)      ; // Send data - 22h
      check_frame_error() ; // Check for frame error
      get_rbr()           ; // Read received data
      $display("------------------------------------------------------------------------\n");
    end
  endtask
  
  task test_case_05();
    begin
      $display("------------------------------------------------------------------------");
      $display("----------------- Test Case - 05 Overrun Error Checking ----------------");
      $display("------------------------------------------------------------------------");
      // Transmit multiple data before reading
      set_lcr(8'h03)          ; // Set LCR, 8 Word, 1 Stop, No parity
      repeat(18) begin
        set_thr({$random}%256); // Write data 20 times
        #1000;
      end
      check_overrun_error()   ; // Check for parity error
      $display("------------------------------------------------------------------------\n");
    end
  endtask
  
  // Initial Block for driving the inputs
  initial begin
    $display("------------------------------------------------------------------------");
    $display("------------------- Micro UART Controller Simulation -------------------");
    $display("------------------------------------------------------------------------");
    initialize         ; // Initialize
    reset(100)         ; // Apply Reset
    $display("------------------------------------------------------------------------\n");
    #1000;
    
    set_baud_rate(115200); // Set baud rate to 9600
    
    // Test Case - 1 basic test case
    test_case_01();
    
    // Test Case - 2 Continuous send receive
    test_case_02();
    
    // Test Case - 3 Check Parity error
    test_case_03();
    
    // Test Case - 4 Check frame error
    test_case_04();
    
    // Test Case - 5 Check overrun error
    test_case_05();
    
    // Test Case - 6 Clear FIFOs
    clear_fifos();
      
  end

endmodule