// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    input PIN_1,  // begin address
    input PIN_2,
    input PIN_3,
    input PIN_4,
    input PIN_5,
    input PIN_6,
    input PIN_7,
    input PIN_8,
    input PIN_9,
    input PIN_10,
    input PIN_11,  // end address
    input PIN_12,  // begin char input
    input PIN_13,
    input PIN_14,
    input PIN_15,
    input PIN_16,
    input PIN_17,
    input PIN_18,  // end char input
    input PIN_19,  // write enable
    output PIN_20, // red
    output PIN_21, // green
    output PIN_22, // blue
    output PIN_23, // horizontal sync
    output PIN_24, // vertical sync
    output USBPU,  // USB pull-up resistor
    output LED     // TinyFPGA BX LED
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    // drive LED to 0 to turn it off
    assign LED = 0;

    wire clk_20_mhz;
    wire locked; //this is an unused output from CLK

    pll PLL_CLK(.clock_in(CLK), .clock_out(clk_20_mhz), .locked(locked));

    vga_adapter vga(
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

endmodule
