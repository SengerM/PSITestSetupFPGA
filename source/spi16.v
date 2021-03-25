// spi16.v

`timescale 1ns/1ps


module spi16
(
	input clk,
	input res_n,
	
	input  nSS,
	input  SCLK,
	input  MOSI,
	output MISO,

	output reg write,
	input  [15:0]din,
	output reg [15:0]dout
);

	reg [1:0]state; // 0 = wait for nSS; 1 = wait for sample; 2 = wait for shift; 3 = write
	reg [3:0]bitcnt; // Bit counter (bit 3 = byte count
	reg [15:0]shreg; //  MISO <- shreg <- mosi_sample <- MOSI
	reg mosi_sample;
	reg nss1;
	reg sclk1;
	
	assign MISO = shreg[15];

	always @(posedge clk or negedge res_n)
	begin
		if (!res_n)
		begin
			state <= 2'd0;
			bitcnt <= 4'd0;
			shreg <= 16'd0;
			mosi_sample <= 1'd0;
			nss1  <= 1'd0;
			sclk1 <= 1'd0;
			write <= 1'd0;
			dout  <= 16'd0;
		end
		else
		begin
			nss1  <= nSS;
			sclk1 <= SCLK;
			if (nss1)
			begin
				state <= 2'd0;
				bitcnt <= 4'd0;
			end
			else
			begin // CPOL = 0; CPHA = 0
				case (state)
					2'd0: // falling nSS edge: load data
						begin
							shreg <= din;
							state <= 2'd1;
						end
					2'd1: // rising SCLK edge: sample
						if (sclk1)
						begin
							mosi_sample <= MOSI;
							state <= 2'd2;
						end
					2'd2: // falling SCLK: shift
						if (!sclk1)
						begin
							shreg <=  {shreg[14:0], mosi_sample};
							bitcnt <= bitcnt + 4'd1;
							state <= (bitcnt == 4'd15)? 2'd3 : 2'd1;
						end
					2'd3: // write
						begin
							shreg <= din;
							dout <= shreg;
							state <= 2'b1;
						end
				endcase
				write <= (state == 2'd3);
			end
		end
	end

endmodule
