/* AC97 support
 *
 * Specifications:
 *   http://download.intel.com/support/motherboards/desktop/sb/ac97_r23.pdf
 *   http://www.xilinx.com/products/boards/ml505/datasheets/87560554AD1981B_c.pdf
 */
 
module soundMUX(ac97_sdata_in, ac97_sdata_out, ac97_sync, ac97_reset_b,
ac97_bitclk, BROM_sel, rst_b, play_music, sound_code, playing_music, resetting);
        input  wire ac97_sdata_in, ac97_bitclk;
        output ac97_sdata_out, ac97_sync, ac97_reset_b;
        input [7:0] BROM_sel;
        input rst_b;
        input play_music;
		  input wire [2:0] sound_code;
		  output wire playing_music;
		  output wire resetting;

        wire [23:0] BROM_addr;
        reg [15:0] sound_data;

        assign resetting = ~rst_b;
		  assign playing_music = play_music;
        
        AC97 ac97(
                //Inputs
                .ac97_bitclk(ac97_bitclk),
                .ac97_sdata_in(ac97_sdata_in),
                .BROM_data(sound_data),
                .rst_b(rst_b),
					 .sound_code(sound_code),
                // Outputs
                .ac97_sdata_out(ac97_sdata_out),
                .ac97_sync(ac97_sync),
                .ac97_reset_b(ac97_reset_b),
                .BROM_a(BROM_addr),
                .play_music((playing_music & rst_b) ? 1'b1 : 1'b0)
        );

      wire [15:0] sound_0D_data, sound_11_data, sound_12_data, sound_16_data, sound_0E_data;

      always @(*) begin
		  case (sound_code)
		    3'd0:    sound_data = sound_11_data; //background
			 3'd1:    sound_data = sound_0D_data; //takeoff
			 3'd2:    sound_data = sound_0E_data; //landing
			 3'd3:    sound_data = sound_12_data;//after death
			 3'd4:    sound_data = sound_16_data;// complete death
			 default: sound_data = 0;
		  endcase
		end

      //assign sound_12_data = 0;
		assign sound_16_data = 0;
		assign sound_0E_data = 0;


      sound_11_brom s_11 (
        .clka(ac97_bitclk), // input clka
        .addra(BROM_addr[17:0]), // input [17 : 0] addra
        .douta(sound_11_data) // output [15 : 0] douta
      );
		
		sound_0D_brom s_0D (
        .clka(ac97_bitclk), // input clka
        .addra(BROM_addr[15:0]), // input [15 : 0] addra
        .douta(sound_0D_data) // output [15 : 0] douta
      );
		
		/*sound_16_brom s_16 (
        .clka(ac97_bitclk), // input clka
        .addra(BROM_addr[17:0]), // input [17 : 0] addra
        .douta(sound_16_data) // output [15 : 0] douta
		);*/
		
		
		sound_12_brom s_12 (
		  .clka(ac97_bitclk), // input clka
		  .addra(BROM_addr[16:0]), // input [16 : 0] addra
		  .douta(sound_12_data) // output [15 : 0] douta
		);


endmodule

