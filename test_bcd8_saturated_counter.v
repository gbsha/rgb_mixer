// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none
`include "led_display.v"
`include "utility_modules.v"

// Project entry point
module top (
	input  CLK,
	input  BTN_N, BTN1, BTN2,
	output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
);
    // 
    wire BTN1_debounced;
    wire BTN2_debounced;
    reg BTN1_old = 0;
    reg BTN2_old = 0;


    // binary coded decimal counter
    wire [7:0] display_value_inc;
    wire [7:0] display_value_dec;
    
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

	debouncer debouncer_BTN1(
		.CLK(CLKBANK[10]),
		.signal_in(BTN1),
		.signal_out(BTN1_debounced)
	);
	debouncer debouncer_BTN2(
		.CLK(CLKBANK[10]),
		.signal_in(BTN2),
		.signal_out(BTN2_debounced)
	);

    always @(posedge CLKBANK[10]) begin
        if ({BTN1_debounced, BTN1_old} == 2'b10)
            display_value = display_value_inc;
        if ({BTN2_debounced, BTN2_old} == 2'b10)
            display_value = display_value_dec;
        BTN1_old = BTN1_debounced;
        BTN2_old = BTN2_debounced;
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

endmodule