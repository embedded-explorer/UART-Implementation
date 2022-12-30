//----------------------------------------------------------------------------
// Title       : Micro UART Controller
// Design      : Source Code
// File        : uart_test.c
//----------------------------------------------------------------------------
// Description : Test Application for Xilinx FPGA
//----------------------------------------------------------------------------
// Author      :
// Version     : 1.0 - Basic Test Application
//----------------------------------------------------------------------------

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "stdint.h"
#include "xparameters.h"

// Reference Clock
#define REF_CLK XPAR_CPU_M_AXI_DP_FREQ_HZ

// Micro UART Controller Base Address
#define MICRO_UART_BA XPAR_MICRO_UART_CONTROLLER_0_BASEADDR

// Micro UART Controller Register Offset Address
#define THR (MICRO_UART_BA + 0)
#define RBR (MICRO_UART_BA + 0)
#define DLL (MICRO_UART_BA + 0)
#define IER (MICRO_UART_BA + 1)
#define DLM (MICRO_UART_BA + 1)
#define IIR (MICRO_UART_BA + 2)
#define FCR (MICRO_UART_BA + 2)
#define LCR (MICRO_UART_BA + 3)
#define MCR (MICRO_UART_BA + 4)
#define LSR (MICRO_UART_BA + 5)
#define MSR (MICRO_UART_BA + 6)
#define SCR (MICRO_UART_BA + 7)

// Function Prototypes
int SetBaudRate(int BaudRate);
int SetLineConfig(u8 WordLength, u8 StopBits, u8 ParityEnable, u8 ParityType);
int SendData(u8 Data);
int ReceiveData();
int UartTest(int BaudRate, u8 WordLength, u8 StopBits, u8 ParityEnable, u8 ParityType);

int main(){

    init_platform();

    xil_printf("-----------------------------------------------------------\r\n");
    xil_printf("----------- Micro UART Controller Target Testing ----------\r\n");
    xil_printf("-----------------------------------------------------------\r\n");

    // Test Cases - Uncomment and Run each test case
    // Baud Rate, Word Length, Stop Bits, Parity Enable, Even Parity

    //UartTest(9600, 8, 1, 0, 0);
    //UartTest(9600, 8, 1, 1, 1);
    //UartTest(9600, 8, 1, 1, 0);
    //UartTest(9600, 8, 2, 0, 0);
    //UartTest(9600, 8, 2, 1, 1);
    //UartTest(9600, 8, 2, 1, 0);
    //UartTest(9600, 7, 1, 0, 0);
    //UartTest(9600, 7, 1, 1, 1);
    //UartTest(9600, 7, 1, 1, 0);
    //UartTest(9600, 7, 2, 0, 0);
    //UartTest(9600, 7, 2, 1, 1);
    //UartTest(9600, 7, 2, 1, 0);

    UartTest(115200, 8, 1, 0, 0);
    //UartTest(115200, 8, 1, 1, 1);
    //UartTest(115200, 8, 1, 1, 0);
    //UartTest(115200, 8, 2, 0, 0);
    //UartTest(115200, 8, 2, 1, 1);
    //UartTest(115200, 8, 2, 1, 0);
    //UartTest(115200, 7, 1, 0, 0);
    //UartTest(115200, 7, 1, 1, 1);
    //UartTest(115200, 7, 1, 1, 0);
    //UartTest(115200, 7, 2, 0, 0);
    //UartTest(115200, 7, 2, 1, 1);
    //UartTest(115200, 7, 2, 1, 0);


    cleanup_platform();
    return 0;
}

//----------------------------------------------------------------------------
// Description : This function sets Divisor Latch Access bit of LCR and
//               Configures the requested baud rate
//----------------------------------------------------------------------------
// Parameter   : Required Baud Rate
// Return      : 0
//----------------------------------------------------------------------------
int SetBaudRate(int BaudRate){
    u16 Divisor;

    Divisor = REF_CLK / (BaudRate * 16);
    Xil_Out32(LCR, 0x80);
    Xil_Out32(DLM, ((0xFF00 & Divisor) >> 8));
    Xil_Out32(DLL, (0x00FF & Divisor));
    Xil_Out32(LCR, 0x00);

    return 0;
}

