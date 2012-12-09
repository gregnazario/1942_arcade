/* AC97 support
 *
 * Specifications:
 *   http://download.intel.com/support/motherboards/desktop/sb/ac97_r23.pdf
 *   http://www.xilinx.com/products/boards/ml505/datasheets/87560554AD1981B_c.pdf
 */
 
module soundMUX
(//ac97_sdata_in, ac97_sdata_out, ac97_sync, ac97_reset_b, ac97_bitclk, BROM_sel, rst_b);
  input  wire ac97_sdata_in, ac97_bitclk,
  input  wire rst_b,
  input  wire [7:0] BROM_sel,
  output ac97_sdata_out, ac97_sync, ac97_reset_b
);

  wire [15:0] sound_00_data, sound_01_data,
              sound_02_data, sound_03_data,
              sound_04_data, sound_05_data,
              sound_06_data, sound_07_data,
              sound_08_data, sound_09_data,
              sound_0A_data, sound_1B_data;
  wire [23:0] BROM_addr;
  reg  [15:0] sound_data;
  wire        finished;
  reg         change_sound;
  reg         force_change_sound;
      
  wire [7:0]  sound_code;

  reg [7:0] BROM_sel_latched;
  reg [7:0] BROM_sel_current;

  always @(posedge ac97_bitclk or negedge rst_b) begin
    if (~rst_b)
      BROM_sel_latched <= 8'd0;
    else begin
      BROM_sel_latched <= BROM_sel;
    end
  end
      
  always @(posedge ac97_bitclk or negedge rst_b) begin
    if (~rst_b)
      BROM_sel_current <= 8'd0;
    else if (change_sound) begin
      BROM_sel_current <= BROM_sel_latched;
   end
  end

  always @(*) begin
   if (force_change_sound)
     change_sound <= 1'b1;
   else
     change_sound <= finished;
  end

  always @(*) begin
    force_change_sound = 1'b0;
    if (BROM_sel_current != BROM_sel_latched) begin
      case (BROM_sel_latched)
        8'h02:        force_change_sound = 1'b1;
        8'h04, 8'h05: force_change_sound = 1'b0;
        8'h06:        force_change_sound = 1'b1;
        8'h07:        force_change_sound = 1'b1;
		  8'h08:        force_change_sound = 1'b1;
        default:      force_change_sound = 1'b0;
      endcase
    end
  end
  
  assign sound_code = BROM_sel_current;
  
  AC97 ac97(
    //Inputs
    .ac97_bitclk(ac97_bitclk),
    .ac97_sdata_in(ac97_sdata_in),
    .BROM_data(sound_data),
    .sound_code(sound_code),
    .rst_b(rst_b),

    // Outputs
    .ac97_sdata_out(ac97_sdata_out),
    .ac97_sync(ac97_sync),
    .ac97_reset_b(ac97_reset_b),
    .BROM_a(BROM_addr),
    .finished(finished)
  );

  sound_02_BROM sound_02(
    .clka(ac97_bitclk),      // input  clka
    .addra(BROM_addr[15:0]), // input  [15 : 0] addra
    .douta(sound_02_data)    // output [15 : 0] douta
  );

  sound_04_BROM sound_04(
    .clka(ac97_bitclk),      // input  clka
    .addra(BROM_addr[15:0]), // input  [15 : 0] addra
    .douta(sound_04_data)    // output [15 : 0] douta
  );
  
  sound_06_BROM sound_06(
    .clka(ac97_bitclk),      // input  clka
    .addra(BROM_addr[15:0]), // input  [15 : 0] addra
    .douta(sound_06_data)    // output [15 : 0] douta
  );
  
  sound_07 sound_07_BROM (
    .clka(ac97_bitclk),      // input  clka
    .addra(BROM_addr[12:0]), // input  [12 : 0] addra
    .douta(sound_07_data)    // output [15 : 0] douta
  );
        
  assign sound_00_data = 0;
  assign sound_01_data = 0;
  assign sound_03_data = sound_04_data;
  assign sound_05_data = sound_04_data;
  assign sound_08_data = sound_07_data;
  assign sound_09_data = sound_04_data;
  assign sound_0A_data = sound_07_data;
  assign sound_1B_data = sound_07_data;
  
  always @(posedge ac97_bitclk or negedge rst_b) begin
    if (~rst_b) begin
      sound_data <= 'd0;
    end else begin
        case (BROM_sel_current)
        8'h00:        sound_data <= sound_00_data;
        8'h01:        sound_data <= sound_01_data;
        8'h02:        sound_data <= sound_02_data;
        8'h03:        sound_data <= sound_03_data;
        8'h04:        sound_data <= sound_04_data;
        8'h05:        sound_data <= sound_05_data;
        8'h06:        sound_data <= sound_06_data;
        8'h07:        sound_data <= sound_07_data;
        8'h08:        sound_data <= sound_08_data;
        8'h09:        sound_data <= sound_09_data;
        8'h0A:        sound_data <= sound_0A_data;
		  8'h1B:        sound_data <= sound_1B_data;
        default:      sound_data <= 'd0;
      endcase
    end
  end

