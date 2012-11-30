`define MAINCPU 1'b0
`define AUDIOCPU 1'd1

`default_nettype none

// maincpu - 00000 - 07FFF
// maincpu bank1 - 10000 - 13FFF
// maincpu bank2 - 14000 - 15FFF
// maincpu bank3 - 18000 - 1BFFF

// maincpu RAM - E000 - EFFF

 // 0000-bfff ROM (8000-bfff banked)
 // cc00-cc7f Sprites
 // d000-d3ff Video RAM
 // d400-d7ff Color RAM
 // d800-dbff Background RAM (groups of 32 bytes, 16 code, 16 color/attribute)
 // e000-efff RAM

module memory_map (cpu_clk, video_clk, cpu_write, rst_b,
  cpu_address, cpu_data_in, cpu_data_out, fgvideoram_read_data,
  bgvideoram_read_data, spriteram_read_data, palette_bank_read_data, scroll_read_data, fgvideoram_read_addr,
  bgvideoram_read_addr, spriteram_read_addr, gfx1_read_data, gfx2_bitplane_1_read_data, gfx2_bitplane_2_read_data,
  gfx2_bitplane_3_read_data, gfx3_1_read_data, gfx3_2_read_data, palette_read_data, gfx1_read_addr,
  gfx2_bitplane_1_read_addr, gfx2_bitplane_2_read_addr, gfx2_bitplane_3_read_addr, gfx3_1_read_addr, gfx3_2_read_addr,
  palette_read_addr, up, down, left, right, fire, special, p1_start, p2_start, coin, dip, soundlatch);

  input up, down, left, right;
  input p1_start, p2_start, coin, fire, special;
  input [7:0] dip;

  input cpu_clk, video_clk, rst_b;
  input cpu_write;           // 1 to enable
  input [15:0] cpu_address;  //to read/write
  input [7:0]  cpu_data_in;

  output reg [7:0] cpu_data_out;

  wire [7:0] cpu_bgvideo_out;
  wire [7:0] cpu_fgvideo_out;
  wire [7:0] cpu_spram_out;

  // Video controller

  output [7:0]  fgvideoram_read_data;
  output [7:0]  bgvideoram_read_data;
  output [7:0]  spriteram_read_data;
  output [1:0]  palette_bank_read_data;
  output [15:0] scroll_read_data;

  input [15:0] fgvideoram_read_addr;
  input [15:0] bgvideoram_read_addr;
  input [15:0] spriteram_read_addr;

  // ROM
  output [7:0]  gfx1_read_data;
  output [7:0]  gfx2_bitplane_1_read_data;
  output [7:0]  gfx2_bitplane_2_read_data;
  output [7:0]  gfx2_bitplane_3_read_data;
  output [7:0]  gfx3_1_read_data;
  output [7:0]  gfx3_2_read_data;
  output [15:0] palette_read_data;

  input [15:0] gfx1_read_addr;
  input [15:0] gfx2_bitplane_1_read_addr;
  input [15:0] gfx2_bitplane_2_read_addr;
  input [15:0] gfx2_bitplane_3_read_addr;
  input [15:0] gfx3_1_read_addr;
  input [15:0] gfx3_2_read_addr;
  input [15:0] palette_read_addr;

  output wire [7:0] soundlatch;

  wire [7:0] data_maincpu_rom;
  wire [7:0] data_maincpu_bank1_rom;
  wire [7:0] data_maincpu_bank2_rom;
  wire [7:0] data_maincpu_bank3_rom;
  wire [7:0] data_maincpu_ram;

  wire [1:0]  bank_switch;
  wire [7:0]  c804, palette_bank, scroll_high, scroll_low;

  reg cpu_write_ram, cpu_write_bg, cpu_write_fg, cpu_write_sprite;


  // ---------------- ROMs --------------------

  maincpu_BRAM cpu_rom (
    .clka(cpu_clk),            // input  clka
    .addra(cpu_address[14:0]), // input  [14 : 0] addra
    .douta(data_maincpu_rom)   // output [7 : 0] douta
  );

  maincpu_bank1_BRAM cpu_bank1_rom (
    .clka(cpu_clk),                // input  clka
    .addra(cpu_address[13:0]),     // input  [13 : 0] addra
    .douta(data_maincpu_bank1_rom) // output [7 : 0]  douta
  );

  maincpu_bank2_BRAM cpu_bank2_rom (
    .clka(cpu_clk),                // input  clka
    .addra(cpu_address[12:0]),     // input  [12 : 0] addra
    .douta(data_maincpu_bank2_rom) // output [7 : 0]  douta
  );

  maincpu_bank3_BRAM cpu_bank3_rom (
    .clka(cpu_clk),                // input  clka
    .addra(cpu_address[13:0]),     // input  [13 : 0] addra
    .douta(data_maincpu_bank3_rom) // output [7 : 0]  douta
  );

  // ------------------ RAMs -----------------------

  maincpu_ram cpu_ram (
    .clka(cpu_clk),            // input  clka
    .wea(cpu_write_ram),       // input  [0 : 0]  wea
    .addra(cpu_address[11:0]), // input  [11 : 0] addra
    .dina(cpu_data_in),        // input  [7 : 0]  dina
    .douta(data_maincpu_ram)   // output [7 : 0]  douta
  );

  bgvideoram bgram (
    .clka(video_clk),                   // input  clka
    .wea(1'b0),                         // input  [0 : 0]  wea
    .addra({1'b0, bgvideoram_read_addr[9:0]}), // input  [10 : 0] addra
    .dina(8'd0),                        // input  [7 : 0]  dina
    .douta(bgvideoram_read_data),       // output [7 : 0]  douta
    .clkb(cpu_clk),                     // input  clkb
    .web(cpu_write_bg),                 // input  [0 : 0]  web
    .addrb({1'b0, cpu_address[9:0]}),          // input  [10 : 0] addrb
    .dinb(cpu_data_in),                 // input  [7 : 0]  dinb
    .doutb(cpu_bgvideo_out)             // output [7 : 0]  doutb
  );

  fgvideoram fgram (
    .clka(video_clk),                   // input  clka
    .wea(1'b0),                         // input  [0 : 0]  wea
    .addra(fgvideoram_read_addr[10:0]), // input  [10 : 0] addra
    .dina(8'd0),                        // input  [7 : 0]  dina
    .douta(fgvideoram_read_data),       // output [7 : 0]  douta
    .clkb(cpu_clk),                     // input  clkb
    .web(cpu_write_fg),                 // input  [0 : 0]  web
    .addrb(cpu_address[10:0]),          // input  [10 : 0] addrb
    .dinb(cpu_data_in),                 // input  [7 : 0]  dinb
    .doutb(cpu_fgvideo_out)             // output [7 : 0]  doutb
  );

  spriteram spram (
    .clka(video_clk),                  // input  clka
    .wea(1'b0),                        // input  [0 : 0]  wea
    .addra(spriteram_read_addr[6:0]),  // input  [6 : 0]  addra
    .dina(8'd0),                       // input  [7 : 0]  dina
    .douta(spriteram_read_data),       // output [7 : 0]  douta
    .clkb(cpu_clk),                    // input  clkb
    .web(cpu_write_sprite),            // input  [0 : 0]  web
    .addrb(cpu_address[6:0]),          // input  [6 : 0]  addrb
    .dinb(cpu_data_in),                // input  [7 : 0]  dinb
    .doutb(cpu_spram_out)              // output [7 : 0]  doutb
  );

  gfx1_BRAM gfx1ram (
    .clka(video_clk),             // input  clka
    .addra(gfx1_read_addr[12:0]), // input  [12 : 0] addra
    .douta(gfx1_read_data)        // output [7 : 0]  douta
  );

  gfx2_1_BRAM gfx21ram (
    .clka(video_clk),                        // input  clka
    .addra(gfx2_bitplane_1_read_addr[13:0]), // input  [13 : 0] addra
    .douta(gfx2_bitplane_1_read_data)        // output [7 : 0]  douta
  );

  gfx2_2_BRAM gfx22ram (
    .clka(video_clk),                        // input  clka
    .addra(gfx2_bitplane_2_read_addr[13:0]), // input  [13 : 0] addra
    .douta(gfx2_bitplane_2_read_data)        // output [7 : 0]  douta
  );

  gfx2_3_BRAM gfx23ram (
    .clka(video_clk),                        // input  clka
    .addra(gfx2_bitplane_3_read_addr[13:0]), // input  [13 : 0] addra
    .douta(gfx2_bitplane_3_read_data)        // output [7 : 0]  douta
  );

  gfx3_1_BRAM gfx31ram (
    .clka(video_clk),               // input  clka
    .addra(gfx3_1_read_addr[14:0]), // input  [14 : 0] addra
    .douta(gfx3_1_read_data)        // output [7 : 0]  douta
  );

  gfx3_2_BRAM gfx32ram (
    .clka(video_clk),               // input  clka
    .addra(gfx3_2_read_addr[14:0]), // input  [14 : 0] addra
    .douta(gfx3_2_read_data)        // output [7 : 0]  douta
  );

  palette_BRAM palettebram (
    .clka(video_clk),                // input  clka
    .addra(palette_read_addr[10:0]), // input  [10 : 0] addra
    .douta(palette_read_data)        // output [15 : 0] douta
  );

  assign palette_bank_read_data = palette_bank;

  // 0000-bfff ROM (8000-bfff banked)
  // cc00-cc7f Sprites
  // d000-d3ff Video RAM--\fgvideo
  // d400-d7ff Color RAM--/ram
  // d800-dbff Background RAM (groups of 32 bytes, 16 code, 16 color/attribute)
  // e000-efff RAM

  // maincpu - 00000 - 07FFF
  // maincpu bank1 - 10000 - 13FFF
  // maincpu bank2 - 14000 - 15FFF
  // maincpu bank3 - 18000 - 1BFFF

  // maincpu RAM - E000 - EFFF

  //wire [15:0] cpu_address;

  // Writing to registers

  generic_register #(8) sl_reg   (
    .in(cpu_data_in), 
    .load((cpu_address == 16'hc800) & cpu_write), 
    .clk(cpu_clk), 
    .rst_b(rst_b), 
    .out(soundlatch));

  generic_register #(8) slow_reg (
    .in(cpu_data_in), 
    .load((cpu_address == 16'hc802) & cpu_write), 
    .clk(cpu_clk), 
    .rst_b(rst_b),
    .out(scroll_low));

  generic_register #(8) shigh_reg(
    .in(cpu_data_in), 
    .load((cpu_address == 16'hc803) & cpu_write), 
    .clk(cpu_clk), 
    .rst_b(rst_b), 
    .out(scroll_high));

  generic_register #(8) c804_reg (
    .in(cpu_data_in), 
    .load((cpu_address == 16'hc804) & cpu_write), 
    .clk(cpu_clk), 
    .rst_b(rst_b), 
    .out(c804));

  generic_register #(8) pb_reg   (
    .in(cpu_data_in), 
    .load((cpu_address == 16'hc805) & cpu_write), 
    .clk(cpu_clk), 
    .rst_b(rst_b), 
    .out(palette_bank));

  generic_register #(2) bs_reg   (
    .in(cpu_data_in[1:0]), 
    .load((cpu_address == 16'hc806) & cpu_write), 
    .clk(cpu_clk), 
    .rst_b(rst_b), 
    .out(bank_switch));

  assign scroll_read_data = {scroll_high, scroll_low};


  always @(*)begin
    cpu_write_sprite = 0;
    cpu_write_ram    = 0;
    cpu_write_fg     = 0;
    cpu_write_bg     = 0;
    cpu_data_out     = 0;

    // main cpu ROM
    if(cpu_address >= 16'h0000 && cpu_address < 16'h8000) begin
      cpu_data_out = data_maincpu_rom;
    // banked ROMs
    end else if(cpu_address >= 16'h8000 && cpu_address < 16'hc000) begin
      case (bank_switch)
        2'b00: // Bank 1
          cpu_data_out = data_maincpu_bank1_rom;
        2'b01: // Bank 2
          cpu_data_out = data_maincpu_bank2_rom;
        2'b10: // Bank 3
          cpu_data_out = data_maincpu_bank3_rom;
      default:
        cpu_data_out = 'd0;
      endcase
    // System port
    end else if (cpu_address == 16'hc000) begin
      cpu_data_out = ~{coin, 5'h00, p2_start, p1_start};//coin1, coin2, all_junk, start2, start1
    // P1 port
    end else if (cpu_address == 16'hc001) begin
      cpu_data_out = ~{1'b0, special, fire, up, down, right, left};
    // P2 port
    end else if (cpu_address == 16'hc002) begin
      cpu_data_out = ~{1'b0, special, fire, up, down, right, left};
     // DSWA port
    end else if (cpu_address == 16'hc003) begin
      cpu_data_out = ~{5'b000, 3'b000};
    // DSWB port
    end else if (cpu_address == 16'hc004) begin
      cpu_data_out = ~{3'b000, dip[0], 3'b000}; // Test mode switch
    end else if (cpu_address == 16'hc800) begin
    // Soundlatch register
      cpu_data_out = soundlatch;
    // Scroll register low
    end else if (cpu_address == 16'hc802) begin
      cpu_data_out = scroll_low;
    // Scroll register high
    end else if (cpu_address == 16'hc803) begin
      cpu_data_out = scroll_high;
    // C804 register
    end else if (cpu_address == 16'hc804) begin
      cpu_data_out = c804;
    // Palette bank register
    end else if (cpu_address == 16'hc805) begin
      cpu_data_out = palette_bank;
    // Bank switch register
    end else if (cpu_address == 16'hc806) begin
      cpu_data_out = bank_switch;
    // sprite RAM
    end else if(cpu_address >= 16'hcc00 && cpu_address < 16'hcc80) begin
      cpu_data_out     = cpu_spram_out;
      cpu_write_sprite = cpu_write;
    // fgvideo RAM
    end else if(cpu_address >= 16'hd000 && cpu_address < 16'hd800) begin
      cpu_data_out = cpu_fgvideo_out;
      cpu_write_fg = cpu_write;
    // bgvideo RAM
    end else if(cpu_address >= 16'hd800 && cpu_address < 16'hdc00) begin
      cpu_data_out = cpu_bgvideo_out;
      cpu_write_bg = cpu_write;
    // maincpu RAM
    end else if(cpu_address >= 16'he000 && cpu_address < 16'hf000) begin
      cpu_data_out  = data_maincpu_ram;
      cpu_write_ram = cpu_write;
    end
  end
endmodule


module video_controller_top
(
  input  wire input_clk, reset, // Add rst_b for synthesis
  input  wire up, down, left, right, fire, special, p1_start, p2_start, coin,
  input  wire [7:0] dip,
  output wire HS, VS,
  output wire [3:0] rgb_r, rgb_g, rgb_b,
  
  // sound
  input  wire ac97_sdata_in,
  output wire ac97_sdata_out,
  output wire ac97_sync,
  output wire ac97_reset_b,
  input  wire ac97_bitclk
  
  );  // RAM

  wire        cpu_clk;
  wire        video_clk;
  wire        cpu_write;   // 1 to enable;
  wire [15:0] cpu_address; // to read/write
  wire [7:0]  cpu_data_in;
  wire [7:0]  cpu_data_out;

  wire [7:0]  fgvideoram_read_data;
  wire [7:0]  bgvideoram_read_data;
  wire [7:0]  spriteram_read_data;
  wire [1:0]  palette_bank_read_data;

  wire [15:0] scroll_read_data;

  wire [15:0] fgvideoram_read_addr;
  wire [15:0] bgvideoram_read_addr;
  wire [15:0] spriteram_read_addr;

  // ROM
  wire [7:0]  gfx1_read_data;
  wire [7:0]  gfx2_bitplane_1_read_data;
  wire [7:0]  gfx2_bitplane_2_read_data;
  wire [7:0]  gfx2_bitplane_3_read_data;
  wire [7:0]  gfx3_1_read_data;
  wire [7:0]  gfx3_2_read_data;
  wire [15:0] palette_read_data;

  wire [15:0] gfx1_read_addr;
  wire [15:0] gfx2_bitplane_1_read_addr;
  wire [15:0] gfx2_bitplane_2_read_addr;
  wire [15:0] gfx2_bitplane_3_read_addr;
  wire [15:0] gfx3_1_read_addr;
  wire [15:0] gfx3_2_read_addr;
  wire [15:0] palette_read_addr;
  
  
  wire [7:0] soundlatch;

  //---------------- VGA controller --------------------------
  wire [9:0] scanline;
  wire [9:0] column;
  wire vga_clk;
  wire clk_100M;

  reg test_clk;
  wire rst_b;
  reg clk_reset;

/* For simulation 
  initial begin
    test_clk = 0;
    clk_reset = 0;
    #10000
    clk_reset = 1;
  end
  initial forever #5 test_clk = ~test_clk;
*/
/* For synthesis */
  always @(*) clk_reset = reset;
  always @(*) test_clk = input_clk; // Remove for simulation

  // Clock for VGA 50Mhz
  freq_divider_50M fd(clk_100M, rst_b, vga_clk);

  // Clock for CPU 6.25Mhz
  clock z80_6_25(
    .CLKIN_IN(test_clk),
    .CLK0_OUT(clk_100M),
    .CLKDV_OUT(cpu_clk),
    .RST_IN(~clk_reset),
    .LOCKED_OUT(rst_b));


  vga v(
    .clk_50M(vga_clk),
    .pixel_clk(video_clk),
    .reset(rst_b),
    .HS(HS),
    .VS(VS),
    .row(scanline),
    .col(column));

  wire j_up, j_down, j_right, j_left, j_p1_start, j_p2_start, j_coin, j_fire, j_special;

  // Joystick controller
  assign j_up       = up;
  assign j_down     = down;
  assign j_left     = left;
  assign j_right    = right;
  assign j_p1_start = p1_start;
  assign j_p2_start = p2_start;
  assign j_coin     = coin;
  assign j_fire     = fire;
  assign j_special  = special;

  // Sprite controller
  video_controller vc(
    .fgvideoram_read_data(fgvideoram_read_data),
    .bgvideoram_read_data(bgvideoram_read_data),
    .spriteram_read_data(spriteram_read_data),
    .palette_bank_read_data(palette_bank_read_data),
    .scroll_read_data(scroll_read_data),
    .fgvideoram_read_addr(fgvideoram_read_addr),
    .bgvideoram_read_addr(bgvideoram_read_addr),
    .spriteram_read_addr(spriteram_read_addr),
    .gfx1_read_data(gfx1_read_data),
    .gfx2_bitplane_1_read_data(gfx2_bitplane_1_read_data),
    .gfx2_bitplane_2_read_data(gfx2_bitplane_2_read_data),
    .gfx2_bitplane_3_read_data(gfx2_bitplane_3_read_data),
    .gfx3_1_read_data(gfx3_1_read_data),
    .gfx3_2_read_data(gfx3_2_read_data),
    .palette_read_data(palette_read_data),
    .gfx1_read_addr(gfx1_read_addr),
    .gfx2_bitplane_1_read_addr(gfx2_bitplane_1_read_addr),
    .gfx2_bitplane_2_read_addr(gfx2_bitplane_2_read_addr),
    .gfx2_bitplane_3_read_addr(gfx2_bitplane_3_read_addr),
    .gfx3_1_read_addr(gfx3_1_read_addr),
    .gfx3_2_read_addr(gfx3_2_read_addr),
    .palette_read_addr(palette_read_addr),
    .scanline(scanline[8:0]),
    .column(column),
    .rgb_r(rgb_r),
    .rgb_b(rgb_b),
    .rgb_g(rgb_g),
    .video_clk(video_clk),
    .rst_b(rst_b),
    .dip(dip));


  soundMUX sound_mux(
    .ac97_sdata_in(ac97_sdata_in),
    .ac97_sdata_out(ac97_sdata_out),
    .ac97_sync(ac97_sync),
    .ac97_reset_b(ac97_reset_b),
    .ac97_bitclk(ac97_bitclk),
    .BROM_sel(soundlatch),
    .rst_b(rst_b)
  );

  // Memory controller
  memory_map mm(
    .up(j_up),
    .down(j_down),
    .left(j_left),
    .right(j_right),
    .fire(j_fire),
    .special(j_special),
    .p1_start(j_p1_start),
    .p2_start(j_p2_start),
    .coin(j_coin),
    .dip(dip),
    .cpu_clk(cpu_clk),
    .video_clk(video_clk),
    .cpu_write(cpu_write),
    .cpu_address(cpu_address),
    .cpu_data_in(cpu_data_in),
    .cpu_data_out(cpu_data_out),
    .fgvideoram_read_data(fgvideoram_read_data),
    .bgvideoram_read_data(bgvideoram_read_data),
    .spriteram_read_data(spriteram_read_data),
    .palette_bank_read_data(palette_bank_read_data),
    .scroll_read_data(scroll_read_data),
    .fgvideoram_read_addr(fgvideoram_read_addr),
    .bgvideoram_read_addr(bgvideoram_read_addr),
    .spriteram_read_addr(spriteram_read_addr),
    .gfx1_read_data(gfx1_read_data),
    .gfx2_bitplane_1_read_data(gfx2_bitplane_1_read_data),
    .gfx2_bitplane_2_read_data(gfx2_bitplane_2_read_data),
    .gfx2_bitplane_3_read_data(gfx2_bitplane_3_read_data),
    .gfx3_1_read_data(gfx3_1_read_data),
    .gfx3_2_read_data(gfx3_2_read_data),
    .palette_read_data(palette_read_data),
    .gfx1_read_addr(gfx1_read_addr),
    .gfx2_bitplane_1_read_addr(gfx2_bitplane_1_read_addr),
    .gfx2_bitplane_2_read_addr(gfx2_bitplane_2_read_addr),
    .gfx2_bitplane_3_read_addr(gfx2_bitplane_3_read_addr),
    .gfx3_1_read_addr(gfx3_1_read_addr),
    .gfx3_2_read_addr(gfx3_2_read_addr),
    .palette_read_addr(palette_read_addr),
    .rst_b(rst_b),
   .soundlatch(soundlatch));


    //-------------- CPU -----------------
    reg  int_n;
    wire wait_n, nmi_n, busrq_n;
    wire m1_n,  iorq_n;

    wire cpu_write_b; //0 to enable;

    assign cpu_write = ~cpu_write_b;

    /// FOR TESTING
    assign wait_n  = 1'b1;
    assign busrq_n = 1'b1;
    assign nmi_n   = 1'b1;

    reg [7:0] cpu_data_out_with_interrupt;

    tv80s tv80(
      // Outputs
      .m1_n(m1_n),
//      .mreq_n(mreq_n),
      .iorq_n(iorq_n),
//      .rd_n(cpu_read_b),
      .wr_n(cpu_write_b),
//      .rfsh_n(rfsh_n),
//      .halt_n(halt_n),
//      .busak_n(busak_n),
      .A(cpu_address),
      .dout(cpu_data_in),

      // Inputs
      .reset_n(rst_b),
      .clk(~cpu_clk),
      .wait_n(wait_n),
      .int_n(int_n),
      .nmi_n(nmi_n),
      .busrq_n(busrq_n),
      .di(cpu_data_out_with_interrupt)
    );

  /* SCANLINE INTERRUPT */
  // scanline interrupt code
  // jump to 0010h once per frame
  reg sending_interrupt, sound_sending_interrupt, scanline_sending_interrupt;
  reg sound_interrupt_received, scanline_interrupt_received;
  wire [9:0] scanline_sync;
  synchronizer #(10) s_scanline(cpu_clk, rst_b, scanline, scanline_sync);

  always @(posedge cpu_clk or negedge rst_b) begin
    if (~rst_b) begin
      int_n <= 1'b1;
    end else if (sending_interrupt) begin
      int_n <= 1'b0;
    end else begin
      int_n <= 1'b1;
    end
  end

  always @(*) sending_interrupt = scanline_sending_interrupt | sound_sending_interrupt;

  always @(posedge cpu_clk or negedge rst_b) begin
    if (~rst_b) begin
      sound_sending_interrupt    <= 0;
      scanline_sending_interrupt <= 0;
    end else if (scanline_sync == 10'd479 && scanline_interrupt_received == 0) begin
      scanline_sending_interrupt <= 1;
   end else if (scanline_sync == 10'd240 && sound_interrupt_received == 0) begin
     sound_sending_interrupt    <= 1;
   end else if (scanline_sync == 10'd242 || (sound_sending_interrupt && m1_n == 0 && iorq_n == 0)) begin
      sound_sending_interrupt    <= 0;
    end else if (scanline_sync == 10'd481 || (scanline_sending_interrupt && m1_n == 0 && iorq_n == 0)) begin
      scanline_sending_interrupt <= 0;
    end
  end

  always @(posedge cpu_clk or negedge rst_b) begin
    if (~rst_b) begin
      scanline_interrupt_received <= 0;
    end else if (scanline_sync == 10'd481) begin
      scanline_interrupt_received <= 0;
    end else if (scanline_sending_interrupt && m1_n == 0 && iorq_n == 0) begin
      scanline_interrupt_received <= 1;
    end
  end
  
  always @(posedge cpu_clk or negedge rst_b) begin
    if (~rst_b) begin
      sound_interrupt_received <= 0;
    end else if (scanline_sync == 10'd242) begin
      sound_interrupt_received <= 0;
    end else if (sound_sending_interrupt && m1_n == 0 && iorq_n == 0) begin
      sound_interrupt_received <= 1;
    end
  end

  // Should be latching
  always @(*) begin
    if (m1_n == 0 && iorq_n == 0) begin
      if (scanline_sending_interrupt)
        cpu_data_out_with_interrupt = 8'hd7;
      else if (sound_sending_interrupt)
        cpu_data_out_with_interrupt = 8'hcf;
    end else begin
      cpu_data_out_with_interrupt = cpu_data_out;
    end
  end

/* SIMULATION SCANLINES *

    initial begin
      video_clk = 0;
      scanline = 9'd0;
      column = 10'd0;
      rst_b = 1;
      #1 rst_b = 0;
      #1 rst_b = 1;
    end

    always #1 video_clk = ~video_clk;

    always @(posedge video_clk) begin

      if (column == 640) begin
        column <= 0;
       if (scanline == 480) begin
         scanline <= 0;
        end
       else begin
         scanline <= scanline+1;
       end
      end
      else begin
        column <= column+1;
      end
    end

*/
endmodule
