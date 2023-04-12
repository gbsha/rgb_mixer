// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none
`include "led_display.v"
`include "utility_modules.v"

// Project entry point
module top (
	input  CLK,
	input  BTN_N, BTN1,
	output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
);
    // 
    wire BTN1_debounced;
    reg [1:0] color_selector = 0;

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

    always @(posedge BTN1_debounced) begin
        case (color_selector)
            2'd2: color_selector = 2'd0;
            default: color_selector = color_selector + 1;
        endcase
        display_value[1:0] = color_selector;
    end

	// 7 segment display control Pmod 1A
	seven_seg_ctrl seven_segment_ctrl (
		.CLK(CLK),
		.din(display_value[7:0]),
		.dout(seven_segment)
	);

endmodule