endmodule

module AC97(
  // Inputs
  input  wire        ac97_bitclk,
  input  wire        ac97_sdata_in,
  input  wire [15:0] BROM_data,
  input  wire [7:0]  sound_code,
  input  wire        rst_b,
  
  // Outputs
  output wire        ac97_sdata_out,
  output wire        ac97_sync,
  output wire        ac97_reset_b,
  output wire [23:0] BROM_a,
  output wire        finished
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
    .finished      (finished),
    .sound_code    (sound_code),
    .rst_b         (rst_b),

    // Inputs
    .ac97_bitclk   (ac97_bitclk),
    .ac97_strobe   (ac97_strobe),
    .BROM_data     (BROM_data[15:0])
  );
   
  ACLink link(
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
    .ac97_out_slot12_valid(ac97_out_slot12_valid)
  );

  AC97Conf conf(
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
  input  wire [7:0]  sound_code,
  input  wire        rst_b,
  output wire [19:0] ac97_out_slot3,
  output wire [19:0] ac97_out_slot4,
  output reg  [23:0] BROM_a,
  output reg         finished
  );

  reg [23:0] count       = 'h0;
  reg [15:0] curr_sample = 'h0;
  reg [15:0] next_sample = 'h0;

  // Counter counts to 247968 and then goes back to 0
  // 247968 is the number of samples read in from the BROM
  always @(posedge ac97_bitclk or negedge rst_b) begin
    if (~rst_b) begin
      count       <= 'd0;
      finished    <= 'd0;
      BROM_a      <= 'd0;
      curr_sample <= 'd0;
    end else if (ac97_strobe) begin
      case (sound_code)
        8'h02:        
        begin
          if (count >= 'd51200) begin
            count    <= 'h0;
            finished <= 1'b1;
          end else begin
            count    <= count + 1;
            finished <= 0;
          end
        end

        8'h04, 8'h05, 8'h09: 
        begin
          if (count >= 'd9728) begin
            count    <= 'h0;
            finished <= 1'b1;
          end else begin
            count    <= count + 1;
            finished <= 0;
          end
        end

        8'h06: 
        begin
          if (count >= 'd55040) begin
            count    <= 'h0;
            finished <= 1'b1;
          end else begin
            count    <= count + 1;
            finished <= 0;
          end
        end

        8'h07, 8'h08, 8'h0A, 8'h1B: 
        begin
          if(count >= 'd8192) begin
            count <= 'h0;
            finished <= 1'b1;
          end else begin
            count <= count + 1;
            finished <= 0;
          end
        end

        default:      
        begin
          count    <= 'h0;
          finished <= 1;
        end
      endcase
      BROM_a      <= count;
      curr_sample <= next_sample;
    end else begin
      next_sample <= BROM_data;
    end
  end

  assign ac97_out_slot3 = {curr_sample[15:8],curr_sample[7:0],4'h0};
  assign ac97_out_slot4 = ac97_out_slot3;
  
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
  
  assign ac97_reset_b = 1;
  
  // We may want to make this into a state machine eventually.
  reg [7:0]   curbit = 8'h0;  // Contains the bit currently on the bus.
  
  
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
   if (~rst_b)
     curbit <= 'd0;
   else
     curbit <= curbit + 1;
  end
  
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
