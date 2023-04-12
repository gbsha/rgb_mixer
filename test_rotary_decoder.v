// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none
`include "led_display.v"
`include "utility_modules.v"


// Project entry point
module top (
    input  CLK,
    input  BTN_N, P1B7, P1B8,
    output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
);
    // 
    wire A = P1B7;
    wire B = P1B8;
    wire A_debounced;
    wire B_debounced;

    // binary coded decimal counter
    wire [7:0] display_value_inc;
    wire [7:0] display_value_dec;
    wire increment;
    wire decrement;
    
    // 7 segment control line bus
    wire [7:0] seven_segment;

    // Assign 7 segment control line bus to Pmod pins
    assign { P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 } = seven_segment;

    // Display value register and increment bus
    reg [7:0] display_value = 0;

    reg [31:0] CLKBANK = 0;

    // Clock divider
    always @(posedge CLK) begin
        CLKBANK <= CLKBANK + 1;
    end

    // 
    debouncer debounce_A(
        .CLK(CLKBANK[10]),
        .signal_in(A),
        .signal_out(A_debounced)
    );
    debouncer debounce_B(
        .CLK(CLKBANK[10]),
        .signal_in(B),
        .signal_out(B_debounced)
    );

    always @(posedge CLKBANK[10]) begin
        if (increment)
            display_value = display_value_inc;
        if (decrement)
            display_value = display_value_dec;
    end 

    bcd8_saturated_counter #('h10) counter(
        .value(display_value),
        .increment(display_value_inc),
        .decrement(display_value_dec)
    );

    // 7 segment display control Pmod 1A
    seven_seg_ctrl seven_segment_ctrl (
        .CLK(CLK),
        .din(display_value[7:0]),
        .dout(seven_segment)
    );

    rotary_decoder rot_decoder(
        .CLK(CLKBANK[10]),
        .A(A_debounced),
        .B(B_debounced),
        .increment(increment),
        .decrement(decrement),
    );

endmodule