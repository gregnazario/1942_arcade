`default_nettype none
module vga
(input  wire clk_50M, reset,
 output reg HS, VS,
 output wire [9:0] row,
 output wire [9:0] col,
 output wire pixel_clk);

  reg clr_row, 
      clr_col, 
      clr_hs,  
	   clr_vs;
  reg inc_row, 
      inc_col, 
      inc_hs,  
	   inc_vs;
  
  wire [11:0] hsCount;
  wire [19:0] vsCount;
  wire [9:0]  rowCount; 
  wire [9:0]  colCount;

  wire //isVSDisp, 
       isHSDisp, 
       isVSPW, 
       isHSPW;

  /* Assigns for location */
  assign row = rowCount;
  assign col = colCount;

  /* Counters for row, column, HS, VS */
  counter #(10) rowC(.clk(clk_50M),
                     .rst(reset),
                     .clr(clr_row),
                     .inc(inc_row),
                     .count(rowCount));
  counter #(10) colC(.clk(clk_50M),
                     .rst(reset),
                     .clr(clr_col),
                     .inc(inc_col),
                     .count(colCount));
  counter #(12)  hsC(.clk(clk_50M),
                     .rst(reset),
                     .clr(clr_hs),
                     .inc(inc_hs),
                     .count(hsCount));
  counter #(20)  vsC(.clk(clk_50M),
                     .rst(reset),
                     .clr(clr_vs),
                     .inc(inc_vs),
                     .count(vsCount));
  
  /* Display Times */
/*  range_check #(20) vsCheck(.low(20'd49600), 
                            .high(20'd817600), 
                            .val(vsCount),
                            .is_between(isVSDisp));*/
  range_check #(12) hsCheck(.low(12'd288), 
                            .high(12'd1567), 
                            .val(hsCount),
                            .is_between(isHSDisp));

  /* Pulse times */
  range_check #(20) vsCheck1(.low(20'd0),
                            .high(20'd3199), 
                            .val(vsCount),
                            .is_between(isVSPW));
  range_check #(12) hsCheck1(.low(12'd0), 
                            .high(12'd192), 
                            .val(hsCount),
                            .is_between(isHSPW));

  // Counter Control logic
  always @(*) begin
	  // Cycle HS counter
	  // 1599
	  clr_hs = (hsCount >= 12'd1599) ? 1'b1 : 1'b0;
	  inc_hs = (hsCount >= 12'd1599) ? 1'b0 : 1'b1;
	
	  // Cycle VS counter
	  clr_vs = (vsCount >= 20'd833599) ? 1'b1 : 1'b0;
	  inc_vs = (vsCount >= 20'd833599) ? 1'b0 : 1'b1;
  end

  counter #(1)  pixClk(.clk(clk_50M),
                     .rst(reset),
                     .clr(clr_hs),
                     .inc(inc_hs),
                     .count(pixel_clk));

  // HS control logic
  always @(*) begin
    // Pulse or no pulse
	 HS = (isHSPW) ? 1'b0 : 1'b1;
  end

  // VS control logic
  always @(*) begin
    VS = (isVSPW) ? 1'b0 : 1'b1;
  end
  
  // Row control logic
  always @(*) begin
    if (clr_col) begin
      inc_row = 1'b1;
      clr_row = 1'b0;
    end
    else if (isVSPW) begin
      clr_row = 1'b1;
      inc_row = 1'b0;
    end
    else begin
      clr_row = 1'b0;
      inc_row = 1'b0;
    end
  end

  // Column control logic
  always @(*) begin
    if (isHSDisp && hsCount[0]) begin
      inc_col = 1'b1;
      clr_col = 1'b0;
    end
    else if (col >= 10'd640) begin
      clr_col = 1'b1;
      inc_col = 1'b0;
    end
    else begin
      clr_col = 1'b0;
      inc_col = 1'b0;
    end
  end


endmodule
