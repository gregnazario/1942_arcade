/**
 * Team Arcade (1942)
 *
 * Video Infrastructure
 */
 
 // state defines
`define FG_PIPELINE_IDLE 0
`define FG_PIPELINE_FETCH_TILE_FROM_RAM_1 1
`define FG_PIPELINE_FETCH_TILE_FROM_RAM_2 2
`define FG_PIPELINE_FETCH_TILE_FROM_ROM_1 3
`define FG_PIPELINE_FETCH_TILE_FROM_ROM_2 4

`define BG_PIPELINE_IDLE 0
`define BG_PIPELINE_FETCH_TILE_FROM_RAM_1 1
`define BG_PIPELINE_FETCH_TILE_FROM_RAM_2 2
`define BG_PIPELINE_FETCH_TILE_FROM_ROM 3

`define SPRITE_PIPELINE_IDLE 0
`define SPRITE_PIPELINE_FETCH_RAM_1 1
`define SPRITE_PIPELINE_FETCH_RAM_2 2
`define SPRITE_PIPELINE_FETCH_RAM_3 3
`define SPRITE_PIPELINE_FETCH_RAM_4 4
`define SPRITE_PIPELINE_EVALUATE 5
`define SPRITE_PIPELINE_FETCH_ROM_1 6
`define SPRITE_PIPELINE_FETCH_ROM_2 7
`define SPRITE_PIPELINE_FETCH_ROM_3 8
`define SPRITE_PIPELINE_FETCH_ROM_4 9
`define SPRITE_PIPELINE_COMMIT 10

