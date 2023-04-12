// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

`include "led_display.v" // provides LED display driver seven_seg_ctrl
`include "utility_modules.v" // provides debouncer for reading input pins.

// Project entry point
module top (
    input  CLK,
    input  BTN_N, BTN1,
    output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
);
    // Clock divider
    // CLKBANK[i + 1] provides a clock that is twice as fast as CLKBANK[i] 
    reg [31:0] CLKBANK = 0;

    always @(posedge CLK) begin
        CLKBANK <= CLKBANK + 1;
    end

    // Debounce BTN1
    wire BTN1_debounced;

    debouncer debouncer_BTN1(
        .CLK(CLKBANK[10]),
        .signal_in(BTN1),
        .signal_out(BTN1_debounced)
    );

    // LED display
    wire [7:0] seven_segment;
    assign { P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 } = seven_segment;
    reg [7:0] display_value = 0;

    seven_seg_ctrl seven_segment_ctrl (
        .CLK(CLK),
        .din(display_value[7:0]),
        .dout(seven_segment)
    );

    // Whenever BTN1 is pressed, increment a value and display it on the LED display
    // NB: this works for value with 3 or less bits, since the carry over to the
    // most significant decimal is not taken care of. 
    reg [1:0] value = 0;

    always @(posedge BTN1_debounced) begin
        value = value + 1;
        display_value[1:0] = value;
    end

endmodule
