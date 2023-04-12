// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

`include "led_display.v"
`include "utility_modules.v"

// Main module
module top #(parameter MAX_BW = 5,
             parameter MAX_VAL = 5'b1_1111, 
             parameter MAX_CNT = 8'h31)(
    input  CLK,
    input  BTN_N, BTN1, P1B7, P1B8,
    output P1B1, P1B2, P1B3,
    output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10, 
    output LED5, LED3, LED4
);
    // Clock divider
    // CLKBANK[i + 1] provides a clock that is twice as fast as CLKBANK[i] 
    reg [31:0] CLKBANK = 0;

    always @(posedge CLK) begin
        CLKBANK <= CLKBANK + 1;
    end

    reg ON_red = 1;
    reg ON_green = 1;
    reg ON_blue = 1;
    assign P1B1 = ON_red;
    assign P1B2 = ON_green;
    assign P1B3 = ON_blue;

    // Pulse width modulation (PWM) of LEDs
    // in CLKBANK[SLOW:FAST], SLOW should be chosen such that the human eye cannot detect.
    // SLOW = 16 seems a reasonable value.
    // LEDs are active-low, so:
    // value = 0 ==> ON = 1 ==> LED is off
    always @(posedge CLKBANK[16 - MAX_BW + 1]) begin
        ON_red = CLKBANK[16:16 - MAX_BW + 1] >= value_red;
        ON_green = CLKBANK[16:16 - MAX_BW + 1] >= value_green;
        ON_blue = CLKBANK[16:16 - MAX_BW + 1] >= value_blue;
    end
    
    // Color selector BTN1.
    // LED5, 3, 4 indicate which color is selected.
    wire BTN1_debounced;
    reg [2:0] color_selector = 3'b001;
    assign LED5 = color_selector[0];
    assign LED3 = color_selector[1];
    assign LED4 = color_selector[2];

    debouncer debounce_BTN1(
        .CLK(CLKBANK[10]),
        .signal_in(BTN1),
        .signal_out(BTN1_debounced)
    );

    always @(posedge BTN1_debounced) begin
        color_selector = {color_selector[1:0], color_selector[2]};
    end

    // Rotary decoder to detect the increment and decrement signals.
    // increment and decrement are high for 1 clock cycle of the clock
    // provided to rot_decoder, so the logic that consumes increment and decrement
    // should use the same clock.
    wire A = P1B7;
    wire B = P1B8;
    wire A_debounced;
    wire B_debounced;
    wire increment;
    wire decrement;

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

    rotary_decoder rot_decoder(
        .CLK(CLKBANK[10]),
        .A(A_debounced),
        .B(B_debounced),
        .increment(increment),
        .decrement(decrement),
    );

    // LED display, Part 1: binary coded decimal counters.
    // The display shows two decimal digits. To avoid multiplication and division,
    // the values to be displayed are incremented and decremented in specific 8 bit
    // binary coded decimal (bcd) counters 
    reg [7:0] display_value_red = 0;
    wire [7:0] display_value_red_inc;
    wire [7:0] display_value_red_dec;

    reg [7:0] display_value_green = 0;
    wire [7:0] display_value_green_inc;
    wire [7:0] display_value_green_dec;

    reg [7:0] display_value_blue = 0;
    wire [7:0] display_value_blue_inc;
    wire [7:0] display_value_blue_dec;

    bcd8_saturated_counter #(MAX_CNT) counter_red(
        .value(display_value_red),
        .increment(display_value_red_inc),
        .decrement(display_value_red_dec)
    );

    bcd8_saturated_counter #(MAX_CNT) counter_green(
        .value(display_value_green),
        .increment(display_value_green_inc),
        .decrement(display_value_green_dec)
    );

    bcd8_saturated_counter #(MAX_CNT) counter_blue(
        .value(display_value_blue),
        .increment(display_value_blue_inc),
        .decrement(display_value_blue_dec)
    );

    // LED display, Part 2: Driver
    wire [7:0] seven_segment;
    assign { P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 } = seven_segment;
    reg [7:0] display_value = 0;

    seven_seg_ctrl seven_segment_ctrl (
        .CLK(CLK),
        .din(display_value[7:0]),
        .dout(seven_segment)
    );


    // RGB Mixer
    // - consumes color selector
    // - consumes increment, decrement signals
    // - updates PWM levels
    // - updates LED display values
    reg [MAX_BW - 1:0] value_red = 0;
    reg [MAX_BW - 1:0] value_green = 0;
    reg [MAX_BW - 1:0] value_blue = 0;

    always @(posedge CLKBANK[10]) begin
        case (color_selector)
            3'b001: begin
                if (increment) begin
                    display_value_red = display_value_red_inc;
                    value_red = value_red == 5'b1_1111 ? value_red : value_red + 1;
                end
                if (decrement) begin
                    display_value_red = display_value_red_dec;
                    value_red = value_red == 0 ? 0 : value_red - 1;
                end
                display_value = display_value_red;
            end
            3'b010: begin
                if (increment) begin
                    display_value_green = display_value_green_inc;
                    value_green = value_green == 5'b1_1111 ? value_green : value_green + 1;
                end
                if (decrement) begin
                    display_value_green = display_value_green_dec;
                    value_green = value_green == 0 ? 0 : value_green - 1;
                end
                display_value = display_value_green;
            end
            3'b100: begin
                if (increment) begin
                    display_value_blue = display_value_blue_inc;
                    value_blue = value_blue == 5'b1_1111 ? value_blue : value_blue + 1;
                end
                if (decrement) begin
                    display_value_blue = display_value_blue_dec;
                    value_blue = value_blue == 0 ? 0 : value_blue - 1;
                end
                display_value = display_value_blue;
            end
        endcase
    end 
endmodule