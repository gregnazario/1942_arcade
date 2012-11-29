`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:50:43 10/06/2012
// Design Name:   maincpu
// Module Name:   /afs/ece.cmu.edu/usr/isimha/BRAM/test.v
// Project Name:  BRAM
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: maincpu
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test;

	// Inputs
	reg clka;
	reg [14:0] addra;

	// Outputs
	wire [7:0] douta;

	// Instantiate the Unit Under Test (UUT)
	maincpu uut (
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