`default_nettype none

/** 
  video controller
  
  "top" module for video controller
  interfaces with ROMS, RAM, and VGA
  timing control for rendering pipelines
*/
module video_controller(
  // RAM
  input  wire [7:0]  fgvideoram_read_data,
  input  wire [7:0]  bgvideoram_read_data,
  input  wire [7:0]  spriteram_read_data,
  input  wire [1:0]  palette_bank_read_data,
  input  wire [15:0] scroll_read_data,
  
  output wire [15:0] fgvideoram_read_addr,
  output wire [15:0] bgvideoram_read_addr,
  output wire [15:0] spriteram_read_addr,
  
  // ROM
  input  wire [7:0]  gfx1_read_data,
  input  wire [7:0]  gfx2_bitplane_1_read_data,
  input  wire [7:0]  gfx2_bitplane_2_read_data,
  input  wire [7:0]  gfx2_bitplane_3_read_data,
  input  wire [7:0]  gfx3_1_read_data,
  input  wire [7:0]  gfx3_2_read_data,
  input  wire [15:0] palette_read_data,
  
  output wire [15:0] gfx1_read_addr,
  output wire [15:0] gfx2_bitplane_1_read_addr,
  output wire [15:0] gfx2_bitplane_2_read_addr,
  output wire [15:0] gfx2_bitplane_3_read_addr,
  output wire [15:0] gfx3_1_read_addr,
  output wire [15:0] gfx3_2_read_addr,
  output wire [15:0] palette_read_addr,
  
  // VGA controller
  input  wire [8:0] scanline,
  input  wire [9:0] column,
  output wire [3:0] rgb_r,
  output wire [3:0] rgb_b,
  output wire [3:0] rgb_g,
  
  input  wire video_clk, rst_b,
  input  wire [7:0] dip
);

  reg        pipeline_start;
  reg  [7:0] effective_scanline;
  reg  [8:0] effective_column;
  
  reg        bg_pipeline_start;
  reg  [7:0] bg_effective_scanline;
  reg  [8:0] bg_effective_column;
  
  wire [7:0] fg_linebuffer_color;
  wire       fg_linebuffer_transparent;

  wire [9:0] bg_linebuffer_color;
  wire       bg_linebuffer_transparent;

  wire [2:0] linebuffer_bit;
  reg        render_pipeline;

  wire [7:0] sprite_linebuffer_color;
  reg  [7:0] sprite_effective_column;
  reg  [7:0] sprite_effective_scanline;
  wire sprite_linebuffer_color_transparent;
  reg  sprite_flop_linebuffers; 
  reg  sprite_linebuffers_clr;
  reg  sprite_pipeline_start;

  wire [9:0] orig_bg_linebuffer_color;
  reg        load_bg_scanline_buffer;
  wire [2:0] bg_linebuffer_bit;
  reg  [9:0] out_effective_column;

  // fg linebuffer pipeline
  fg_linebuffer_pipeline fg_pipe(
    // inputs
    .scanline(effective_scanline),
    .column(effective_column[7:0]),
    .pipeline_start(pipeline_start),
    .fgvideoram_read_data(fgvideoram_read_data),
    .gfx1_read_data(gfx1_read_data),
    .linebuffer_bit(linebuffer_bit),
    .video_clk(video_clk), 
    .rst_b(rst_b),

    // outputs
    .gfx1_read_addr(gfx1_read_addr),
    .fg_linebuffer_color(fg_linebuffer_color),
    .fgvideoram_read_addr(fgvideoram_read_addr),
    .fg_linebuffer_color_transparent(fg_linebuffer_transparent)
  );
  
  // Scrolling logic
  bg_scroller bg_scroll(
    // inputs
    .scanline(effective_scanline),
    .column(out_effective_column),
    .bg_column(bg_effective_column),
    .scroll_read_data(scroll_read_data),
    .video_clk(video_clk), 
    .rst_b(rst_b),
    .orig_bg_linebuffer_color(orig_bg_linebuffer_color),
    .load_bg_scanline_buffer(load_bg_scanline_buffer),
    
    //outputs
    .bg_linebuffer_bit(bg_linebuffer_bit),
    .new_bg_linebuffer_color(bg_linebuffer_color)
  );
  
  // bg linebuffer pipeline
  bg_linebuffer_pipeline bg_pipe(
    // inputs
    .scanline(bg_effective_scanline),
    .column(bg_effective_column),
    .pipeline_start(bg_pipeline_start),
    .scroll_read_data(scroll_read_data),
    .bgvideoram_read_data(bgvideoram_read_data),
    .gfx2_bitplane_1_read_data(gfx2_bitplane_1_read_data),
    .gfx2_bitplane_2_read_data(gfx2_bitplane_2_read_data),
    .gfx2_bitplane_3_read_data(gfx2_bitplane_3_read_data),
    .linebuffer_bit(bg_linebuffer_bit),
    .palette_bank_read_data(palette_bank_read_data),
    .video_clk(video_clk), 
    .rst_b(rst_b),

    // outputs
    .gfx2_bitplane_1_read_addr(gfx2_bitplane_1_read_addr),
    .gfx2_bitplane_2_read_addr(gfx2_bitplane_2_read_addr),
    .gfx2_bitplane_3_read_addr(gfx2_bitplane_3_read_addr),
    .bg_linebuffer_color(orig_bg_linebuffer_color),
    .bgvideoram_read_addr(bgvideoram_read_addr)
  );
   

  // sprite linebuffer pipeline
  sprite_linebuffer_pipeline sprite_pipe(
    // inputs
    .scanline(sprite_effective_scanline),
    .column(sprite_effective_column),
    .sprite_pipeline_start(sprite_pipeline_start),
    .linebuffers_clr(sprite_linebuffers_clr),
    .flop_linebuffers(sprite_flop_linebuffers),
    .gfx3_1_read_data(gfx3_1_read_data),
    .gfx3_2_read_data(gfx3_2_read_data),
    .spriteram_read_data(spriteram_read_data),
    .video_clk(video_clk), .rst_b(rst_b),

    // outputs
    .sprite_linebuffer_color(sprite_linebuffer_color),
    .sprite_linebuffer_color_transparent(sprite_linebuffer_color_transparent),
    .spriteram_addr(spriteram_read_addr),
    .gfx3_1_read_addr(gfx3_1_read_addr),
    .gfx3_2_read_addr(gfx3_2_read_addr)
  );

  // renderer
  renderer_pipeline renderer(
    // inputs
    .render_pipeline(render_pipeline),
    .fg_linebuffer_color(fg_linebuffer_color),
    .fg_linebuffer_color_transparent(fg_linebuffer_transparent),
    .bg_linebuffer_color(bg_linebuffer_color),
    .sprite_linebuffer_color(sprite_linebuffer_color),
    .sprite_linebuffer_color_transparent(sprite_linebuffer_color_transparent),
    .palette_data(palette_read_data[11:0]),
    .video_clk(video_clk),
    .rst_b(rst_b), 
    .dip(dip),

    // outputs
    .palette_addr(palette_read_addr),
    .linebuffer_bit(linebuffer_bit),
    .rgb_r(rgb_r),
    .rgb_b(rgb_b),
    .rgb_g(rgb_g)
  );

  // timing control
  always @(*) begin
    // defaults
    sprite_effective_scanline = 0;
    effective_scanline        = 0;
    effective_column          = 0;
    pipeline_start            = 0;
    sprite_pipeline_start     = 0;
    render_pipeline           = 0;
    sprite_flop_linebuffers   = 0;
    sprite_linebuffers_clr    = 0;
    sprite_effective_column   = 0;
    bg_effective_scanline     = 0;
    bg_effective_column       = 0;
    bg_pipeline_start         = 0;
    load_bg_scanline_buffer   = 0;
    out_effective_column      = 0;
   
    // sprite pipeline control
    // operates one scanline ahead for next scanline
    if (scanline >= 127 && scanline <= 350) begin
      if (column == 10) begin // soon after clearing, start
        sprite_pipeline_start  = 1;
      end else if (column == 1) begin // clear at start of scanline
        sprite_linebuffers_clr = 1;
      end else if (column == 600) begin // flop at end of scanline
        sprite_flop_linebuffers = 1;
      end
      sprite_effective_scanline = scanline - 127 + 16 + 1;
    end

    // bg pipeline control (for scrolling)
    // operates one scanline ahead at all times
    if (scanline >= 126 && scanline <= 349) begin
      bg_effective_scanline = scanline - 126 + 16;
    
      if (column >= 184 && column <= 695) begin
        load_bg_scanline_buffer = 1;
        bg_effective_column  = column - 184;
      
        if (((column) % 8) == 0) begin
          bg_pipeline_start = 1;
        end
      end
    end
   
    // bg output control (for scrolling)
    // operates one scanline ahead at all times
    if (scanline >= 128 && scanline <= 351) begin
      bg_effective_scanline = scanline - 128 + 16;
      
      if (column >= 184 && column <= 456) begin
        out_effective_column  = column - 184;
      end
    end
   

    // fg/bg pipeline control
    // operates 8 pixels ahead for next 8 pixels
    if (scanline >= 128 && scanline <= 351) begin
      effective_scanline = scanline - 128 + 16;

      if (column >= 184 && column <= 440) begin
        effective_column = column - 184;

        if (((column) % 8) == 0) begin
          pipeline_start = 1;
        end        
      end
      
      // renderer control
      // has delay of 2
      if (column >= 193 && column <= 448) begin
        sprite_effective_column = column - 193;
        render_pipeline = 1;
      end
    end
  end
endmodule


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
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(6) fgvideoram_color_reg(
    .in(fgvideoram_read_data[5:0]), 
    .out(fgvideoram_color_reg_out), 
    .load(fgvideoram_color_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) gfx1_1_reg(
    .in(gfx1_read_data), 
    .out(gfx1_1_reg_out), 
    .load(gfx1_1_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) gfx1_2_reg(
    .in(gfx1_read_data), 
    .out(gfx1_2_reg_out), 
    .load(gfx1_2_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );
  
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
  assign  gfx1_1_linebuffer_in = {gfx1_2_reg_out[3:0], gfx1_1_reg_out[3:0]};
  assign  gfx1_2_linebuffer_in = {gfx1_2_reg_out[7:4], gfx1_1_reg_out[7:4]};
  
  // fg, gfx1 linebuffers
  generic_register #(6) fgvideoram_color_linebuffer(
    .in(fgvideoram_color_reg_out), 
    .out(fgvideoram_color_linebuffer_out), 
    .load(linebuffer_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  linebuffer8 gfx1_1_linebuffer(
    .in(gfx1_1_linebuffer_in), 
    .sel(gfx1_1_linebuffer_sel), 
    .load(linebuffer_load), 
    .out(gfx1_1_linebuffer_out), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  linebuffer8 gfx1_2_linebuffer(
    .in(gfx1_2_linebuffer_in), 
    .sel(gfx1_2_linebuffer_sel), 
    .load(linebuffer_load), 
    .out(gfx1_2_linebuffer_out), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );
  
  
  // inputs/outputs to renderer
  assign gfx1_1_linebuffer_sel           = linebuffer_bit - 1;
  assign gfx1_2_linebuffer_sel           = linebuffer_bit - 1;
  assign fg_linebuffer_color_transparent = ({gfx1_2_linebuffer_out, gfx1_1_linebuffer_out} == 2'd0);
  assign fg_linebuffer_color             = {fgvideoram_color_linebuffer_out, 
                                            gfx1_1_linebuffer_out, 
                                            gfx1_2_linebuffer_out};
  
  reg [2:0] fg_pipeline_state, fg_pipeline_next_state;
  
  // fg tile element indexes in gfx1
  reg [15:0] gfx1_read_addr_computed;
  reg [7:0]  gfx1_read_addr_offset;
  reg [15:0] gfx1_1_read_addr, gfx1_2_read_addr;
  reg [7:0]  fg_tile_row;
  
  always @(*) begin
    gfx1_read_addr_computed = 0;
    gfx1_read_addr_offset   = 0;

    gfx1_read_addr_computed = (fgvideoram_code_reg_out + {fgvideoram_read_data[7], 8'b00000000}) << 4; // fgvideoram_read_data is color reg this cycle
    
    gfx1_read_addr_offset   = (fg_tile_row << 1);
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
    gfx1_read_addr            = 0;
    fgvideoram_read_addr      = 0;
    
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
        fgvideoram_read_addr      = fgvideoram_tile_index + 'h0400; // tile_index + 1024
      end
      `FG_PIPELINE_FETCH_TILE_FROM_ROM_1: begin
        fg_pipeline_next_state = `FG_PIPELINE_FETCH_TILE_FROM_ROM_2;
        gfx1_1_reg_load        = 1;
        gfx1_read_addr         = gfx1_2_read_addr;
        fgvideoram_read_addr   = fgvideoram_tile_index + 'h0400; // tile_index + 1024
      end
      `FG_PIPELINE_FETCH_TILE_FROM_ROM_2: begin
        fg_pipeline_next_state = `FG_PIPELINE_IDLE;
        gfx1_2_reg_load        = 1;
      end
    endcase 
  end
  
endmodule

/**
  bg linebuffer pipeline
  
  reads bg RAM, loads tiles from ROM, generates pixels for rendering  
*/
module bg_linebuffer_pipeline(
    input  wire [7:0]  scanline,
    input  wire [8:0]  column,
    input  wire [15:0] scroll_read_data,
    input  wire [7:0]  bgvideoram_read_data,
    input  wire [7:0]  gfx2_bitplane_1_read_data,
    input  wire [7:0]  gfx2_bitplane_2_read_data,
    input  wire [7:0]  gfx2_bitplane_3_read_data,
    input  wire [2:0]  linebuffer_bit,
    input  wire [1:0]  palette_bank_read_data,
    input  wire        pipeline_start,
    input  wire        video_clk, rst_b,
    output reg  [15:0] bgvideoram_read_addr,
    output reg  [15:0] gfx2_bitplane_1_read_addr,
    output reg  [15:0] gfx2_bitplane_2_read_addr,
    output reg  [15:0] gfx2_bitplane_3_read_addr,
    output wire [9:0]  bg_linebuffer_color
  );
  
  // commits to linebuffers will occur on assertion of pipeline_start
  wire linebuffer_load;
  assign linebuffer_load = pipeline_start;
  
  wire [7:0] bgvideoram_code_reg_out;
  wire [7:0] bgvideoram_color_reg_out;
  wire [7:0] gfx2_bitplane_1_reg_out;
  wire [7:0] gfx2_bitplane_2_reg_out;
  wire [7:0] gfx2_bitplane_3_reg_out;

  reg bgvideoram_code_reg_load;
  reg bgvideoram_color_reg_load;
  reg gfx2_bitplane_1_reg_load;
  reg gfx2_bitplane_2_reg_load;
  reg gfx2_bitplane_3_reg_load;
  
  // bg, gfx2 registers
  // bg code is all read data
  // bg color is [4:0] read data
  generic_register #(8) bgvideoram_code_reg(
    .in(bgvideoram_read_data), 
    .out(bgvideoram_code_reg_out), 
    .load(bgvideoram_code_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) bgvideoram_color_reg(
    .in(bgvideoram_read_data), 
    .out(bgvideoram_color_reg_out), 
    .load(bgvideoram_color_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) gfx2_bitplane_1_reg(
    .in(gfx2_bitplane_1_read_data), 
    .out(gfx2_bitplane_1_reg_out), 
    .load(gfx2_bitplane_1_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) gfx2_bitplane_2_reg(
    .in(gfx2_bitplane_2_read_data), 
    .out(gfx2_bitplane_2_reg_out), 
    .load(gfx2_bitplane_2_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) gfx2_bitplane_3_reg(
    .in(gfx2_bitplane_3_read_data), 
    .out(gfx2_bitplane_3_reg_out), 
    .load(gfx2_bitplane_3_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );
  
  wire [7:0] bgvideoram_color_linebuffer_out;
  wire [2:0] gfx2_bitplane_1_linebuffer_sel;
  wire [2:0] gfx2_bitplane_2_linebuffer_sel;
  wire [2:0] gfx2_bitplane_3_linebuffer_sel;
  wire       gfx2_bitplane_1_linebuffer_out;
  wire       gfx2_bitplane_2_linebuffer_out;
  wire       gfx2_bitplane_3_linebuffer_out;
  
  // bg, gfx2 linebuffers
  generic_register #(8) bgvideoram_color_linebuffer(
    .in(bgvideoram_color_reg_out), 
    .out(bgvideoram_color_linebuffer_out), 
    .load(linebuffer_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  linebuffer8 bgfx2_bitplane_1_reg(
    .in(gfx2_bitplane_1_reg_out), 
    .sel(gfx2_bitplane_1_linebuffer_sel), 
    .load(linebuffer_load), 
    .out(gfx2_bitplane_1_linebuffer_out),
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  linebuffer8 bgfx2_bitplane_2_reg(
    .in(gfx2_bitplane_2_reg_out), 
    .sel(gfx2_bitplane_2_linebuffer_sel), 
    .load(linebuffer_load), 
    .out(gfx2_bitplane_2_linebuffer_out), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  linebuffer8 bgfx2_bitplane_3_reg(
    .in(gfx2_bitplane_3_reg_out), 
    .sel(gfx2_bitplane_3_linebuffer_sel), 
    .load(linebuffer_load), 
    .out(gfx2_bitplane_3_linebuffer_out), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );
 
  wire flipx;
  assign flipx = bgvideoram_color_linebuffer_out[5];

  // inputs/outputs to renderer
  reg [2:0] flipped_linebuffer_bit;
  always @(*) begin
    // flipx if color[5]
    if (flipx) begin
      flipped_linebuffer_bit = 3'd7 - linebuffer_bit + 5;
    end else begin
      flipped_linebuffer_bit = linebuffer_bit + 3;
    end
  end
  

  // inputs/outputs to renderer
  assign gfx2_bitplane_1_linebuffer_sel = flipped_linebuffer_bit;
  assign gfx2_bitplane_2_linebuffer_sel = flipped_linebuffer_bit;
  assign gfx2_bitplane_3_linebuffer_sel = flipped_linebuffer_bit;

  assign bg_linebuffer_color = {palette_bank_read_data[1:0], 
                                bgvideoram_color_linebuffer_out[4:0], 
                                gfx2_bitplane_1_linebuffer_out, 
                                gfx2_bitplane_2_linebuffer_out, 
                                gfx2_bitplane_3_linebuffer_out};
  
  // bg tile element indexes in gfx2
  reg [15:0] gfx2_read_addr_computed;
  reg [7:0]  gfx2_read_addr_offset;
  reg [7:0]  bg_tile_row, bg_tile_col;
  
  always @(*) begin
    gfx2_read_addr_computed = 0;
    gfx2_read_addr_offset   = 0;
   
    gfx2_read_addr_computed = (bgvideoram_code_reg_out + {bgvideoram_read_data[7], 8'b00000000}) << 5;
    
    // flipx
    if (bgvideoram_read_data[5]) begin
      if (bg_tile_col >= 8) gfx2_read_addr_offset = 0;
      else                  gfx2_read_addr_offset = 16;
    end else begin
      if (bg_tile_col >= 8) gfx2_read_addr_offset = 16;
      else                  gfx2_read_addr_offset = 0;
    end
    
    // flipy
    if (bgvideoram_read_data[6]) begin
      gfx2_read_addr_offset   =  gfx2_read_addr_offset   + (8'd15 - bg_tile_row);
    end else begin
      gfx2_read_addr_offset   =  gfx2_read_addr_offset   + bg_tile_row;
    end

    gfx2_read_addr_computed   = (gfx2_read_addr_computed + gfx2_read_addr_offset); // align to byte
    
    // addresses to roms
    gfx2_bitplane_1_read_addr = gfx2_read_addr_computed;
    gfx2_bitplane_2_read_addr = gfx2_read_addr_computed;
    gfx2_bitplane_3_read_addr = gfx2_read_addr_computed;
  end
  
  reg [2:0] bg_pipeline_state, bg_pipeline_next_state;
  
  // bg pipeline fsm
  always @(posedge video_clk or negedge rst_b) begin
    if (~rst_b) bg_pipeline_state <= `BG_PIPELINE_IDLE;
    else        bg_pipeline_state <= bg_pipeline_next_state;
  end

  wire [15:0] effective_column;
  assign effective_column = column + {scroll_read_data[15:4], 4'd0};//((scroll_read_data >> 4) << 4);
  
  // bg pipeline output function (4 cycles)
  reg [15:0] bgvideoram_tile_index, bgvideoram_tile_index_computed;
  always @(*) begin
    // defaults
    bg_pipeline_next_state    = `FG_PIPELINE_IDLE;
    bgvideoram_color_reg_load = 0;
    bgvideoram_code_reg_load  = 0;
    gfx2_bitplane_1_reg_load  = 0;
    gfx2_bitplane_2_reg_load  = 0;
    gfx2_bitplane_3_reg_load  = 0;
    bgvideoram_read_addr      = 0;
    
    // compute tile index
    bgvideoram_tile_index          = ((effective_column >> 4) << 4) + (scanline >> 4); // (column/16) * 32 + (row/16)
    bgvideoram_tile_index_computed = {bgvideoram_tile_index[8:4], 1'd0, bgvideoram_tile_index[3:0]};
    bg_tile_row = scanline % 16;
    bg_tile_col = effective_column % 16;
    
    case (bg_pipeline_state)
      `BG_PIPELINE_IDLE: begin
        bgvideoram_read_addr     = bgvideoram_tile_index_computed + 'h10; // computed tile index + 16
        if (pipeline_start) begin
          bg_pipeline_next_state = `BG_PIPELINE_FETCH_TILE_FROM_RAM_1;
          bgvideoram_read_addr   = bgvideoram_tile_index_computed;       
        end
      end
      `BG_PIPELINE_FETCH_TILE_FROM_RAM_1: begin
        bg_pipeline_next_state   = `BG_PIPELINE_FETCH_TILE_FROM_RAM_2;
        bgvideoram_code_reg_load = 1;
        bgvideoram_read_addr     = bgvideoram_tile_index_computed + 'h10; // computed tile index + 16
      end
      `BG_PIPELINE_FETCH_TILE_FROM_RAM_2: begin
        bg_pipeline_next_state    = `BG_PIPELINE_FETCH_TILE_FROM_ROM;
        bgvideoram_color_reg_load = 1;
        bgvideoram_read_addr      = bgvideoram_tile_index_computed + 'h10; // computed tile index + 16
      end
      `BG_PIPELINE_FETCH_TILE_FROM_ROM: begin
        bg_pipeline_next_state   = `BG_PIPELINE_IDLE;
        gfx2_bitplane_1_reg_load = 1;
        gfx2_bitplane_2_reg_load = 1;
        gfx2_bitplane_3_reg_load = 1;
        bgvideoram_read_addr     = bgvideoram_tile_index_computed + 'h10; // computed tile index + 16
      end
    endcase 
  end
endmodule






/**
sprite pipeline:
(1) fetch sprite
(2) evaluate y-coordinate
(3) load sprite from rom (2 reads)
(4) transform
(5) set sprite line buffer cell
*/

/**
  sprite linebuffer pipeline
  
  reads sprite RAM, loads tiles from ROM, generates pixels for rendering  
*/
module sprite_linebuffer_pipeline(
    input wire   [7:0] scanline,
    input wire   [7:0] column,
    input wire         sprite_pipeline_start,
    input wire         linebuffers_clr,
    input wire         flop_linebuffers,
    input wire   [7:0] gfx3_1_read_data,
    input wire   [7:0] gfx3_2_read_data,
    input wire   [7:0] spriteram_read_data,
    input wire         video_clk, rst_b,
    output wire [7:0]  sprite_linebuffer_color,
    output wire        sprite_linebuffer_color_transparent,
    output reg  [15:0] spriteram_addr,
    output reg  [15:0] gfx3_1_read_addr,
    output reg  [15:0] gfx3_2_read_addr
  );

  wire [7:0] gfx3_1_1_reg_out;
  wire [7:0] gfx3_1_2_reg_out;
  wire [7:0] gfx3_1_3_reg_out;
  wire [7:0] gfx3_1_4_reg_out;
  wire [7:0] gfx3_2_1_reg_out;
  wire [7:0] gfx3_2_2_reg_out;
  wire [7:0] gfx3_2_3_reg_out;
  wire [7:0] gfx3_2_4_reg_out;

  reg gfx3_1_1_reg_load;
  reg gfx3_1_2_reg_load;
  reg gfx3_1_3_reg_load;
  reg gfx3_1_4_reg_load;
  reg gfx3_2_1_reg_load;
  reg gfx3_2_2_reg_load;
  reg gfx3_2_3_reg_load;
  reg gfx3_2_4_reg_load;

  reg        sprite_counter_inc;
  wire [4:0] sprite_counter_out; 
  
  // counter (32 sprites)
  generic_counter #(5) sprite_counter(
    .inc(sprite_counter_inc), 
    .out(sprite_counter_out), 
    .rst_b(rst_b), 
    .clk(video_clk), 
    .clr(1'b0)
  );
 
  generic_register #(8) gfx3_1_1_reg(
    .in(gfx3_1_read_data), 
    .out(gfx3_1_1_reg_out), 
    .load(gfx3_1_1_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) gfx3_1_2_reg(
    .in(gfx3_1_read_data), 
    .out(gfx3_1_2_reg_out), 
    .load(gfx3_1_2_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) gfx3_1_3_reg(
    .in(gfx3_1_read_data), 
    .out(gfx3_1_3_reg_out), 
    .load(gfx3_1_3_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) gfx3_1_4_reg(
    .in(gfx3_1_read_data), 
    .out(gfx3_1_4_reg_out), 
    .load(gfx3_1_4_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) gfx3_2_1_reg(
    .in(gfx3_2_read_data), 
    .out(gfx3_2_1_reg_out), 
    .load(gfx3_2_1_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) gfx3_2_2_reg(
    .in(gfx3_2_read_data), 
    .out(gfx3_2_2_reg_out), 
    .load(gfx3_2_2_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) gfx3_2_3_reg(
    .in(gfx3_2_read_data), 
    .out(gfx3_2_3_reg_out), 
    .load(gfx3_2_3_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) gfx3_2_4_reg(
    .in(gfx3_2_read_data), 
    .out(gfx3_2_4_reg_out), 
    .load(gfx3_2_4_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  wire [7:0] spriteram_code_reg_data, spriteram_color_reg_data, spriteram_sy_reg_data, spriteram_sx_reg_data;
  reg spriteram_code_reg_load, spriteram_color_reg_load, spriteram_sy_reg_load, spriteram_sx_reg_load;
 
  generic_register #(8) spriteram_code_reg(
    .in(spriteram_read_data), 
    .out(spriteram_code_reg_data), 
    .load(spriteram_code_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) spriteram_color_reg(
    .in(spriteram_read_data), 
    .out(spriteram_color_reg_data), 
    .load(spriteram_color_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) spriteram_sy_reg(
    .in(spriteram_read_data), 
    .out(spriteram_sy_reg_data), 
    .load(spriteram_sy_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  generic_register #(8) spriteram_sx_reg(
    .in(spriteram_read_data), 
    .out(spriteram_sx_reg_data), 
    .load(spriteram_sx_reg_load), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );

  wire      linebuffers_full;
  reg       linebuffers_load;
  reg [8:0] sprite_sx;

  sprite_linebuffers linebuffers(
    .bitplane1({gfx3_1_4_reg_out[3:0], gfx3_1_3_reg_out[3:0], gfx3_1_2_reg_out[3:0], gfx3_1_1_reg_out[3:0]}),
    .bitplane2({gfx3_1_4_reg_out[7:4], gfx3_1_3_reg_out[7:4], gfx3_1_2_reg_out[7:4], gfx3_1_1_reg_out[7:4]}),
    .bitplane3({gfx3_2_4_reg_out[3:0], gfx3_2_3_reg_out[3:0], gfx3_2_2_reg_out[3:0], gfx3_2_1_reg_out[3:0]}),
    .bitplane4({gfx3_2_4_reg_out[7:4], gfx3_2_3_reg_out[7:4], gfx3_2_2_reg_out[7:4], gfx3_2_1_reg_out[7:4]}),
    .color(spriteram_color_reg_data[3:0]),
    .sx(sprite_sx),
    .load(linebuffers_load),
    .clr(linebuffers_clr),
    .clk(video_clk),
    .rst_b(rst_b),
    .sel(column),
    .flop_linebuffers(flop_linebuffers),
    .transparent(sprite_linebuffer_color_transparent),
    .full(linebuffers_full),
    .out(sprite_linebuffer_color)
  );
 
  reg [3:0] sprite_pipeline_state, sprite_pipeline_next_state;
  
  // sprite pipeline fsm
  always @(posedge video_clk or negedge rst_b) begin
    if (~rst_b) begin
      sprite_pipeline_state <= `SPRITE_PIPELINE_IDLE;
    end else begin
      sprite_pipeline_state <= sprite_pipeline_next_state;
    end
  end
  
  // spriteram address logic
  reg [15:0] spriteram_addr_computed;

  always @(*) begin
    spriteram_addr_computed = (31 - sprite_counter_out) << 2; // (32 - offs)*4
  end
  
  // sprite relevance, address, color, and position logic
  reg [1:0]  sprite_i;
  reg        sprite_in_scanline;
  reg [15:0] sprite_code;
  reg [15:0] sprite_code_rom_addr_1, sprite_code_rom_addr_2, sprite_code_rom_addr_3, sprite_code_rom_addr_4;
  reg [3:0]  sprite_color;
  reg [1:0]  sprite_i_effective;

  always @(*) begin
    // defaults
    sprite_i_effective = 0;
    sprite_in_scanline = 0;
    
    // double/quadruple height
    sprite_i = spriteram_color_reg_data[7:6];

    if (sprite_i == 2) sprite_i = 3;
    
    // checking if sprite falls in scanline
    if (spriteram_sy_reg_data >= scanline) begin
     sprite_in_scanline = 0;
    end else if (spriteram_sy_reg_data + 16 >= scanline) begin
      sprite_in_scanline = 1;
      sprite_i_effective = 0;
    end else if ((sprite_i >= 1) && (spriteram_sy_reg_data + 32 >= scanline)) begin
      sprite_in_scanline = 1;
      sprite_i_effective = 1;
    end else if ((sprite_i >= 2) && (spriteram_sy_reg_data + 48 >= scanline)) begin
      sprite_in_scanline = 1;
      sprite_i_effective = 2;
    end else if ((sprite_i == 3) && (spriteram_sy_reg_data + 64 >= scanline)) begin
      sprite_in_scanline = 1;
      sprite_i_effective = 3;
    end
    
    // compute code address
    sprite_code = {spriteram_code_reg_data[7], spriteram_color_reg_data[5], spriteram_code_reg_data[6:0]};
    sprite_code = (sprite_code + sprite_i_effective) << 6;    

    // addresses to roms
    sprite_code = sprite_code + (((scanline - 1 - spriteram_sy_reg_data) % 16) * 2); // 16*row of sprite tile
    sprite_code_rom_addr_1 = sprite_code;
    sprite_code_rom_addr_2 = sprite_code + 1;
    sprite_code_rom_addr_3 = sprite_code + 32;
    sprite_code_rom_addr_4 = sprite_code + 32 + 1;
    
    // color
    sprite_color = spriteram_color_reg_data[3:0];
    
    // x-position
    sprite_sx = spriteram_sx_reg_data - (spriteram_color_reg_data[4] << 8);

  end
  
  // sprite pipeline output function
  always @(*) begin
    // defaults
    sprite_pipeline_next_state = `SPRITE_PIPELINE_IDLE;
    sprite_counter_inc         = 0;
    spriteram_code_reg_load    = 0;
    spriteram_color_reg_load   = 0;
    spriteram_sy_reg_load      = 0;
    spriteram_sx_reg_load      = 0;
    gfx3_1_1_reg_load          = 0;
    gfx3_1_2_reg_load          = 0;
    gfx3_1_3_reg_load          = 0;
    gfx3_1_4_reg_load          = 0;
    gfx3_2_1_reg_load          = 0;
    gfx3_2_2_reg_load          = 0;
    gfx3_2_3_reg_load          = 0;
    gfx3_2_4_reg_load          = 0;
    linebuffers_load           = 0;
    gfx3_1_read_addr           = 0;
    gfx3_2_read_addr           = 0;
    spriteram_addr             = 0;
    
    case (sprite_pipeline_state)
      `SPRITE_PIPELINE_IDLE: begin
        if (sprite_pipeline_start) begin
          sprite_pipeline_next_state = `SPRITE_PIPELINE_FETCH_RAM_1;
        end
      end
      `SPRITE_PIPELINE_FETCH_RAM_1: begin
        sprite_pipeline_next_state = `SPRITE_PIPELINE_FETCH_RAM_2;
        spriteram_addr             = spriteram_addr_computed;
      end
      `SPRITE_PIPELINE_FETCH_RAM_2: begin
        sprite_pipeline_next_state = `SPRITE_PIPELINE_FETCH_RAM_3;
        spriteram_addr             = spriteram_addr_computed + 1;
        spriteram_code_reg_load    = 1;
      end
      `SPRITE_PIPELINE_FETCH_RAM_3: begin
        sprite_pipeline_next_state = `SPRITE_PIPELINE_FETCH_RAM_4;
        spriteram_addr             = spriteram_addr_computed + 2;
        spriteram_color_reg_load   = 1;
      end
      `SPRITE_PIPELINE_FETCH_RAM_4: begin
        sprite_pipeline_next_state = `SPRITE_PIPELINE_EVALUATE;
        spriteram_addr             = spriteram_addr_computed + 3;
        spriteram_sy_reg_load      = 1;
      end
      `SPRITE_PIPELINE_EVALUATE: begin
        spriteram_sx_reg_load = 1;

        if (linebuffers_full) begin
          sprite_pipeline_next_state = `SPRITE_PIPELINE_IDLE;
        end else if (sprite_in_scanline) begin
          sprite_pipeline_next_state = `SPRITE_PIPELINE_FETCH_ROM_1;
          gfx3_1_read_addr = sprite_code_rom_addr_1;
          gfx3_2_read_addr = sprite_code_rom_addr_1;
        end else begin
          if (sprite_counter_out == 5'd31) begin
            sprite_pipeline_next_state = `SPRITE_PIPELINE_IDLE;
          end else begin
            sprite_pipeline_next_state = `SPRITE_PIPELINE_FETCH_RAM_1;
          end
          sprite_counter_inc    = 1;
        end
      end
      `SPRITE_PIPELINE_FETCH_ROM_1: begin
        sprite_pipeline_next_state = `SPRITE_PIPELINE_FETCH_ROM_2;
        gfx3_1_read_addr  = sprite_code_rom_addr_2;
        gfx3_2_read_addr  = sprite_code_rom_addr_2;
        gfx3_1_1_reg_load = 1;
        gfx3_2_1_reg_load = 1;
      end
       `SPRITE_PIPELINE_FETCH_ROM_2: begin
        sprite_pipeline_next_state = `SPRITE_PIPELINE_FETCH_ROM_3;
        gfx3_1_read_addr  = sprite_code_rom_addr_3;
        gfx3_2_read_addr  = sprite_code_rom_addr_3;
        gfx3_1_2_reg_load = 1;
        gfx3_2_2_reg_load = 1;
      end
      `SPRITE_PIPELINE_FETCH_ROM_3: begin
        sprite_pipeline_next_state = `SPRITE_PIPELINE_FETCH_ROM_4;
        gfx3_1_read_addr  = sprite_code_rom_addr_4;
        gfx3_2_read_addr  = sprite_code_rom_addr_4;
        gfx3_1_3_reg_load = 1;
        gfx3_2_3_reg_load = 1;
      end
      `SPRITE_PIPELINE_FETCH_ROM_4: begin
        sprite_pipeline_next_state = `SPRITE_PIPELINE_COMMIT;
        gfx3_1_4_reg_load = 1;
        gfx3_2_4_reg_load = 1;
      end
      `SPRITE_PIPELINE_COMMIT: begin
        linebuffers_load   = 1;
        sprite_counter_inc = 1;

        if (sprite_counter_out == 5'd31) begin
          sprite_pipeline_next_state = `SPRITE_PIPELINE_IDLE;
        end else begin
          sprite_pipeline_next_state = `SPRITE_PIPELINE_FETCH_RAM_1;
        end
      end
    endcase
  end
  
endmodule


module sprite_linebuffer (
  input  wire [15:0] bitplane1,
  input  wire [15:0] bitplane2,
  input  wire [15:0] bitplane3,
  input  wire [15:0] bitplane4,
  input  wire [8:0]  sx,
  input  wire [7:0]  sel,
  input  wire [3:0]  color,
  input  wire load,
  input  wire clr,
  input  wire clk,
  input  wire rst_b,
  input  wire flop_linebuffer,
  output wire transparent,
  output reg  valid_out,
  output wire [7:0] out);

  reg [15:0] b1, b2, b3, b4;
  reg [8:0]  sx_internal;
  reg [15:0] b1_f, b2_f, b3_f, b4_f;
  reg [8:0]  sx_f;
  reg valid;
  reg valid_f;
  reg [3:0] colorbase;
  reg [3:0] colorbase_f;

  always @(posedge clk or negedge rst_b) begin
    if (~rst_b) begin
      b1 <= 0;
      b2 <= 0;
      b3 <= 0;
      b4 <= 0;
      b1_f <= 0;
      b2_f <= 0;
      b3_f <= 0;
      b4_f <= 0;
      valid <= 0;
      valid_f <= 0;
      colorbase <= 0;
      colorbase_f <= 0;
      sx_internal <= 0;
      sx_f        <= 0;
    end
    else if (clr) begin
      valid <= 0;  
    end
    else if (load) begin
      b1 <= bitplane1;
      b2 <= bitplane2;
      b3 <= bitplane3;
      b4 <= bitplane4;
      colorbase <= color;
      sx_internal <= sx;
      valid <= 1;
    end
    else if (flop_linebuffer) begin
      sx_f <= sx_internal;
      b1_f <= b1;
      b2_f <= b2;
      b3_f <= b3;
      b4_f <= b4;
      colorbase_f <= colorbase;
      valid_f <= valid;
    end
  end

  wire [3:0] coloroffset;
  reg  [3:0] linebuffer_sel;

  always @(*) begin
    linebuffer_sel = 0;
    valid_out      = 0;

    if (sel >= sx_f && sel < sx_f + 16) begin
      linebuffer_sel = sel[3:0] - sx_f;
      valid_out      = valid_f;

      linebuffer_sel = {linebuffer_sel[3:2], ~linebuffer_sel[1:0]};
    end
    else if ( (sx_f - 496) < 16 && sel < (sx_f - 496) && sx_f > 496) begin
      linebuffer_sel = sel[3:0] - (sx_f - 496);
      linebuffer_sel = {linebuffer_sel[3:2], ~linebuffer_sel[1:0]};
      valid_out      = valid_f;
    end
  end

  assign coloroffset = {b3_f[linebuffer_sel], b4_f[linebuffer_sel],
                        b1_f[linebuffer_sel], b2_f[linebuffer_sel]};
  assign transparent = (coloroffset == 4'b1111);
  assign out         = {colorbase_f, coloroffset};

endmodule

module sprite_linebuffers (
  input  wire [15:0] bitplane1,
  input  wire [15:0] bitplane2,
  input  wire [15:0] bitplane3,
  input  wire [15:0] bitplane4,
  input  wire [3:0]  color,
  input  wire [8:0]  sx,
  input  wire [7:0]  sel,
  input  wire        load,
  input  wire        clr,
  input  wire        clk,
  input  wire        rst_b,
  input  wire        flop_linebuffers,
  output wire        full,
  output reg         transparent,
  output reg  [7:0]  out);

  reg splb_1_load;
  reg splb_2_load;
  reg splb_3_load;
  reg splb_4_load;
  reg splb_5_load;
  reg splb_6_load;
  reg splb_7_load;
  reg splb_8_load;

  wire splb_1_valid;
  wire splb_2_valid;
  wire splb_3_valid;
  wire splb_4_valid;
  wire splb_5_valid;
  wire splb_6_valid;
  wire splb_7_valid;
  wire splb_8_valid;

  wire splb_1_transparent;
  wire splb_2_transparent;
  wire splb_3_transparent;
  wire splb_4_transparent;
  wire splb_5_transparent;
  wire splb_6_transparent;
  wire splb_7_transparent;
  wire splb_8_transparent;

  wire [7:0] splb_1_out;
  wire [7:0] splb_2_out;
  wire [7:0] splb_3_out;
  wire [7:0] splb_4_out;
  wire [7:0] splb_5_out;
  wire [7:0] splb_6_out;
  wire [7:0] splb_7_out;
  wire [7:0] splb_8_out;

  sprite_linebuffer splb_1(
    .bitplane1(bitplane1), 
    .bitplane2(bitplane2), 
    .bitplane3(bitplane3), 
    .bitplane4(bitplane4), 
    .color(color), 
    .sx(sx), 
    .load(splb_1_load), 
    .clr(clr), 
    .clk(clk), 
    .rst_b(rst_b), 
    .flop_linebuffer(flop_linebuffers), 
    .sel(sel), 
    .transparent(splb_1_transparent), 
    .valid_out(splb_1_valid), 
    .out(splb_1_out)
  );

  sprite_linebuffer splb_2(
    .bitplane1(bitplane1), 
    .bitplane2(bitplane2), 
    .bitplane3(bitplane3), 
    .bitplane4(bitplane4), 
    .color(color), 
    .sx(sx), 
    .load(splb_2_load), 
    .clr(clr), 
    .clk(clk), 
    .rst_b(rst_b), 
    .flop_linebuffer(flop_linebuffers), 
    .sel(sel), 
    .transparent(splb_2_transparent), 
    .valid_out(splb_2_valid), 
    .out(splb_2_out)
  );

  sprite_linebuffer splb_3(
    .bitplane1(bitplane1), 
    .bitplane2(bitplane2), 
    .bitplane3(bitplane3), 
    .bitplane4(bitplane4), 
    .color(color), 
    .sx(sx), 
    .load(splb_3_load), 
    .clr(clr), 
    .clk(clk), 
    .rst_b(rst_b), 
    .flop_linebuffer(flop_linebuffers), 
    .sel(sel), 
    .transparent(splb_3_transparent), 
    .valid_out(splb_3_valid), 
    .out(splb_3_out)
  );

  sprite_linebuffer splb_4(
    .bitplane1(bitplane1), 
    .bitplane2(bitplane2), 
    .bitplane3(bitplane3), 
    .bitplane4(bitplane4), 
    .color(color), 
    .sx(sx), 
    .load(splb_4_load), 
    .clr(clr), 
    .clk(clk), 
    .rst_b(rst_b), 
    .flop_linebuffer(flop_linebuffers), 
    .sel(sel), 
    .transparent(splb_4_transparent), 
    .valid_out(splb_4_valid), 
    .out(splb_4_out)
  );

  sprite_linebuffer splb_5(
    .bitplane1(bitplane1), 
    .bitplane2(bitplane2), 
    .bitplane3(bitplane3), 
    .bitplane4(bitplane4), 
    .color(color), 
    .sx(sx), 
    .load(splb_5_load), 
    .clr(clr), 
    .clk(clk), 
    .rst_b(rst_b), 
    .flop_linebuffer(flop_linebuffers), 
    .sel(sel), 
    .transparent(splb_5_transparent), 
    .valid_out(splb_5_valid), 
    .out(splb_5_out)
  );

  sprite_linebuffer splb_6(
    .bitplane1(bitplane1), 
    .bitplane2(bitplane2), 
    .bitplane3(bitplane3), 
    .bitplane4(bitplane4), 
    .color(color), 
    .sx(sx), 
    .load(splb_6_load), 
    .clr(clr), 
    .clk(clk), 
    .rst_b(rst_b), 
    .flop_linebuffer(flop_linebuffers), 
    .sel(sel), 
    .transparent(splb_6_transparent), 
    .valid_out(splb_6_valid), 
    .out(splb_6_out));

  sprite_linebuffer splb_7(
    .bitplane1(bitplane1), 
    .bitplane2(bitplane2), 
    .bitplane3(bitplane3), 
    .bitplane4(bitplane4), 
    .color(color), 
    .sx(sx), 
    .load(splb_7_load), 
    .clr(clr), 
    .clk(clk), 
    .rst_b(rst_b), 
    .flop_linebuffer(flop_linebuffers), 
    .sel(sel), 
    .transparent(splb_7_transparent), 
    .valid_out(splb_7_valid), 
    .out(splb_7_out)
  );

  sprite_linebuffer splb_8(
    .bitplane1(bitplane1), 
    .bitplane2(bitplane2), 
    .bitplane3(bitplane3), 
    .bitplane4(bitplane4), 
    .color(color), 
    .sx(sx), 
    .load(splb_8_load), 
    .clr(clr), 
    .clk(clk), 
    .rst_b(rst_b), 
    .flop_linebuffer(flop_linebuffers), 
    .sel(sel), 
    .transparent(splb_8_transparent), 
    .valid_out(splb_8_valid), 
    .out(splb_8_out)
  );

 
  reg linebuffer_count_inc;
  wire [3:0] linebuffer_count_out;
 
  generic_counter #(4) linebuffer_count(
    .inc(linebuffer_count_inc), 
    .out(linebuffer_count_out), 
    .clr(clr), 
    .rst_b(rst_b),
    .clk(clk)
  );

  assign full = (linebuffer_count_out == 4'd8);

  always @(*) begin
    splb_1_load = 0;
    splb_2_load = 0;
    splb_3_load = 0;
    splb_4_load = 0;
    splb_5_load = 0;
    splb_6_load = 0;
    splb_7_load = 0;
    splb_8_load = 0;
    linebuffer_count_inc = 0;

    // load selection logic
    if (load) begin
      if      (linebuffer_count_out == 4'd0) splb_1_load = 1;      
      else if (linebuffer_count_out == 4'd1) splb_2_load = 1;      
      else if (linebuffer_count_out == 4'd2) splb_3_load = 1;      
      else if (linebuffer_count_out == 4'd3) splb_4_load = 1;      
      else if (linebuffer_count_out == 4'd4) splb_5_load = 1;      
      else if (linebuffer_count_out == 4'd5) splb_6_load = 1;      
      else if (linebuffer_count_out == 4'd6) splb_7_load = 1;      
      else if (linebuffer_count_out == 4'd7) splb_8_load = 1;

      linebuffer_count_inc = 1;      
    end

    // priority selection logic
    transparent = 0;
    out         = 0;
    if      (splb_1_valid && !splb_1_transparent) out = splb_1_out;
    else if (splb_2_valid && !splb_2_transparent) out = splb_2_out;
    else if (splb_3_valid && !splb_3_transparent) out = splb_3_out;
    else if (splb_4_valid && !splb_4_transparent) out = splb_4_out;
    else if (splb_5_valid && !splb_5_transparent) out = splb_5_out;
    else if (splb_6_valid && !splb_6_transparent) out = splb_6_out;
    else if (splb_7_valid && !splb_7_transparent) out = splb_7_out;
    else if (splb_8_valid && !splb_8_transparent) out = splb_8_out;
    else transparent = 1;
  end

endmodule

/* 
renders pixel using pipeline
  -reads linebuffer
  -implements color priority logic
  -accesses palette
  -outputs rgb
  */
module renderer_pipeline(
  input  wire [11:0] palette_data,
  input  wire [9:0]  bg_linebuffer_color,
  input  wire [7:0]  fg_linebuffer_color,
  input  wire [7:0]  sprite_linebuffer_color,
  input  wire        fg_linebuffer_color_transparent,
  input  wire        sprite_linebuffer_color_transparent,
  input  wire        video_clk, rst_b,
  input  wire        render_pipeline,
  input  wire [7:0]  dip,
  output wire [15:0] palette_addr,
  output reg  [2:0]  linebuffer_bit,
  output wire [3:0]  rgb_r,
  output wire [3:0]  rgb_b,
  output wire [3:0]  rgb_g);
  
  // linebuffer bit counter 0...7 repeatedly
  always @(posedge video_clk or negedge rst_b) begin
    if      (~rst_b)          linebuffer_bit <= 4;
    else if (render_pipeline) linebuffer_bit <= linebuffer_bit - 1;
  end
  
  // color priority logic and palette access
  reg [10:0] palette_addr_0;
  
  always @(*) begin
    // default - color = bg
    //palette_addr_0 = 0;
    palette_addr_0 = bg_linebuffer_color + 256;

    // second priority - fg
    if (!fg_linebuffer_color_transparent) begin
      palette_addr_0 = fg_linebuffer_color + 0;
    end
    
    // first priority - sprite
    if (!sprite_linebuffer_color_transparent) begin
      palette_addr_0 = sprite_linebuffer_color + 1280;
    end
    
    // display black if not rendering
    if (!render_pipeline) palette_addr_0 = 0;
  end
  
  // flop address (pipeline)
  generic_register #(11) palette_addr_reg(
    .in(palette_addr_0), 
    .out(palette_addr[10:0]), 
    .load(1'd1), 
    .clk(video_clk), 
    .rst_b(rst_b)
  );
 
  assign palette_addr[15:11] = 5'd0;
 
  // output (delayed by 1 cycle)
  assign rgb_r = palette_data[11:8];
  assign rgb_g = palette_data[7:4];
  assign rgb_b = palette_data[3:0];

endmodule

//------------------------------------------------------------------------------
// Library
//------------------------------------------------------------------------------

/*
// generic ram
// synthesize as bram
module generic_ram(
  input [7:0] data_in,
  input [7:0] write_addr,
  input [7:0] read_addr,
  input write,
  input clk,
  input rst_b,
  output [7:0] data_out);
  
  parameter width = 2048;

  reg [7:0] ram [width-1:0];
  
  // write
  always @(posedge clk) begin
    if (~rst_b) ram <= 0;
    else if (write) ram[write_addr][7:0] <= data_in;
  end
  
  // read
  assign data_out[7:0] = ram[read_addr][7:0];
  
endmodule

// generic tiny ram
// synthesize as flops
module generic_tiny_ram(
  input [7:0] data_in,
  input [7:0] write_addr,
  input [7:0] read_addr,
  input write,
  input clk,
  input rst_b,
  output [7:0] data_out);
  
  parameter width = 2;

  reg [7:0] ram [width-1:0];
  
  // write
  always @(posedge clk) begin
    if (~rst_b) ram <= 0;
    else if (write) ram[write_addr][7:0] <= data_in;
  end
  
  // read
  assign data_out[7:0] = ram[read_addr][7:0];
  
endmodule
*/

module generic_counter
  #(parameter width = 5)
  (
    input  wire inc,
    input  wire clr,
    input  wire clk,
    input  wire rst_b,
    output reg [width-1:0] out
  );

  always @(posedge clk or negedge rst_b) begin
    if      (~rst_b) out <= 0;
    else if (clr)    out <= 0;
    else if (inc)    out <= out + 1;
  end

endmodule

module generic_register
  #(parameter width = 8)
  (
    input  wire load,
    input  wire clk,
    input  wire rst_b,
    input  wire [width-1:0] in,
    output reg  [width-1:0] out
  );

  
  always @(posedge clk or negedge rst_b) begin
    if      (~rst_b) out <= 0;
    else if (load)   out <= in;
  end
  
endmodule
/*
module generic_linebuffer
  #(parameter width=8)
  (
    input [width-1:0] in,
    input [$clog2(width)-1:0] sel,
    input load,
    input clk,
    input rst_b,
    output wire out
  );

  
  reg [width-1:0] data;
  
  always @(posedge clk or negedge rst_b) begin
    if (~rst_b) data <= 0;
    else if (load) data <= in;
  end
  
  assign out = data[sel];
  
endmodule
*/

module linebuffer8
  (
    input  wire [7:0] in,
    input  wire [2:0] sel,
    input  wire load,
    input  wire clk,
    input  wire rst_b,
    output wire out
  );

  reg [7:0] data;
  
  always @(posedge clk or negedge rst_b) begin
    if      (~rst_b) data <= 0;
    else if (load)   data <= in;
  end
  
  assign out = data[sel];
  
endmodule
  
  // Scrolling logic
module bg_scroller(
    // inputs
    input wire [7:0]  scanline,
    input wire [9:0]  column,
    input wire [8:0]  bg_column,
    input wire [15:0] scroll_read_data,
    input wire        video_clk, 
    input wire        rst_b,
    input wire [9:0]  orig_bg_linebuffer_color,
    input wire        load_bg_scanline_buffer,
    
    // outputs
    output reg  [2:0] bg_linebuffer_bit,
    output wire [9:0] new_bg_linebuffer_color
  );
  
  reg  [9:0] flopped_color [511:0];
  wire [8:0] buffer_index;
  
  assign buffer_index = column + scroll_read_data[3:0];
  
  assign new_bg_linebuffer_color = flopped_color[buffer_index];
  
  // linebuffer bit counter 0...7 repeatedly
  always @(posedge video_clk or negedge rst_b) begin
    if      (~rst_b)                  bg_linebuffer_bit <= 5;
    else if (load_bg_scanline_buffer) bg_linebuffer_bit <= bg_linebuffer_bit - 1;
    else                              bg_linebuffer_bit <= 5;
  end
  
  always @(posedge video_clk) begin
    if (load_bg_scanline_buffer)
      flopped_color[bg_column] <= orig_bg_linebuffer_color;
  end
  
  
endmodule 
