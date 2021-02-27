`timescale 1 ns/10 ps
module top_tb();
  reg clk_20_mhz;
  wire PIN_1, PIN_2, PIN_3, PIN_4, PIN_5, PIN_6, PIN_7, PIN_8, PIN_9;
  wire PIN_10, PIN_11, PIN_12, PIN_13, PIN_14, PIN_15, PIN_16, PIN_17, PIN_18;
  wire PIN_19, PIN_20, PIN_21, PIN_22, PIN_23, PIN_24, USBPU;

  localparam  period = 25;
  localparam  dump_file = "top_tb.vcd";
  localparam  simulation_frames = 10.0;
  localparam  simulation_fps = 60.0;
  localparam  simulation_duration_sec = simulation_frames / simulation_fps;
  localparam  pll_clk_mhz = 20;
  localparam  total_clock_cycles = 1000000000.0 / ( 2.0 * period) * simulation_duration_sec;
  localparam  out_file_path = "vga_frames.txt";
  localparam  empty_symbol = ".";
  localparam  full_symbol = "*";
  localparam  sync_symbol = " ";

  integer out_file;
  integer frame_counter;



  vga_adapter UUT(
    .address({PIN_1, PIN_2, PIN_3, PIN_4, PIN_5, PIN_6, PIN_7, PIN_8, PIN_9, PIN_10, PIN_11}),
    .char_input({PIN_12, PIN_13, PIN_14, PIN_15, PIN_16, PIN_17, PIN_18}),
    .write_enable(PIN_19),
    .clk_20_mhz(clk_20_mhz),
    .red(PIN_20),
    .green(PIN_21),
    .blue(PIN_22),
    .horizontal_sync(PIN_23),
    .vertical_sync(PIN_24)
  );

  initial begin
    $dumpfile(dump_file);
    $dumpvars(2, UUT);
    out_file = $fopen(out_file_path);
    frame_counter = 0;
  end

  initial begin
    clk_20_mhz = 1'b0;
  end

  always begin
    #period
    clk_20_mhz = !clk_20_mhz;
  end

  initial begin
    repeat (total_clock_cycles) @(posedge clk_20_mhz);

    $fclose(out_file);
    $finish;
  end

  always @ (posedge clk_20_mhz) begin
    if (!(UUT.horizontal_sync | UUT.vertical_sync)) begin
      if(UUT.red | UUT.green) begin
        $fwrite(out_file, full_symbol);
      end else if(UUT.blue) begin
        $fwrite(out_file, empty_symbol);
      end else begin
        $fwrite(out_file, sync_symbol);
      end
    end
  end

  always @ (posedge UUT.horizontal_sync) begin
    if(!UUT.vertical_sync) begin
      $fwrite(out_file, "\n");
    end
  end

  always @ (posedge UUT.vertical_sync) begin
    $fwrite(out_file, "\n--Frame %d--\n", frame_counter);
    frame_counter = frame_counter + 1;
  end


endmodule
