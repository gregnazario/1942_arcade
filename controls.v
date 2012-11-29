module joystick_controller 
(
  input wire up, down, left, right,
  input wire b1, b2, b3, b4, b5, 
  input wire clk, rst,
  output wire [3:0] dir,
  output wire p1_start, p2_start,
  output wire coin,
  output wire fire, special
);
/* Button Layout
 *         B5 B3   B4     
 *                           
 *    U    
 *  L   R  B1 
 *    D   B2
 *
 */
  wire ctrl_up, ctrl_down, ctrl_left, ctrl_right;
  reg [3:0] tmp_dir;
  wire up_sync, down_sync, left_sync, right_sync;
  wire b1_sync, b2_sync, b3_sync, b4_sync, b5_sync;
  

  /* Input sanitizer
   * North South East West
   
  always @(*) begin
    case({ctrl_up, ctrl_down, ctrl_right, ctrl_left})
      4'b1000: tmp_dir = 4'b1000; // North
      4'b1010: tmp_dir = 4'b1010; // NorthEast
      4'b1001: tmp_dir = 4'b1001; // NorthWest

      4'b0100: tmp_dir = 4'b0100; // South
      4'b0110: tmp_dir = 4'b0110; // SouthEast
      4'b0101: tmp_dir = 4'b0101; // SouthWest

      4'b0010: tmp_dir = 4'b0010; // East
      4'b0001: tmp_dir = 4'b0001; // West
		4'b0000: tmp_dir = 4'b0000;
      default: tmp_dir = 4'b0000; // None
    endcase
  end
  */
	assign dir = {ctrl_up, ctrl_down, ctrl_right, ctrl_left};//tmp_dir;

  synchronizer s_up   (clk, rst, up,    up_sync);
  synchronizer s_down (clk, rst, down,  down_sync);
  synchronizer s_left (clk, rst, left,  left_sync);
  synchronizer s_right(clk, rst, right, right_sync);

  debouncer d_up   (clk, rst, up_sync,    ctrl_up);
  debouncer d_down (clk, rst, down_sync,  ctrl_down);
  debouncer d_left (clk, rst, left_sync,  ctrl_left);
  debouncer d_right(clk, rst, right_sync, ctrl_right);
  
  synchronizer s_b1(clk, rst, b1, b1_sync);
  synchronizer s_b2(clk, rst, b2, b2_sync);
  synchronizer s_b3(clk, rst, b3, b3_sync);
  synchronizer s_b4(clk, rst, b4, b4_sync);
  synchronizer s_b5(clk, rst, b5, b5_sync);
  
  debouncer d_b1(clk, rst, b1_sync, fire);
  debouncer d_b2(clk, rst, b2_sync, special);
  debouncer d_b3(clk, rst, b3_sync, coin);
  debouncer d_b4(clk, rst, b4_sync, p1_start);
  debouncer d_b5(clk, rst, b5_sync, p2_start);

endmodule

// 3 flip flop synchronizer
module synchronizer
#(parameter W = 1)
(input  wire clk, rst, 
 input  wire [W-1:0] in,
 output wire [W-1:0] out);
 
  reg [W-1:0] temp_1, temp_2;//, temp_3;
  
  assign out = temp_2;
  
  always @(posedge clk or negedge rst) begin
    if (~rst) begin
	   temp_1 <= 0;
		temp_2 <= 0;
	 end
    else begin
	   temp_1 <= in;
		temp_2 <= temp_1;
	 end
  end
endmodule


// Debounces inputs
module debouncer 
(
 input  wire clk, rst, in,
 output wire out
);

  parameter W = 8;

  reg [W-1:0] check_reg;
  reg       debounced;
 
  assign out = debounced;

  always @(posedge clk or negedge rst) begin
    if (~rst) begin
	   check_reg <= 0;
		debounced <= 0;
    end
    else begin
		 check_reg[W-1:0] <= {check_reg[W-2:0], in};
		 debounced        <= (check_reg[W-1:0] == {W{1'b1}}) ? 1'b1 : 1'b0;
    end
  end
endmodule