module AC97(
  // Inputs
  input  wire        ac97_bitclk,
  input  wire        ac97_sdata_in,
  input  wire [15:0] BROM_data,
  input  wire [2:0]  sound_code,
  input  wire        rst_b,
  
  // Outputs
  output wire        ac97_sdata_out,
  output wire        ac97_sync,
  output wire        ac97_reset_b,
  output wire [23:0] BROM_a,
//  output wire        BROM_clk,
//  output wire        finished,
  input wire play_music
  );

  wire        ac97_strobe;           // From link of ACLink.v
   
  wire        ac97_out_slot1_valid;  // From conf of AC97Conf.v
  wire        ac97_out_slot2_valid;  // From conf of AC97Conf.v
  wire        ac97_out_slot3_valid  = 1;
  wire        ac97_out_slot4_valid  = 1;
  wire        ac97_out_slot5_valid  = 0;
  wire        ac97_out_slot6_valid  = 0;
  wire        ac97_out_slot7_valid  = 0;
  wire        ac97_out_slot8_valid  = 0;
  wire        ac97_out_slot9_valid  = 0;
  wire        ac97_out_slot10_valid = 0;
  wire        ac97_out_slot11_valid = 0;
  wire        ac97_out_slot12_valid = 0;
   
  wire [19:0] ac97_out_slot1;    // From conf of AC97Conf.v
  wire [19:0] ac97_out_slot2;    // From conf of AC97Conf.v
  wire [19:0] ac97_out_slot3;    // From source of AudioGen.v
  wire [19:0] ac97_out_slot4;    // From source of AudioGen.v
  wire [19:0] ac97_out_slot5  = 'h0;
  wire [19:0] ac97_out_slot6  = 'h0;
  wire [19:0] ac97_out_slot7  = 'h0;
  wire [19:0] ac97_out_slot8  = 'h0;
  wire [19:0] ac97_out_slot9  = 'h0;
  wire [19:0] ac97_out_slot10 = 'h0;
  wire [19:0] ac97_out_slot11 = 'h0;
  wire [19:0] ac97_out_slot12 = 'h0;

  AudioGen source(
      // Outputs
      .ac97_out_slot3(ac97_out_slot3[19:0]),
      .ac97_out_slot4(ac97_out_slot4[19:0]),
      .BROM_a        (BROM_a[23:0]),

//      .finished      (finished),
      .sound_code    (sound_code),
      .rst_b         (rst_b),
      // Inputs
      .ac97_bitclk   (ac97_bitclk),
      .ac97_strobe   (ac97_strobe),
      .BROM_data     (BROM_data[15:0]),
      .play_music    (play_music));
   
  /*
  wire button;
  assign button = 1;
  wire [7:0] switches;
  assign switches = 0;  
  
  SquareWave source(
    .ac97_bitclk(ac97_bitclk),
    .ac97_strobe(ac97_strobe),
    .sample(ac97_out_slot3),
    .song(button),
   .select(switches)
  );
*/
  //assign ac97_out_slot4 = 'h0;
  
  ACLink link(
    /*AUTOINST*/
        // Outputs
        .ac97_sdata_out  (ac97_sdata_out),
        .ac97_sync       (ac97_sync),
        .ac97_reset_b    (ac97_reset_b),
        .ac97_strobe     (ac97_strobe),
        .rst_b(rst_b),

        // Inputs
        .ac97_bitclk     (ac97_bitclk),
        .ac97_sdata_in   (ac97_sdata_in),

        .ac97_out_slot1  (ac97_out_slot1[19:0]),
        .ac97_out_slot2  (ac97_out_slot2[19:0]),
        .ac97_out_slot3  (ac97_out_slot3[19:0]),
        .ac97_out_slot4  (ac97_out_slot4[19:0]),
        .ac97_out_slot5  (ac97_out_slot5[19:0]),
        .ac97_out_slot6  (ac97_out_slot6[19:0]),
        .ac97_out_slot7  (ac97_out_slot7[19:0]),
        .ac97_out_slot8  (ac97_out_slot8[19:0]),
        .ac97_out_slot9  (ac97_out_slot9[19:0]),
        .ac97_out_slot10 (ac97_out_slot10[19:0]),
        .ac97_out_slot11 (ac97_out_slot11[19:0]),
        .ac97_out_slot12 (ac97_out_slot12[19:0]),

        .ac97_out_slot1_valid (ac97_out_slot1_valid),
        .ac97_out_slot2_valid (ac97_out_slot2_valid),
        .ac97_out_slot3_valid (ac97_out_slot3_valid),
        .ac97_out_slot4_valid (ac97_out_slot4_valid),
        .ac97_out_slot5_valid (ac97_out_slot5_valid),
        .ac97_out_slot6_valid (ac97_out_slot6_valid),
        .ac97_out_slot7_valid (ac97_out_slot7_valid),
        .ac97_out_slot8_valid (ac97_out_slot8_valid),
        .ac97_out_slot9_valid (ac97_out_slot9_valid),
        .ac97_out_slot10_valid(ac97_out_slot10_valid),
        .ac97_out_slot11_valid(ac97_out_slot11_valid),
        .ac97_out_slot12_valid(ac97_out_slot12_valid));

  AC97Conf conf(/*AUTOINST*/
          // Outputs
          .ac97_out_slot1  (ac97_out_slot1[19:0]),
          .ac97_out_slot2  (ac97_out_slot2[19:0]),

          .ac97_out_slot1_valid(ac97_out_slot1_valid),
          .ac97_out_slot2_valid(ac97_out_slot2_valid),

          // Inputs
          .ac97_bitclk  (ac97_bitclk),
          .ac97_strobe  (ac97_strobe),
          .rst_b        (rst_b)
       );
endmodule



