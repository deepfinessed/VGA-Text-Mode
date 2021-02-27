module vga_adapter(
  input [10:0] address,
  input [ 6:0] char_input,
  input        write_enable,
  input        clk_20_mhz,
  output       red,
  output       green,
  output       blue,
  output       horizontal_sync,
  output       vertical_sync
  );

  localparam  GLYPHS_FILE = "char_glyphs.mem";
  localparam BUFFER_INIT_FILE = "init_display_buffer.mem";

  /*
  Numbers taken from here: http://tinyvga.com/vga-timing/800x600@60Hz
  but the horizontal values are all divided by 2 -

  HORIZONTAL:

  Scanline part	 | Pixels	 | Time [µs]
  Visible area	 | 400	   | 20
  Front porch	   | 20	     | 1
  Sync pulse	   | 64 	   | 3.2
  Back porch	   | 44	     | 2.2
  Whole line	   | 528	   | 26.4

  VERTICAL:

  Frame part	   | Lines	 | Time [ms]
  Visible area	 | 600	   | 15.84
  Front porch	   | 1	     | 0.0264
  Sync pulse	   | 4	     | 0.1056
  Back porch	   | 23	     | 0.6072
  Whole frame	   | 628     | 16.5792
  */
  localparam  SCREEN_WIDTH = 400;
  localparam  HORIZONTAL_SYNC_START = 421; // vis. area + front porch
  localparam  HORIZONTAL_SYNC_END = HORIZONTAL_SYNC_START + 64; //add sync pulse
  localparam  LINE_END = 528;
  localparam  VERTICAL_SYNC_START = 600;
  localparam  VERTICAL_SYNC_END = VERTICAL_SYNC_START + 5;
  localparam  FRAME_END = 628;
  localparam  CHAR_WIDTH = 8;

  /*
  We actually want our characters to have a
  height of 10 'pixels', but since we are halving the clock speed, we will
  draw each row twice.

  To do our clock halving, we are going to have a counter that only increment
  half the time. Since we have odd numbers in the timing recommendation above
  we will keep track of the actual pixel counter and our 'adjusted' counter

  We will use our 'adjusted' counter within glyphs and the pixel counter for
  timing related to VGA signals like syncs
  */
  localparam  CHAR_HEIGHT = 10;


  wire clk_20_mhz;

  reg [10:0] horizontal_counter;
  reg        horizontal_sync;
  reg [ 9:0] vertical_pixel_counter;
  reg [ 9:0] vertical_counter;
  reg        vertical_sync;
  reg        red;
  reg        green;
  reg        blue;
  wire       write_enable;

  reg [79:0] char_glyphs   [0:255];
  reg [ 6:0] output_buffer [0:1499];


  initial begin
    horizontal_counter <= 0; //horizontal position on screen
    horizontal_sync <= 0;
    vertical_pixel_counter <= 0; //counts actual screen pixels - is double vertical counter
    vertical_counter <= 0; //counts 'virtual pixels' - each pixel is written twice
    vertical_sync <= 0;
    red <= 0;
    green <= 0;
    blue <= 0;

    $readmemh(GLYPHS_FILE, char_glyphs);
    $readmemh(BUFFER_INIT_FILE, output_buffer);
  end


  reg [10:0] display_index; //index of character to display
  reg [10:0] horizontal_index; //horizontal index within glyph
  reg [10:0] vertical_index; //vertical index within glyph

  wire [10:0] address;
  wire [ 6:0] char_input;
  reg  [ 6:0] output_char_code;


  always @(negedge clk_20_mhz) begin
    output_char_code <= output_buffer[display_index];
    if (write_enable) begin
      output_buffer[address] <= char_input;
    end
  end


  always @(posedge clk_20_mhz) begin
    if(horizontal_counter > HORIZONTAL_SYNC_START && horizontal_counter < HORIZONTAL_SYNC_END) begin
      horizontal_sync <= 1;
    end else begin
      horizontal_sync <= 0;
    end

    if(vertical_pixel_counter > VERTICAL_SYNC_START && vertical_pixel_counter > VERTICAL_SYNC_END) begin
      vertical_sync <= 1;
    end else begin
      vertical_sync <= 0;
    end

    if(horizontal_counter < SCREEN_WIDTH && vertical_pixel_counter < VERTICAL_SYNC_START) begin
      display_index <= (horizontal_counter / CHAR_WIDTH) + ((SCREEN_WIDTH / CHAR_WIDTH) * (vertical_counter / CHAR_HEIGHT));
      horizontal_index <= horizontal_counter % CHAR_WIDTH;
      vertical_index <= vertical_counter % CHAR_HEIGHT;

      // Default pixel color is blue
      red <= 0;
      green <= 0;
      blue <= 1;

      // If it's part of a character, it's white
      if(char_glyphs[output_char_code][horizontal_index + (vertical_index * CHAR_WIDTH)] == 1'b1) begin
        red <= 1;
        green <= 1;
        blue <= 1;
      end
    end else begin
      // Outside display region, output nothing
      red <= 0;
      green <= 0;
      blue <= 0;
    end

    horizontal_counter <= horizontal_counter + 1'b1;

    if(horizontal_counter == LINE_END) begin
      horizontal_counter <= 0;
      if(vertical_pixel_counter[0] == 1'b1) begin
        vertical_counter <= vertical_counter + 1'b1;
      end
      vertical_pixel_counter <= vertical_pixel_counter + 1'b1;
    end

    if(vertical_pixel_counter == FRAME_END) begin
      vertical_pixel_counter <= 0;
      vertical_counter <= 0;
    end
  end


endmodule
