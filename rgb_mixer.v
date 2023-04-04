// Cause yosys to throw an error when we implicitly declare nets
`default_nettype none

// Project entry point

module top (
	input BTN1,
	input  CLK, P1B1, P1B2, P1B3, P1B4, P1B7, P1B8,
	input LED_RED_N, LED_GRN_N, LED_BLU_N, 
	output LED1,
	output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
);
	reg ON1 = 0;
	reg ON2 = 1;
	reg ON3 = 1;
	assign P1A1 = ON1;
	assign P1A2 = ON2;
	assign P1A3 = ON3;
	
	reg [31:0] CLKBANK = 0; // clock divider
	reg LED1ON = 0;
	assign LED1 = LED1ON;

	// RED
	wire A1 = P1B1;
	wire B1 = P1B2;
	wire A1_debounced;
	wire B1_debounced;
	wire [4:0] display_value1;
	// GREEN
	wire A2 = P1B3;
	wire B2 = P1B4;
	wire A2_debounced;
	wire B2_debounced;
	wire [4:0] display_value2;
	// BLUE
	wire A3 = P1B7;
	wire B3 = P1B8;
	wire A3_debounced;
	wire B3_debounced;
	wire [4:0] display_value3;

	// PWM [17]
	always @(posedge CLKBANK[12]) begin
		ON1 = CLKBANK[16:12] <= display_value1;
		ON2 = CLKBANK[16:12] <= display_value2;
		ON3 = CLKBANK[16:12] <= display_value3;
	end


	// LED DISPLAY
	// 7 segment control line bus
	// wire [7:0] seven_segment;
	// Assign 7 segment control line bus to Pmod pins
	// assign { P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 } = seven_segment;
	// Display value register and increment bus
	reg [7:0] display_value = 0;

	// Clock-Divider
	always @(posedge CLK) begin
		CLKBANK <= CLKBANK + 1;
	end

	/*
	always @(posedge CLKBANK[24]) begin
		LED1ON <= LED1ON + 1;
	end */

	// DEBOUNCER
	// RED
	debouncer debounce_A1(
		.CLK(CLKBANK[10]),
		.signal_in(A1),
		.signal_out(A1_debounced)
	);
	debouncer debounce_B1(
		.CLK(CLKBANK[10]),
		.signal_in(B1),
		.signal_out(B1_debounced)
	);
	// GREEN
	debouncer debounce_A2(
		.CLK(CLKBANK[10]),
		.signal_in(A2),
		.signal_out(A2_debounced)
	);
	debouncer debounce_B2(
		.CLK(CLKBANK[10]),
		.signal_in(B2),
		.signal_out(B2_debounced)
	);
	// BLUE
	debouncer debounce_A3(
		.CLK(CLKBANK[10]),
		.signal_in(A3),
		.signal_out(A3_debounced)
	);
	debouncer debounce_B3(
		.CLK(CLKBANK[10]),
		.signal_in(B3),
		.signal_out(B3_debounced)
	);


	// ROTARY ENCODER
	// RED
	rotary_decoder rotary_decoder1 (
		.CLK(CLKBANK[10]),
		.A(A1_debounced),
		.B(B1_debounced),
		.display_value(display_value1)
	);
	// GREEN
	rotary_decoder rotary_decoder2 (
		.CLK(CLKBANK[10]),
		.A(A2_debounced),
		.B(B2_debounced),
		.display_value(display_value2)
	);
	// BLUE
	rotary_decoder rotary_decoder3 (
		.CLK(CLKBANK[10]),
		.A(A3_debounced),
		.B(B3_debounced),
		.display_value(display_value3)
	);

	always @(posedge CLKBANK[10]) begin
		display_value[2:0] <= display_value3;
	end


	// 7 segment display control Pmod 1A
	/*
	seven_seg_ctrl seven_segment_ctrl (
		.CLK(CLK),
		.din(display_value[7:0]),
		.dout(seven_segment)
	);*/

endmodule

module rotary_decoder(
	input CLK,
	input A, B,
	output reg[4:0] display_value
);

reg [1:0] AB_old = 2'b11;
reg [9:0] memory = 10'b11_1111_1111;

always @(posedge CLK) begin
	if({A, B} != AB_old) begin
		memory = memory << 2;
		memory[1:0] = {A, B};
		case(memory)
			10'b111000_0111: begin
				display_value[4:0] <= display_value[4:0] + 1;
			end
			10'b110100_1011: begin
				display_value[4:0] <= display_value[4:0] - 1;
			end
		endcase
		AB_old <= {A, B};
	end
end
endmodule


module debouncer(
	input CLK,
	input signal_in,
	output reg signal_out
);
reg [7:0] memory = 8'b0;
reg signal_debounced;

always @(posedge CLK) begin
	memory = memory << 1;
	memory[0] = signal_in;
	signal_out <= signal_debounced;

	case(memory)
		8'b0000_0000: signal_debounced <= 0;
		8'b1111_1111: signal_debounced <= 1;
	endcase
end
endmodule

module lpf (
	input CLK,
	input signal_in,
	output reg [2:0] signal_out
);
	reg [6:0] delayer = 0;

	always @(posedge CLK) begin
		signal_out <= signal_out - delayer[6] + signal_in;
		delayer <= delayer << 1;
		delayer[0] <= signal_in;
	end
endmodule


// Seven segment controller
// Switches quickly between the two parts of the display
// to create the illusion of both halves being illuminated
// at the same time.
module seven_seg_ctrl (
	input CLK,
	input [7:0] din,
	output reg [7:0] dout
);
	wire [6:0] lsb_digit;
	wire [6:0] msb_digit;

	seven_seg_hex msb_nibble (
		.din(din[7:4]),
		.dout(msb_digit)
	);

	seven_seg_hex lsb_nibble (
		.din(din[3:0]),
		.dout(lsb_digit)
	);

	reg [9:0] clkdiv = 0;
	reg clkdiv_pulse = 0;
	reg msb_not_lsb = 0;

	always @(posedge CLK) begin
		clkdiv <= clkdiv + 1;
		clkdiv_pulse <= &clkdiv;
		msb_not_lsb <= msb_not_lsb ^ clkdiv_pulse;

		if (clkdiv_pulse) begin
			if (msb_not_lsb) begin
				dout[6:0] <= ~msb_digit;
				dout[7] <= 0;
			end else begin
				dout[6:0] <= ~lsb_digit;
				dout[7] <= 1;
			end
		end
	end
endmodule

// Convert 4bit numbers to 7 segments
module seven_seg_hex (
	input [3:0] din,
	output reg [6:0] dout
);
	always @*
		case (din)
			4'h0: dout = 7'b 0111111;
			4'h1: dout = 7'b 0000110;
			4'h2: dout = 7'b 1011011;
			// 4'h3: dout = FIXME;
			4'h3: dout = 7'b 1001111;
			4'h4: dout = 7'b 1100110;
			4'h5: dout = 7'b 1101101;
			4'h6: dout = 7'b 1111101;
			4'h7: dout = 7'b 0000111;
			// 4'h8: dout = FIXME;
			4'h8: dout = 7'b 1111111;
			4'h9: dout = 7'b 1101111;
			4'hA: dout = 7'b 1110111;
			4'hB: dout = 7'b 1111100;
			4'hC: dout = 7'b 0111001;
			4'hD: dout = 7'b 1011110;
			4'hE: dout = 7'b 1111001;
			4'hF: dout = 7'b 1110001;
			default: dout = 7'b 1000000;
		endcase
endmodule