module AudioGen(
  input  wire        ac97_bitclk,
  input  wire        ac97_strobe,
  input  wire [15:0] BROM_data,
  input  wire [2:0]  sound_code,
  input  wire        rst_b,
  output wire [19:0] ac97_out_slot3,
  output wire [19:0] ac97_out_slot4,
  output reg  [23:0] BROM_a,
//  output reg         finished,
  input  wire        play_music
  );

  // Constants?

  reg [23:0] count  = 'h0;

  reg [15:0] curr_sample = 'h0;
  reg [15:0] next_sample = 'h0;

  // Counter counts to 247968 and then goes back to 0
  // 247968 is the number of samples read in from the BROM
  always @(posedge ac97_bitclk or negedge rst_b) begin
    if (~rst_b) begin
      count       <= 'd0;
      BROM_a      <= 'd0;
      curr_sample <= 'd0;
    end else if (ac97_strobe) begin
      if (play_music) begin
		  case (sound_code)
			  3'd0: begin
				  if (count >= ('d147200 << 2)) begin
					 count <= 'd0;
				  end else begin
					 count <= count + 'd1;
				  end
				end
			  3'd1: begin
				  if (count >= ('d39427 << 2)) begin
					 count <= 'd0;
				  end else begin
					 count <= count + 'd1;
				  end
			  end
			  /*3'd2: begin
				  if (count >= ('d39427 << 2)) begin
					 count <= 'd0;
				  end else begin
					 count <= count + 'd1;
				  end
			  end*/
			  3'd3: begin
				  if (count >= ('d121606 << 2)) begin
					 count <= 'd0;
				  end else begin
					 count <= count + 'd1;
				  end
			  end
			  3'd2, 3'd4: begin
				  /*if (count >= ('d39427 << 2)) begin
					 count <= 'd0;
				  end else begin
					 count <= count + 'd1;
				  end*/
				  count <= 'd0;
			  end
		  endcase	  
		  BROM_a      <= {2'd0, count[23:2]};
		  curr_sample <= next_sample;
		end else begin
        //next_sample <= 'd0;
        curr_sample <= 'd0;
        count       <= 'd0;
        BROM_a      <= 'd0;
      end
    end else begin
      next_sample <= BROM_data;
    end
  end

  assign ac97_out_slot3 = {curr_sample[15:8],curr_sample[7:0],4'h0};
  assign ac97_out_slot4 = ac97_out_slot3;
  //assign ac97_out_slot4 = {curr_sample[23:16],curr_sample[31:24],4'h0};
  
endmodule


// Creates a square wave that changes every 8 bitclk cycles where the strobe
// is active
module SquareWave(
  input  wire        ac97_bitclk,
  input  wire        ac97_strobe,
  input  wire        song,
  input  wire [7:0]  select,
  output wire [19:0] sample
  );

  reg [3:0] count = 4'b0;
  reg divider = 'h1;
  reg [9:0] div_count = 'h0;
/*  always @(posedge ac97_bitclk) begin
    if (ac97_strobe) begin
      divider <= ~divider;
      if (song) 
        count <= count + divider;
      else
        count <= count + 1;
    end
  end*/
  
  always @(posedge ac97_bitclk) begin
    if (ac97_strobe) begin
    if (div_count > select) begin
      divider <= 'h1;
      
      if (div_count > (div_count << 'h2))
        div_count <= 'h0;
      else
        div_count <= div_count + 'h1;
    end
    else begin
      divider <= 'h0;
      div_count <= div_count + 'h1;
    end
    
      if (song) 
        count <= count + divider;
      else
        count <= count + 1;
    end
  end
  
  assign sample = (count[3] ? 20'h80000 : 20'h7ffff);
endmodule

/* Timing diagrams for ACLink:
 *   http://nyus.joshuawise.com/ac97-clocking.scale.jpg
 */
module ACLink(
  input  wire  ac97_bitclk,
  input  wire  ac97_sdata_in,
  input  wire  rst_b,
  
  output wire  ac97_sdata_out,
  output wire  ac97_sync,
  output wire  ac97_reset_b,
  
  output wire  ac97_strobe,
  
  input wire [19:0] ac97_out_slot1,
  input wire [19:0] ac97_out_slot2,
  input wire [19:0] ac97_out_slot3,
  input wire [19:0] ac97_out_slot4,
  input wire [19:0] ac97_out_slot5,
  input wire [19:0] ac97_out_slot6,
  input wire [19:0] ac97_out_slot7,
  input wire [19:0] ac97_out_slot8,
  input wire [19:0] ac97_out_slot9,
  input wire [19:0] ac97_out_slot10,
  input wire [19:0] ac97_out_slot11,
  input wire [19:0] ac97_out_slot12,
  input wire        ac97_out_slot1_valid,
  input wire        ac97_out_slot2_valid,
  input wire        ac97_out_slot3_valid,
  input wire        ac97_out_slot4_valid,
  input wire        ac97_out_slot5_valid,
  input wire        ac97_out_slot6_valid,
  input wire        ac97_out_slot7_valid,
  input wire        ac97_out_slot8_valid,
  input wire        ac97_out_slot9_valid,
  input wire        ac97_out_slot10_valid,
  input wire        ac97_out_slot11_valid,
  input wire        ac97_out_slot12_valid
  );
  
  assign ac97_reset_b = rst_b;
  
  // We may want to make this into a state machine eventually.
  reg [7:0]   curbit = 8'h0;  // Contains the bit currently on the bus.
  
//  reg [255:0] inbits = 256'h0;
  //reg [255:0] latched_inbits;
  
  /* Spec says: rising edge should be in the middle of the final bit of
   * the last slot, and the falling edge should be in the middle of
   * the final bit of the TAG slot.
   */
  assign ac97_sync = (curbit == 255) || (curbit < 15); 
  
  /* The outside world is permitted to read our latched data on the
   * rising edge after bit 0 is transmitted.  Bit FF will have been
   * latched on its falling edge, which means that on the rising edge
   * that still contains bit FF, the "us to outside world" flipflops
   * will have been triggered.  Given that, by the rising edge that
   * contains bit 0, those flip-flops will have data.  So, the outside
   * world strobe will be high on the rising edge that contains bit 0.
   *
   * Additionally, this strobe controls when the outside world will
   * strobe new data into us.  The rising edge will latch new data
   * into our inputs.  This data, in theory, will show up in time for
   * the falling edge of the bit clock for big 01.
   *
   * NOTE: We need UCF timing constraints with setup times to make
   * sure this happens!
   */   
  assign ac97_strobe = (curbit == 8'h00);
  
  /* The internal strobe for the output flip-flops needs to happen on
   * the rising edge that still contains bit FF.
   */
  always @(posedge ac97_bitclk or negedge rst_b) begin
   // if (curbit == 8'hFF) begin
   //   latched_inbits <= inbits;
   // end
   if (~rst_b)
     curbit <= 'd0;
   else
      curbit <= curbit + 1;
  end
  
/*  always @(negedge ac97_bitclk or negedge rst_b) begin
    if (~rst_b) inbits <= 'd0;
   else        inbits[curbit] <= ac97_sdata_in;
  end
*/  
  /* Bit order is reversed; msb of tag sent first. */
  wire [0:255] outbits = { /* TAG */
                           1'b1,
                           ac97_out_slot1_valid,
                           ac97_out_slot2_valid,
                           ac97_out_slot3_valid,
                           ac97_out_slot4_valid,
                           ac97_out_slot5_valid,
                           ac97_out_slot6_valid,
                           ac97_out_slot7_valid,
                           ac97_out_slot8_valid,
                           ac97_out_slot9_valid,
                           ac97_out_slot10_valid,
                           ac97_out_slot11_valid,
                           ac97_out_slot12_valid,
                           3'b000,
                           /* and then time slots */
                           ac97_out_slot1_valid  ? ac97_out_slot1  : 20'h0,
                           ac97_out_slot2_valid  ? ac97_out_slot2  : 20'h0,
                           ac97_out_slot3_valid  ? ac97_out_slot3  : 20'h0,
                           ac97_out_slot4_valid  ? ac97_out_slot4  : 20'h0,
                           ac97_out_slot5_valid  ? ac97_out_slot5  : 20'h0,
                           ac97_out_slot6_valid  ? ac97_out_slot6  : 20'h0,
                           ac97_out_slot7_valid  ? ac97_out_slot7  : 20'h0,
                           ac97_out_slot8_valid  ? ac97_out_slot8  : 20'h0,
                           ac97_out_slot9_valid  ? ac97_out_slot9  : 20'h0,
                           ac97_out_slot10_valid ? ac97_out_slot10 : 20'h0,
                           ac97_out_slot11_valid ? ac97_out_slot11 : 20'h0,
                           ac97_out_slot12_valid ? ac97_out_slot12 : 20'h0
                           };
  
  /* Spec says: should transition shortly after the rising edge.  In
   * the end, we probably want to flop this to guarantee that (or set
   * up UCF constraints as mentioned above).
   */
  assign ac97_sdata_out = outbits[curbit];

/*  wire [35:0] cs_control0;

  chipscope_icon icon0(
    .CONTROL0(cs_control0) // INOUT BUS [35:0]
  );
  
  chipscope_ila ila0 (
    .CONTROL(cs_control0), // INOUT BUS [35:0]
    .CLK(ac97_bitclk), // IN
    .TRIG0({'b0, ac97_sdata_out, inbits[curbit], ac97_sync, curbit[7:0]}) // IN BUS [255:0]
  );
*/
endmodule

module AC97Conf(
  input  wire        ac97_bitclk,
  input  wire        ac97_strobe,
  input  wire        rst_b,
  output wire [19:0] ac97_out_slot1,
  output wire [19:0] ac97_out_slot2,
  output wire        ac97_out_slot1_valid,
  output wire        ac97_out_slot2_valid
  );
  
  reg        ac97_out_slot1_valid_r;
  reg        ac97_out_slot2_valid_r;
  reg [19:0] ac97_out_slot1_r;
  reg [19:0] ac97_out_slot2_r;
  
  assign ac97_out_slot1 = ac97_out_slot1_r;
  assign ac97_out_slot2 = ac97_out_slot2_r;
  assign ac97_out_slot1_valid = ac97_out_slot1_valid_r;
  assign ac97_out_slot2_valid = ac97_out_slot2_valid_r;

  reg [3:0] state     = 4'h0;
  reg [3:0] nextstate = 4'h0;

  always @(*) begin
    ac97_out_slot1_r = 20'hxxxxx;
    ac97_out_slot2_r = 20'hxxxxx;
    ac97_out_slot1_valid_r = 0;
    ac97_out_slot2_valid_r = 0;
    nextstate = state;
    case (state)
    4'h0: begin
      ac97_out_slot1_r = {1'b0 /* write */, 7'h00 /* reset */, 12'b0 /* reserved */};
      ac97_out_slot2_r = {16'h0, 4'h0};
      ac97_out_slot1_valid_r = 1;
      ac97_out_slot2_valid_r = 1;
      nextstate = 4'h1;
    end
    4'h1: begin
      ac97_out_slot1_r = {1'b0 /* write */, 7'h02 /* master volume */, 12'b0 /* reserved */};
      ac97_out_slot2_r = {16'h0 /* unmuted, full volume */, 4'h0};
      ac97_out_slot1_valid_r = 1;
      ac97_out_slot2_valid_r = 1;
      nextstate = 4'h2;
    end
    4'h2: begin
      ac97_out_slot1_r = {1'b0 /* write */, 7'h18 /* pcm volume */, 12'b0 /* reserved */};
      ac97_out_slot2_r = {16'h0808 /* unmuted, 0dB */, 4'h0};
      ac97_out_slot1_valid_r = 1;
      ac97_out_slot2_valid_r = 1;
      nextstate = 4'h3;
    end
    4'h3: begin
      ac97_out_slot1_r = {1'b1 /* read */, 7'h26 /* power status */, 12'b0 /* reserved */};
      ac97_out_slot2_r = {20'h00000};
      ac97_out_slot1_valid_r = 1;
      ac97_out_slot2_valid_r = 1;
      nextstate = 4'h4;
    end
    4'h4: begin
      ac97_out_slot1_r = {1'b1 /* read */, 7'h7c /* vid0 */, 12'b0 /* reserved */};
      ac97_out_slot2_r = {20'h00000};
      ac97_out_slot1_valid_r = 1;
      ac97_out_slot2_valid_r = 1;
      nextstate = 4'h5;
    end
    4'h5: begin
      ac97_out_slot1_r = {1'b1 /* read */, 7'h7e /* vid1 */, 12'b0 /* reserved */};
      ac97_out_slot2_r = {20'h00000};
      ac97_out_slot1_valid_r = 1;
      ac97_out_slot2_valid_r = 1;
      nextstate = 4'h3;
    end
    endcase
  end
  
  always @(posedge ac97_bitclk or negedge rst_b) begin
    if (~rst_b)           state <= 'd0;
    else if (ac97_strobe) state <= nextstate;
  end
endmodule
