`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:20:26 10/09/2012
// Design Name:   audiocpu_BRAM
// Module Name:   /afs/ece.cmu.edu/usr/isimha/BRAM/audioBRAM_test.v
// Project Name:  BRAM
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: audiocpu_BRAM
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module audioBRAM_test;

	// Inputs
	reg clka;
	reg [13:0] addra;

	// Outputs
	wire [7:0] douta;

	// Instantiate the Unit Under Test (UUT)
	audiocpu_BRAM uut (
		.clka(clka), 
		.addra(addra), 
		.douta(douta)
	);

	initial begin
		// Initialize Inputs
		clka = 0;
		addra = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

