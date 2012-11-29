`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:41:41 10/21/2012 
// Design Name: 
// Module Name:    demo_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////


`define north      4'b1000
`define northeast  4'b1010
`define northwest  4'b1001

`define south      4'b0100
`define southeast  4'b0110
`define southwest  4'b0101

`define east       4'b0010
`define west       4'b0001

module demo_top
(input       clk_100M, reset,
 input [3:0] red_sw,
 input [3:0] green_sw,
 input [3:0] blue_sw,
 input b1, b2, b3, b4, b5,
 input up, down, left, right,
 output wire [9:0] row, col,
 output wire HS, VS, 
 output wire [3:0] red, green, blue);
  
  wire clk_50M;
  wire is_inbounds;
  
  wire [3:0] dir;
  wire [3:0] cp_red, cp_green, cp_blue;
  reg  [3:0] final_red, final_green, final_blue;

  wire p1_start, p2_start, coin, fire, special;
  
  freq_divider fd(clk_100M, reset, clk_50M);
  
  vga v(.clk_50M(clk_50M), .reset(reset), .HS(HS), .VS(VS), .row(row), .col(col));
  
  color_picker cp(clk_100M, reset, row, col, cp_red, cp_green, cp_blue, is_inbounds);
  
  assign red   = (is_inbounds) ? final_red   : 4'b0;
  assign green = (is_inbounds) ? final_green : 4'b0;
  assign blue  = (is_inbounds) ? final_blue  : 4'b0;

  always @(*) begin
    final_red   = cp_red;
	 final_blue  = cp_blue;
	 final_green = cp_green;
    case ({dir})
	   `north: 
		begin
		  final_red   = cp_red;
		  final_blue  = cp_red;
		  final_green = cp_red;
		end
		`northeast:
		begin
		  final_red   = cp_red;
		  final_blue  = cp_blue;
		  final_green = cp_red;
		end
		`northwest:
		begin
		  final_red   = cp_red;
		  final_blue  = cp_red;
		  final_green = cp_green;
		end
		`south:
		begin
		  final_red   = cp_blue;
		  final_blue  = cp_blue;
		  final_green = cp_blue;
		end
		`southeast:
		begin
		  final_red   = cp_red;
		  final_blue  = cp_blue;
		  final_green = cp_blue;
		end
		`southwest:
		begin
		  final_red   = cp_blue;
		  final_blue  = cp_blue;
		  final_green = cp_green;
		end
		`east:
		begin
		  final_red   = cp_green;
		  final_blue  = cp_green;
		  final_green = cp_green;
		end
		`west:
		begin
		  final_red   = 4'h0;
		  final_blue  = 4'h0;
		  final_green = cp_green;
		end
      default:
      begin
        case ({fire, special, coin, p1_start, p2_start})
		    5'b00000: 
		    begin
		      final_red   = cp_red;
			   final_blue  = cp_blue;
			   final_green = cp_green;
		    end
			 default:
			 begin
			   final_red   = 4'hF;
				final_green = 4'hF;
				final_blue  = 4'hF;
			 end
		  endcase
      end		  
	 endcase
	 
  end

  joystick_controller jc(
  .up(up), 
  .down(down), 
  .left(left), 
  .right(right),
  .b1(b1), 
  .b2(b2), 
  .b3(b3), 
  .b4(b4), 
  .b5(b5), 
  .clk(clk_100M), 
  .rst(reset),
  .dir(dir), // [3:0]
  .p1_start(p1_start), 
  .p2_start(p2_start),
  .coin(coin),
  .fire(fire), 
  .special(special));

endmodule

module color_picker
(
	input clk_50M,
	input reset,
	input [9:0] row, col,
	output wire [3:0] red_out, green_out, blue_out,
	output wire is_inbounds
);
  wire is_c1, is_c2, is_c3, is_c4, is_c5, is_c6, is_c7, is_c8,
       is_r1, is_r2, is_r3;
  reg [3:0] red, blue, green;
  
  assign red_out   = red;
  assign green_out = green;
  assign blue_out  = blue;
  
  assign is_inbounds = (is_c1 | is_c2 | is_c3 | is_c4 | is_c5 | is_c6 | is_c7 | is_c8)
                       & (is_r1 | is_r2 | is_r3);

  always @(posedge clk_50M or negedge reset) begin
    if (~reset) begin
		red   <= 'd0;
		blue  <= 'd0;
		green <= 'd0;
	 end
	 else begin
	   red   <= 4'h0;
		blue  <= 4'h0;
		green <= 4'h0;
      if (is_r1) begin
		  if (is_c1) begin
		    //Grey
		    red   <= 4'h4;
			 green <= 4'h4;
			 blue  <= 4'h4;
		  end
        else if (is_c2) begin
		    //Yellow
			 red   <= 4'hF;
			 green <= 4'hF;
			 blue  <= 4'h0;
		  end
		  else if (is_c3) begin
		    //Cyan
			 red   <= 4'h0;
			 green <= 4'hF;
			 blue  <= 4'hF;
		  end
		  else if (is_c4) begin
		    //Green
			 red   <= 4'h0;
			 green <= 4'hF;
			 blue  <= 4'h0;
		  end
		  else if (is_c5) begin
		    //Magenta
			 red   <= 4'hF;
			 green <= 4'h0;
			 blue  <= 4'hF;
		  end
		  else if (is_c6) begin
		    //Red
			 red   <= 4'hF;
			 green <= 4'h0;
			 blue  <= 4'h0;
		  end
		  else if (is_c7) begin
		    //Blue
			 red   <= 4'h0;
			 green <= 4'h0;
			 blue  <= 4'hF;
		  end
		  else if (is_c8) begin
		    //Purple
			 red   <= 4'h8;
			 green <= 4'h0;
			 blue  <= 4'hF;
		  end
		end
		else if (is_r2) begin
		  if (is_c1) begin
		    //Blue
		    red   <= 4'h0;
			 green <= 4'h0;
			 blue  <= 4'hF;
		  end
        else if (is_c2) begin
		    //Brown
			 red   <= 4'h4;
			 green <= 4'h2;
			 blue  <= 4'h8;
		  end
		  else if (is_c3) begin
		    //Magenta
			 red   <= 4'hF;
			 green <= 4'h0;
			 blue  <= 4'hF;
		  end
		  else if (is_c4) begin
		    //Orange
			 red   <= 4'h8;
			 green <= 4'h4;
			 blue  <= 4'h2;
		  end
		  else if (is_c5) begin
		    // Cyan
			 red   <= 4'h0;
			 green <= 4'hF;
			 blue  <= 4'hF;
		  end
		  else if (is_c6) begin
		    // Yellow
			 red   <= 4'h9;
			 green <= 4'h9;
			 blue  <= 4'h5;
		  end
		  else if (is_c7) begin
			 // Dark Brown
			 red   <= 4'h2;
			 green <= 4'h2;
			 blue  <= 4'h2;
		  end		  
		  else if (is_c8) begin
		    // Light brown
			 red   <= 4'h3;
			 green <= 4'h2;
			 blue  <= 4'h4;
		  end
		end
		// Color Gradient
		else if (is_r3) begin
			red   <= col[4:0];
			green <= col[6:4];
			blue  <= col[9:6];
		end
    end
  end
  
  range_check #(10) c1(.low(10'd0),   .high(10'd299), .val(row), .is_between(is_r1));
  range_check #(10) c2(.low(10'd300), .high(10'd379), .val(row), .is_between(is_r2));
  range_check #(10) c3(.low(10'd380), .high(10'd500), .val(row), .is_between(is_r3));
  range_check #(10) r1(.low(10'd0),   .high(10'd79),  .val(col), .is_between(is_c1));
  range_check #(10) r2(.low(10'd80),  .high(10'd159), .val(col), .is_between(is_c2));
  range_check #(10) r3(.low(10'd160), .high(10'd239), .val(col), .is_between(is_c3));
  range_check #(10) r4(.low(10'd240), .high(10'd319), .val(col), .is_between(is_c4));
  range_check #(10) r5(.low(10'd320), .high(10'd399), .val(col), .is_between(is_c5));
  range_check #(10) r6(.low(10'd400), .high(10'd479), .val(col), .is_between(is_c6));
  range_check #(10) r7(.low(10'd480), .high(10'd559), .val(col), .is_between(is_c7));
  range_check #(10) r8(.low(10'd560), .high(10'd639), .val(col), .is_between(is_c8));  
  
endmodule