//----------------------------------------------------------------------------
// Description : This function sets the requested word length, stop bits
//               Parity and Mode of parity
//----------------------------------------------------------------------------
// Parameter   : Word Length, 7 Bits or 8 bits
//               Stop Bits, 0 for 1 bit, 1 for 2 bits
//               Parity, 1 for Enabling, 0 for Disabling
//               Parity Mode, 0 for Odd, 1 for Even
// Return      : 0
//----------------------------------------------------------------------------
int SetLineConfig(u8 WordLength, u8 StopBits, u8 ParityEnable, u8 ParityType){
	u8 ConfigValue;

	ConfigValue  = 0x03; // Default Word Length 8

    if(WordLength == 7){
    	ConfigValue = 0x02;
    }
	ConfigValue |= ((0x03 & StopBits) << 1);
	ConfigValue |= ((0x01 & ParityEnable) << 3);
	ConfigValue |= ((0x01 & ParityType) << 4);

	Xil_Out32(LCR, ConfigValue);

	return 0;
}

//----------------------------------------------------------------------------
// Description : Sends out data using polling method
//----------------------------------------------------------------------------
// Parameter   : Byte to be transmitted
// Return      : 0
//----------------------------------------------------------------------------
int SendData(u8 Data){
	u8 CheckStatus = 0x00;

	while(!(CheckStatus & 0x20)){
		CheckStatus = Xil_In32(LSR);
	}
	Xil_Out32(THR, Data);

	return 0;
}

//----------------------------------------------------------------------------
// Description : Receive data from UART until enter key is pressed
//----------------------------------------------------------------------------
// Return      : 0
//----------------------------------------------------------------------------
int ReceiveData(){
	u8 CheckStatus = 0x00;
	u8 ReceivedChar = 0x00;

	while(!(ReceivedChar == '\r')){
		xil_printf("Enter Character Followed by Enter Key to Exit..\r\n");
		while(!(CheckStatus & 0x01)){
			CheckStatus = Xil_In32(LSR);
		}
		CheckStatus = 0x00;
		ReceivedChar = Xil_In32(RBR);
		xil_printf("Received Character : %c\r\n", ReceivedChar);
	}

	return 0;
}

//----------------------------------------------------------------------------
// Description : This function calls SetBaudRate, SetLineConfig, SendData
//               and ReceiveData functions
//----------------------------------------------------------------------------
// Parameter   : Baud Rate integer
//               Word Length, 7 Bits or 8 bits
//               Stop Bits, 0 for 1 bit, 1 for 2 bits
//               Parity, 1 for Enabling, 0 for Disabling
//               Parity Mode, 0 for Odd, 1 for Even
// Return      : 0
//----------------------------------------------------------------------------
int UartTest(int BaudRate, u8 WordLength, u8 StopBits, u8 ParityEnable, u8 ParityType){

	char * DispString = "No Parity  ";
	if(ParityEnable){
		if(ParityType)
			DispString = "Even Parity";
		else
			DispString = "Odd Parity ";
	}


	xil_printf("\r\n-----------------------------------------------------------\r\n");
	xil_printf("- Baud Rate: %0d, %0d Data Bits, %0d Stop Bit, %s -\r\n", \
			   BaudRate, WordLength, StopBits, DispString);
	xil_printf("-----------------------------------------------------------\r\n");

	// Configure 9600 Baud Rate
	SetBaudRate(BaudRate);

    // Configure 8-Bit Word Length, 1 Stop Bit, No Parity
	SetLineConfig(WordLength, StopBits, ParityEnable, ParityType);

	// Transmit Data
	for(int i=0; i<26; i++){
	    SendData('A' + i);
	}

	// Receive Data
	ReceiveData();

	xil_printf("-----------------------------------------------------------\r\n");
	xil_printf("---------------------- Test Completed ---------------------\r\n");
	xil_printf("-----------------------------------------------------------\r\n");

	return 0;
}

