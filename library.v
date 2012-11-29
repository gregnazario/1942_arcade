`default_nettype none
  
module register
#(parameter W = 1)
(input wire en, clr, rst, clk,
 input wire [W-1:0] D,
 output reg [W-1:0] Q);
  
  always @(posedge clk or negedge rst)
  begin
    if (~rst)
      Q <= 0;
    else begin
		if (en)
			Q <= D;
		else if (clr)
			Q <= 0;
		else
			Q <= Q;
	 end
  end
  
endmodule

module counter
#(parameter W = 1)
(input  wire inc, clr, rst, clk,
 output wire [W-1:0] count);

  reg [W-1:0] nextCount;
  
  always @(*) begin
    if (clr)
      nextCount = 0;
    else if (inc)
      nextCount = count + 1;
    else
      nextCount = count;
  end

  register #(W) r(.clk(clk), .en(inc), .clr(clr), .rst(rst), .D(nextCount),
      .Q(count));
  
endmodule

module range_check
#(parameter W = 1)
(input  wire [W-1:0] low, high, val,
 output reg is_between);

  always @(*) begin
    if (val >= low && val <= high)
      is_between = 1;
    else
      is_between = 0;
  end

endmodule

module offset_check
#(parameter W = 1)
(input  wire [W-1:0] low, delta, val,
 output wire is_between);
  
  wire high;
  assign high = low + delta;

  range_check #(W) rc(.low(low), .high(high), .val(val), .is_between(is_between));
endmodule

module freq_divider_50M
(input  wire clk_100M, rst,
 output wire clk_50M);
  
  reg next_clk;
  assign clk_50M = next_clk;
  
  always @(posedge clk_100M or negedge rst)
  begin
    if (~rst) begin
		next_clk <= 0;
	 end
	 else
	 begin
		next_clk <= ~clk_50M;
	 end
  end
endmodule

module test_4M;

reg clk;
reg rst;
wire new_clk;

initial begin
  clk = 0;
  rst = 0;
  #1
  rst = 1;
  forever #1 clk = ~clk;
end

freq_divider_4M fd(clk, rst, new_clk);

endmodule

module freq_divider_4M
(input  wire clk_100M, rst,
 output wire clk_4M);
  
  reg next_clk_4M;
  reg [7:0] count;
  reg pos;
  
  assign clk_4M = next_clk_4M;
  
  always @(posedge clk_100M or negedge rst)
  begin
    if (~rst) begin
		next_clk_4M <= 0;
		pos <= 0;
		count <= 0;
	 end
	 else begin
	   if (pos) begin
		  if (count >= 11) begin
		    next_clk_4M <= ~clk_4M;
			 count    <= 0;
			 pos <= ~pos;
		  end
		  else begin
		    count <= count + 1;
		  end
		end
	   else begin
		  if (count >= 12) begin
		    next_clk_4M <= ~clk_4M;
			 count    <= 0;
			 pos      <= ~pos;
		  end
		  else begin
		    count <= count + 1;
		  end
		end
	 end
  end
endmodule

module freq_divider_3M
(input  wire clk_100M, rst,
 output wire clk_3M);
  
  reg next_clk_3M;
  reg [7:0] count;
  reg pos;
  
  assign clk_3M = next_clk_3M;
  
  always @(posedge clk_100M or negedge rst)
  begin
    if (~rst) begin
		next_clk_3M <= 0;
		pos <= 0;
		count <= 0;
	 end
	 else begin
	   if (pos) begin
		  if (count >= 15) begin
		    next_clk_3M <= ~clk_3M;
			 count    <= 0;
			 pos <= ~pos;
		  end
		  else begin
		    count <= count + 1;
		  end
		end
	   else begin
		  if (count >= 16) begin
		    next_clk_3M <= ~clk_3M;
			 count    <= 0;
			 pos      <= ~pos;
		  end
		  else begin
		    count <= count + 1;
		  end
		end
	 end
  end
endmodule

module freq_divider_1_5M
(input  wire clk_100M, rst,
 output wire clk_1_5M);
 
 wire clk_3M;
 
 freq_divider_3M  fd3(clk_100M, rst, clk_3M);
 freq_divider_50M fd50(clk_3M, rst, clk_1_5M);
endmodule


/*module freq_divider
(input  clk_50M, rst,
 output reg new_clk);
  
  wire next_clk;
  reg cnt_clr, inc, en;
  reg [22:0] count;

  assign next_clk = ~new_clk;

  counter #(23) c(.clk(clk_50M), .rst(rst), .clr(cnt_clr), .count(count), .inc(inc));

  register creg(.clk(clk_50M), .Q(new_clk),.D(next_clk),.rst(rst),.en(en),
      .clr(1'b0));
  
  always @(*) begin
    if (count >= 23'd4194630) begin
      en = 1'b1;
      cnt_clr = 1'b1;
      inc = 1'b0;
    end
    else begin
      inc = 1'b1;
      cnt_clr = 1'b0;
      en = 1'b0;
    end
  end
endmodule*/
