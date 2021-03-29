// baseboard.v

`timescale 1ns/1ps


module baseboard
(
	// --- 10 MHz Clock inputs ------------------------------------
	input CLOCK1, // 2.26
	input CLOCK2, // 2.27
	input CLOCK3, // 2.28
	input CLOCK4, // 2.29
	
	// --- Raspberry Pi interface ---------------------------------
	inout  SCL,        // 3.38
	inout  SDA,        // 3.39

	output SPI_CE1,    // 3.47 ADC SPI nCS
	input  SPI_CE0,    // 3.41 GPIO8
	output SPI_MISO,   // 3.45 GPIO9
	input  SPI_MOSI,   // 3.44 GPIO10
	input  SPI_SCLK,   // 3.43 GPIO11

	output RPI_GPIO6,  // 2.33 ADC SPI SCLK
	output RPI_GPIO12, // 2.32 ADC SPI MOSI
	input  RPI_GPIO13, // 2.30 ADC SPI MISO
	
	// --- general purpose LEMO input/output
	input IN1,   // 1A.11
	input IN2,   // 1A.12
	output OUT1, // 1A.13
	output OUT2, // 1A.14
	
	// --- US1, US2 enable ----------------------------------------
	output reg ENA_US1, // 24
	output reg ENA_US2, // 25
	
	// --- Digital IO signals
	// Bank 4, 5; 3.3V
	output DIO1,   // 5.74
	output reg PSTOP, // 4.70P 4.69N
//	inout  DIO2,   // 4.70 P
	output DIO3,   // 5.75
//	output DIO4,   // 4.69 N
	output DIO5,   // 5.76
	output DIO6,   // 4.66
	output DIO7,   // 5.77
	output reg PSTART, // 4.65P 4.64N
//	inout  DIO8,   // 4.65 P
	output DIO9,   // 5.78
//	output DIO10,  // 4.64 N
	output DIO11,  // 5.79
	inout  DIO12,  // 4.62
	output DIO13,  // 4.61
	output DIO14,  // 5.80
	output DIO15,  // 5.81
	output DIO16,  // 5.84
	output DIO17,  // 5.85
	output DIO18,  // 5.86
	output DIO19,  // 5.87
	
	// Bank 6, 7; 1.2V
	// Bank 8; 3.3V
	inout  DIO20,  // 6.88
	inout  DIO21,  // 6.89
	inout  DIO22,  // 6.90
	inout  DIO23,  // 6.91
	inout  DIO24,  // 6.92
	inout  DIO25,  // 6.93
	inout  DIO26,  // 6.96
	inout  DIO27,  // 6.97
	inout  DIO28,  // 6.98
	inout  DIO29,  // 6.99
	inout  DIO30,  // 6.100
	inout  DIO31,  // 6.101
	inout  DIO32,  // 6.102
	inout  DIO33,  // 6.105
	inout  DIO34,  // 6.106
	inout  DIO35,  // 8.141
	inout  DIO36,  // 7.110
	inout  DIO37,  // 8.140
	inout  DIO38,  // 7.111
	input  DIO39,  // 8.135
	inout  DIO40,  // 7.112
	input  DIO41,  // 8.132
	inout  DIO42,  // 7.113
	output DIO43,  // 8.131
	output DIO44,  // 7.114
	input  DIO45,  // 8.130
	output DIO46,  // 7.118
	output  DIO47,  // 8.127
	output DIO48,  // 7.119
	output  DIO49,  // 8.124
	output DIO50,  // 8.120
	output  DIO51   // 8.123
);
	
	// --- clock, reset -------------------------------------------
	wire clk;
	wire res_n;
	
	MainPLL	pll	(
		.inclk0(CLOCK1),
		.c0 (clk),
		.locked (res_n)
	);
	
	//  Adapter board and delay chips signals --------------------------
	reg ADAPTER_BOARD_VOLTAGE_REGULATOR_ENABLE; // 2.5 V regulator enable.
	reg DELAY_CHIPS_ENABLE; // Enable pin of the delay chips.
	reg [9:0]DELAY_CHIPS_D; // D input of the delay chips.
	reg DELAY_CHIPS_LENA; // LEN input of the delay chip A.
	reg DELAY_CHIPS_LENB; // LEN input of the delay chip B.
	
	// Signals of the test structure TDC_V1_SW_28_10_19 ----------------
	reg [3:0]TEST_STRUCTURE_SEL; // TDC structure selection.
	wire [6:0]TEST_STRUCTURE_DOUT; // TDC counter output.
	wire [20:0]TEST_STRUCTURE_SAFF; // TDC inverters chain output.
	reg TEST_STRUCTURE_RES; // Test structure reset.
	
	// Signals mapping with DIO (see KiCAD design) ---------------------
	assign DIO6 = ADAPTER_BOARD_VOLTAGE_REGULATOR_ENABLE;
	assign DIO19 = DELAY_CHIPS_ENABLE;
	assign {DIO1, DIO3, DIO9, DIO11, DIO13, DIO14, DIO15, DIO16, DIO17, DIO18} = DELAY_CHIPS_D;
	assign DIO7  = DELAY_CHIPS_LENA;
	assign DIO5  = DELAY_CHIPS_LENB;
	assign {DIO47, DIO49, DIO51, DIO50} = TEST_STRUCTURE_SEL;
	assign TEST_STRUCTURE_DOUT = {DIO48, DIO45, DIO43, DIO41, DIO39, DIO37, DIO35};
	assign DIO12 = TEST_STRUCTURE_RES;
	
	// Internal signals ------------------------------------------------
	wire [9:0]DELAY_CHIPS_D_internal;
	wire DELAY_CHIPS_LENA_internal;
	wire DELAY_CHIPS_LENB_internal;
	wire [3:0]TEST_STRUCTURE_SEL_internal;
	reg [5:0]TEST_STRUCTURE_DOUT_internal;
	wire PSTART_internal;
	wire PSTOP_internal;
	wire ready;
	wire measuring;

	// --- I2C ----------------------------------------------------
	assign SCL = 1'bz; // Unused input.
	assign SDA = 1'bz; // Unused input.
	
	// --- SPI ----------------------------------------------------
	wire spi_write;
	wire [15:0]spi_d;
	wire [15:0]spi_q;

	reg spi_enable;
	reg data_mode;

	wire write;
	reg  [4:0]writeaddr;
	wire [15:0]writedata;
	reg  [4:0]readaddr;
	wire [15:0]readdata;
	
	spi16 raspi_spi
	(
		.clk(clk),
		.res_n(res_n),
		.nSS(SPI_CE0),
		.SCLK(SPI_SCLK),
		.MOSI(SPI_MOSI),
		.MISO(SPI_MISO),
		.write(spi_write),
		.din(spi_d),
		.dout(spi_q)
	);

	assign spi_d = data_mode ? readdata : {ready, spi_enable, 6'd2, 2'b_00, TEST_STRUCTURE_DOUT_internal};

	// --- LEMO input/output --------------------------------------
	assign OUT1 = write;
	assign OUT2 = write;

	// --- Command decoder ----------------------------------------
	reg cmd_del;
	reg cmd_run_sequencer;
	reg cmd_ena;
	reg cmd_read_start;
	reg cmd_read;
	reg cmd_read_last;

	reg [7:0]tstart;
	reg [7:0]tstop;

	always @(posedge clk or negedge res_n)
	begin
		if (!res_n)
		begin
			cmd_del <= 1'b0;
			cmd_run_sequencer <= 1'd0;
			cmd_ena <= 1'd0;
			cmd_read_start <= 1'b0;
			cmd_read <= 1'b0;
			cmd_read_last <= 1'b0;
			tstart  <= 8'd0;
			tstop   <= 8'd0;
		end
		else
		begin
			cmd_ena <= spi_write && (spi_q[15:12] == 4'b1001);
			if (spi_enable)
			begin
				cmd_del           <= spi_write && (spi_q[15:13] == 3'b001);
				cmd_run_sequencer <= spi_write && (spi_q[15:13] == 3'b010);
			   cmd_read_start    <= spi_write && (spi_q[15:12] == 4'b1100);
			   cmd_read          <= spi_write && (spi_q[15:12] == 4'b1101);
			   cmd_read_last     <= spi_write && (spi_q[15:12] == 4'b1110);
				if (spi_write && (spi_q[15:11] == 5'b01100)) tstart <= spi_q[7:0];
				if (spi_write && (spi_q[15:11] == 5'b01101)) tstop  <= spi_q[7:0];			
			end
		end
	end	

	// --- SPI enable
	always @(posedge clk or negedge res_n)
	begin
		if (!res_n) spi_enable <= 1'd0;
		else if (cmd_ena && (spi_q[7:1] == 7'b1001000)) spi_enable <= spi_q[0];
	end

	// --- Read Data
	always @(posedge clk or negedge res_n)
	begin
		if (!res_n)
		begin
			data_mode <= 1'b0;
			readaddr <= 5'd0;
		end
		else
		begin
			if (cmd_read_start)
			begin
				data_mode <= 1'b1;
				readaddr <= 5'd0;
			end
			else if (cmd_read)
			begin
				readaddr <= readaddr + 5'd1;
			end
			else if (cmd_read_last || cmd_ena)
			begin
				data_mode <= 1'b0;
			end
		end
	end

	// --- Write Data
	always @(posedge clk or negedge res_n)
	begin
		if (!res_n) writeaddr <= 5'd0;
		else
		begin
			if (measuring) writeaddr <= 5'd0;
			else if (write) writeaddr <= writeaddr + 5'd1;
		end
	end

	datamem RAM
	(
		.clock(clk),
		.data(writedata),
		.rdaddress(readaddr),
		.wraddress(writeaddr),
		.wren(write),
		.q(readdata)
	);

	delay del
	(
		.clk(clk),
		.res_n(res_n),
		.set(cmd_del),
		.sel(spi_q[12]),
		.d(spi_q[9:0]),
		.lena(DELAY_CHIPS_LENA_internal),
		.lenb(DELAY_CHIPS_LENB_internal),
		.delay(DELAY_CHIPS_D_internal)
	);

	sequencer_for_TDC_V1_SW_28_10_19 sequencer
	(
		.clk(clk),
		.reset(!res_n),
		.run_sequencer(cmd_run_sequencer),
		.t_start_coarse(tstart),
		.t_stop_coarse(tstop),
		.ready_flag(ready),
		.measure_flag(measuring),
		.SEL(TEST_STRUCTURE_SEL_internal),
		.PSTART(PSTART_internal),
		.PSTOP(PSTOP_internal),
		.RES(TEST_STRUCTURE_RES),
		.DOUT(TEST_STRUCTURE_DOUT_internal),
		.SAFF(TEST_STRUCTURE_SAFF),
		.write(write),
		.data(writedata)
	);

	always @(posedge clk or negedge res_n)
	begin
		if (!res_n)
		begin
			ADAPTER_BOARD_VOLTAGE_REGULATOR_ENABLE <= 1'b0;
			ENA_US1 <= 1'b0;
			ENA_US2 <= 1'b0;
			DELAY_CHIPS_ENABLE <= 1'b0;
			DELAY_CHIPS_D <= 10'd0;
			DELAY_CHIPS_LENA <= 1'b0;
			DELAY_CHIPS_LENB <= 1'b0;
			TEST_STRUCTURE_SEL <= 3'd0;
			PSTART <= 1'b0;
			PSTOP <= 1'b0;
			TEST_STRUCTURE_DOUT_internal <= 6'd0;
		end
		else if (spi_enable)
		begin
			ADAPTER_BOARD_VOLTAGE_REGULATOR_ENABLE <= 1'b1;
			ENA_US1 <= 1'b1;
			ENA_US2 <= 1'b1;
			DELAY_CHIPS_ENABLE <= 1'b0;
			DELAY_CHIPS_D <= DELAY_CHIPS_D_internal;
			DELAY_CHIPS_LENA <= DELAY_CHIPS_LENA_internal;
			DELAY_CHIPS_LENB <= DELAY_CHIPS_LENB_internal;
			TEST_STRUCTURE_SEL <= TEST_STRUCTURE_SEL_internal;
			PSTART <= !PSTART_internal;
			PSTOP <= !PSTOP_internal;
			if (|TEST_STRUCTURE_SEL_internal) TEST_STRUCTURE_DOUT_internal <= TEST_STRUCTURE_DOUT;
		end		
		else
		begin
			ADAPTER_BOARD_VOLTAGE_REGULATOR_ENABLE <= 1'b0;
			ENA_US1 <= 1'b0;
			ENA_US2 <= 1'b0;
			DELAY_CHIPS_ENABLE <= 1'b0;
			DELAY_CHIPS_D <= 10'd0;
			DELAY_CHIPS_LENA <= 1'b0;
			DELAY_CHIPS_LENB <= 1'b0;
			TEST_STRUCTURE_SEL <= 3'd0;
			PSTART <= 1'b0;
			PSTOP <= 1'b0;
			TEST_STRUCTURE_DOUT_internal <= TEST_STRUCTURE_DOUT;
		end
	end
endmodule

	
