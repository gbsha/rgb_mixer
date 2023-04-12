// Debouncer for reading input pins as discussed in
// In the https://zerotoasiccourse.com/ course.
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


// binary coding decimal (BCD) counter.
// From https://github.com/icebreaker-fpga/icebreaker-workshop
// Modifications:
// - saturates at 0 and MAX_CNT
// - supports increment and decrement
module bcd8_saturated_counter #(parameter MAX_CNT = 'h99)(
	input [7:0] value,
	output reg [7:0] increment,
	output reg [7:0] decrement
);
    always @* begin
        // Calculate increment
		if (value[7:0] == MAX_CNT) // saturate at max value
            increment = MAX_CNT;
		else if	(value[3:0] == 4'h 9) // carry over for LS decimal = 9
            increment = {value[7:4] + 4'd 1, 4'h 0};
        else
            increment = {value[7:4], value[3:0] + 4'd 1};

        // Calculate decrement
		if (value[7:0] == 8'h0) // saturate at min value 0
            decrement = 8'h0;
		else if	(value[3:0] == 4'h 0) // carry over at LS decimal = 0
            decrement = {value[7:4] - 4'd 1, 4'h 9};
        else
            decrement = {value[7:4], value[3:0] - 4'd 1};
	end
endmodule


// Rotary decoder for Gray coded signals from rotary encoder.
// Provides increment and decrement signals at the speed of the provided clock
// increment detected: increment signal is high for 1 clock cycle.
// decrement detected: decrement signal is high for 1 clock cycle.
module rotary_decoder(
	input CLK,
	input A, B,
	output reg increment,
    output reg decrement,
);

reg [1:0] AB_old = 2'b11;
reg [9:0] memory = 10'b11_1111_1111;

always @(posedge CLK) begin
	if({A, B} != AB_old) begin
		memory = memory << 2;
		memory[1:0] = {A, B};
		case(memory)
			10'b111000_0111: begin
				increment = 1;
			end
			10'b110100_1011: begin
				decrement = 1;
			end
		endcase
		AB_old = {A, B};
	end else begin
		increment = 0;
		decrement = 0;
	end
end
endmodule