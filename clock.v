////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2011 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 13.2
//  \   \         Application : xaw2verilog
//  /   /         Filename : clock.v
// /___/   /\     Timestamp : 11/06/2012 15:03:22
// \   \  /  \ 
//  \___\/\___\ 
//
//Command: xaw2verilog -intstyle /afs/ece.cmu.edu/usr/gnazario/ece545/current_proj/1942/BRAM/ipcore_dir/clock.xaw -st clock.v
//Design Name: clock
//Device: xc5vlx110t-2ff1136
//
// Module clock
// Generated by Xilinx Architecture Wizard
// Written for synthesis tool: XST
`timescale 1ns / 1ps

module clock(CLKIN_IN, 
             RST_IN, 
             CLKDV_OUT, 
             CLKIN_IBUFG_OUT, 
             CLK0_OUT, 
             LOCKED_OUT);

    input CLKIN_IN;
    input RST_IN;
   output CLKDV_OUT;
   output CLKIN_IBUFG_OUT;
   output CLK0_OUT;
   output LOCKED_OUT;
   
   wire CLKDV_BUF;
   wire CLKFB_IN;
   wire CLKIN_IBUFG;
   wire CLK0_BUF;
   wire GND_BIT;
   wire [6:0] GND_BUS_7;
   wire [15:0] GND_BUS_16;
   
   assign GND_BIT = 0;
   assign GND_BUS_7 = 7'b0000000;
   assign GND_BUS_16 = 16'b0000000000000000;
   assign CLKIN_IBUFG_OUT = CLKIN_IBUFG;
   assign CLK0_OUT = CLKFB_IN;
   BUFG  CLKDV_BUFG_INST (.I(CLKDV_BUF), 
                         .O(CLKDV_OUT));
   IBUFG  CLKIN_IBUFG_INST (.I(CLKIN_IN), 
                           .O(CLKIN_IBUFG));
   BUFG  CLK0_BUFG_INST (.I(CLK0_BUF), 
                        .O(CLKFB_IN));
   DCM_ADV #( .CLK_FEEDBACK("1X"), .CLKDV_DIVIDE(16.0), .CLKFX_DIVIDE(1), 
         .CLKFX_MULTIPLY(4), .CLKIN_DIVIDE_BY_2("FALSE"), 
         .CLKIN_PERIOD(10.000), .CLKOUT_PHASE_SHIFT("NONE"), 
         .DCM_AUTOCALIBRATION("TRUE"), .DCM_PERFORMANCE_MODE("MAX_SPEED"), 
         .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), .DFS_FREQUENCY_MODE("LOW"), 
         .DLL_FREQUENCY_MODE("LOW"), .DUTY_CYCLE_CORRECTION("TRUE"), 
         .FACTORY_JF(16'hF0F0), .PHASE_SHIFT(0), .STARTUP_WAIT("FALSE"), 
         .SIM_DEVICE("VIRTEX5") ) DCM_ADV_INST (.CLKFB(CLKFB_IN), 
                         .CLKIN(CLKIN_IBUFG), 
                         .DADDR(GND_BUS_7[6:0]), 
                         .DCLK(GND_BIT), 
                         .DEN(GND_BIT), 
                         .DI(GND_BUS_16[15:0]), 
                         .DWE(GND_BIT), 
                         .PSCLK(GND_BIT), 
                         .PSEN(GND_BIT), 
                         .PSINCDEC(GND_BIT), 
                         .RST(RST_IN), 
                         .CLKDV(CLKDV_BUF), 
                         .CLKFX(), 
                         .CLKFX180(), 
                         .CLK0(CLK0_BUF), 
                         .CLK2X(), 
                         .CLK2X180(), 
                         .CLK90(), 
                         .CLK180(), 
                         .CLK270(), 
                         .DO(), 
                         .DRDY(), 
                         .LOCKED(LOCKED_OUT), 
                         .PSDONE());
endmodule
