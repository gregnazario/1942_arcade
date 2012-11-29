/**
  structure called line buffer will hold next scanline so that this happens
  in parallel with rendering current scanline

  create sprite buffer for scanline:
  -scan all sprites (looking at y-coordinate)
  -load sprite from rom
  -initialize shift register to x-coordinate
  -flip if applicable

  create bg tile buffer
  -load bg tile from bgvideoram
  -load tile from rom
  -flip if applicable

  create fg tile buffer
  -load fg tile from fgvideoram
  -load tile from rom

  PIPELINE STAGES

  bg tile pipeline:
  (1) fetch bg tile (2 reads)
  (2) load tile from rom (3 reads)
  (3) transform
  (4) set bg line buffer cell

  sprite pipeline:
  (1) fetch sprite
  (2) evaluate y-coordinate
  (3) load sprite from rom (2 reads)
  (4) transform
  (5) set sprite line buffer cell

  fg tile pipeline:
  (1) fetch fg tile (2 reads)
  (2) load tile from rom (1 read)
  (3) set fg line buffer cell

  render pipeline:
  (1) fetch 3 line buffer cells
  (2) fetch color based on priority (fg > sprite > bg)
*/

/**
  fg linebuffer pipeline

  reads fg RAM, loads tiles from ROM, generates pixels for rendering
*/
module fg_linebuffer_pipeline(
    input  wire [7:0]  scanline,
    input  wire [7:0]  column,
    input  wire [7:0]  fgvideoram_read_data,
    input  wire [7:0]  gfx1_read_data,
    input  wire [2:0]  linebuffer_bit,
    input  wire        pipeline_start,
    input  wire        video_clk, rst_b,
    output reg  [15:0] gfx1_read_addr,
    output reg  [15:0] fgvideoram_read_addr,
    output wire [7:0]  fg_linebuffer_color,
    output wire        fg_linebuffer_color_transparent
  );

  wire [7:0] fgvideoram_code_reg_out;
  wire [5:0] fgvideoram_color_reg_out;
  wire [7:0] gfx1_1_reg_out;
  wire [7:0] gfx1_2_reg_out;
  reg        fgvideoram_code_reg_load;
  reg        fgvideoram_color_reg_load;
  reg        gfx1_1_reg_load;
  reg        gfx1_2_reg_load;

  // -- fg, gfx1 registers

  // Code  = all read data
  // Color = [5:0]read data
  generic_register #(8) fgvideoram_code_reg (
    .in(fgvideoram_read_data),
    .out(fgvideoram_code_reg_out),
    .load(fgvideoram_code_reg_load),
    .clk(video_clk), .rst_b(rst_b));

  generic_register #(6) fgvideoram_color_reg(
    .in(fgvideoram_read_data[5:0]),
    .out(fgvideoram_color_reg_out),
    .load(fgvideoram_color_reg_load),
    .clk(video_clk),
    .rst_b(rst_b));

  generic_register #(8) gfx1_1_reg(
    .in(gfx1_read_data),
    .out(gfx1_1_reg_out),
    .load(gfx1_1_reg_load),
    .clk(video_clk),
    .rst_b(rst_b));

  generic_register #(8) gfx1_2_reg(
    .in(gfx1_read_data),
    .out(gfx1_2_reg_out),
    .load(gfx1_2_reg_load),
    .clk(video_clk),
    .rst_b(rst_b));

  wire [5:0] fgvideoram_color_linebuffer_out;
  wire [2:0] gfx1_1_linebuffer_sel;
  wire [2:0] gfx1_2_linebuffer_sel;
  wire       gfx1_1_linebuffer_out;
  wire       gfx1_2_linebuffer_out;

  // commits to linebuffers will occur on assertion of pipeline_start
  wire linebuffer_load;

  assign linebuffer_load = pipeline_start;


  wire [7:0] gfx1_1_linebuffer_in, gfx1_2_linebuffer_in;

  // Reordering linebuffers
  //always @(*) begin
  assign  gfx1_1_linebuffer_in = {gfx1_2_reg_out[3:0], gfx1_1_reg_out[3:0]};
  assign  gfx1_2_linebuffer_in = {gfx1_2_reg_out[7:4], gfx1_1_reg_out[7:4]};
  //end

  // fg, gfx1 linebuffers
  generic_register #(6) fgvideoram_color_linebuffer(
    .in(fgvideoram_color_reg_out),
    .out(fgvideoram_color_linebuffer_out),
    .load(linebuffer_load),
    .clk(video_clk),
    .rst_b(rst_b));

  linebuffer8 gfx1_1_linebuffer(
    .in(gfx1_1_linebuffer_in),
    .sel(gfx1_1_linebuffer_sel),
    .load(linebuffer_load),
    .out(gfx1_1_linebuffer_out),
    .clk(video_clk),
    .rst_b(rst_b));

  linebuffer8 gfx1_2_linebuffer(
    .in(gfx1_2_linebuffer_in),
    .sel(gfx1_2_linebuffer_sel),
    .load(linebuffer_load),
    .out(gfx1_2_linebuffer_out),
    .clk(video_clk),
    .rst_b(rst_b));


  // inputs/outputs to renderer
  assign gfx1_1_linebuffer_sel           = linebuffer_bit;
  assign gfx1_2_linebuffer_sel           = linebuffer_bit;
  assign fg_linebuffer_color_transparent = ({gfx1_2_linebuffer_out, gfx1_1_linebuffer_out} == 2'd0);
  assign fg_linebuffer_color             = {fgvideoram_color_linebuffer_out, gfx1_2_linebuffer_out, gfx1_1_linebuffer_out};

  reg [2:0] fg_pipeline_state, fg_pipeline_next_state;

  // fg tile element indexes in gfx1
  reg [15:0] gfx1_read_addr_computed;
  reg [7:0]  gfx1_read_addr_offset;
  reg [15:0] gfx1_1_read_addr, gfx1_2_read_addr;
  reg [7:0]  fg_tile_row;

  always @(*) begin
    gfx1_read_addr_computed = 0;
    gfx1_read_addr_offset   = 0;

    // OLD formula
    // (((fgvideoram_code_reg_out + (fgvideoram_read_data[7] << 1) % 64) >> 7)

    // Current formula: (16 * code) + {data[7], 8'd0}
    gfx1_read_addr_computed = (fgvideoram_code_reg_out + {fgvideoram_read_data[7], 8'b00000000}) << 4; // fgvideoram_read_data is color reg this cycle

    gfx1_read_addr_offset   = (fg_tile_row * 2);
    gfx1_read_addr_computed = (gfx1_read_addr_computed + gfx1_read_addr_offset); // align to byte

    // addresses to roms
    gfx1_1_read_addr = gfx1_read_addr_computed;
    gfx1_2_read_addr = gfx1_read_addr_computed + 1;
  end

  // fg pipeline fsm
  always @(posedge video_clk or negedge rst_b) begin
    if (~rst_b) fg_pipeline_state <= `FG_PIPELINE_IDLE;
    else        fg_pipeline_state <= fg_pipeline_next_state;
  end

  // fg pipeline output function (5 cycles)
  reg [15:0] fgvideoram_tile_index;

  always @(*) begin
    // defaults
    fg_pipeline_next_state    = `FG_PIPELINE_IDLE;
    fgvideoram_color_reg_load = 0;
    fgvideoram_code_reg_load  = 0;
    gfx1_1_reg_load           = 0;
    gfx1_2_reg_load           = 0;
    fgvideoram_read_addr      = 0;
    gfx1_read_addr            = 0;

    // compute tile index
    fgvideoram_tile_index = ((scanline >> 3) << 5) + (column >> 3); // (scanline/8) * 32 + (column/8)
    fg_tile_row           = scanline % 8;

    case (fg_pipeline_state)
      `FG_PIPELINE_IDLE: begin
        if (pipeline_start) begin
          fg_pipeline_next_state = `FG_PIPELINE_FETCH_TILE_FROM_RAM_1;
          fgvideoram_read_addr   = fgvideoram_tile_index;
        end
      end
      `FG_PIPELINE_FETCH_TILE_FROM_RAM_1: begin
        fg_pipeline_next_state   = `FG_PIPELINE_FETCH_TILE_FROM_RAM_2;
        fgvideoram_code_reg_load = 1;
        fgvideoram_read_addr     = fgvideoram_tile_index + 'h0400; // tile_index + 1024
      end
      `FG_PIPELINE_FETCH_TILE_FROM_RAM_2: begin
        fg_pipeline_next_state    = `FG_PIPELINE_FETCH_TILE_FROM_ROM_1;
        fgvideoram_color_reg_load = 1;
        gfx1_read_addr            = gfx1_1_read_addr;
      end
      `FG_PIPELINE_FETCH_TILE_FROM_ROM_1: begin
        fg_pipeline_next_state = `FG_PIPELINE_FETCH_TILE_FROM_ROM_2;
        gfx1_1_reg_load        = 1;
        gfx1_read_addr         = gfx1_2_read_addr;
      end
      `FG_PIPELINE_FETCH_TILE_FROM_ROM_2: begin
        fg_pipeline_next_state = `FG_PIPELINE_IDLE;
        gfx1_2_reg_load        = 1;
      end
    endcase
  end

endmodule


