// delay.v

`timescale 1ns/1ps


module delay
(
	input clk,
	input res_n,
	
	input set,
	input sel,
	input [9:0]d,

	output lena, // 800 ns neg pulse
	output lenb, // 800 ns neg pulse
	output reg [9:0]delay
);

	reg [5:0]state;

	always @(posedge clk or negedge res_n)
	begin
		if (!res_n)
		begin
			delay <= 10'd0;
			state <= 6'd0;
		end
		else if (|state) state <= state + 6'd1;
		else if (set)
		begin
			delay <= d;
			state <= 6'd1;
		end
	end

	assign lena = !(state[5] & !sel);
	assign lenb = !(state[5] &  sel);

endmodule
