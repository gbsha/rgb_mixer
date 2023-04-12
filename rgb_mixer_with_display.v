// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none
`include "led_display.v"
`include "utility_modules.v"


// Project entry point
module top #(parameter MAX_BW = 5,
             parameter MAX_VAL = 5'b1_1111, 
             parameter MAX_CNT = 8'h31)(
	input  CLK,
	input  BTN_N, BTN1, P1B7, P1B8,
    output P1B1, P1B2, P1B3,
	output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10, LED5, LED3, LED4
);
    reg ON_red = 1;
	reg ON_green = 1;
	reg ON_blue = 1;
	assign P1B1 = ON_red;
	assign P1B2 = ON_green;
	assign P1B3 = ON_blue;

	reg [4:0] value_red = 0;
	reg [4:0] value_green = 0;
	reg [4:0] value_blue = 0;

    // TODO: make configurable
    always @(posedge CLKBANK[12]) begin
		ON_red = CLKBANK[16:12] >= value_red;
		ON_green = CLKBANK[16:12] >= value_green;
		ON_blue = CLKBANK[16:12] >= value_blue;
	end

    
    wire BTN1_debounced;
    reg [2:0] color_selector = 3'b001;
    assign LED5 = color_selector[0];
    assign LED3 = color_selector[1];
    assign LED4 = color_selector[2];

    // 
	wire A = P1B7;
	wire B = P1B8;
	wire A_debounced;
	wire B_debounced;

    // binary coded decimal counters
	reg [7:0] display_value_red = 0;
    wire [7:0] display_value_red_inc;
    wire [7:0] display_value_red_dec;

	reg [7:0] display_value_green = 0;
    wire [7:0] display_value_green_inc;
    wire [7:0] display_value_green_dec;

	reg [7:0] display_value_blue = 0;
    wire [7:0] display_value_blue_inc;
    wire [7:0] display_value_blue_dec;

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

    always @(posedge BTN1_debounced) begin
        color_selector <= {color_selector[1:0], color_selector[2]};
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
	//
	debouncer debounce_BTN1(
		.CLK(CLKBANK[10]),
		.signal_in(BTN1),
		.signal_out(BTN1_debounced)
	);

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