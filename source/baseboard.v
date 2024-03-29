// baseboard.v

`timescale 1ns/1ps

module baseboard(
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
	inout DIO1,   // 5.74
	inout DIO2,   // 4.70 P
	input DIO3,   // 5.75
	input DIO4,   // 4.69 N
	input DIO5,   // 5.76
	input DIO6,   // 4.66
	input DIO7,   // 5.77
	input DIO8,   // 4.65 P
	input DIO9,   // 5.78
	input DIO10,  // 4.64 N
	input DIO11,  // 5.79
	input DIO12,  // 4.62
	input DIO13,  // 4.61
	input DIO14,  // 5.80
	input DIO15,  // 5.81
	input DIO16,  // 5.84
	input DIO17,  // 5.85
	input DIO18,  // 5.86
	input DIO19,  // 5.87
	
	// Bank 6, 7; 1.2V
	// Bank 8; 3.3V
	output DIO20,  // 6.88
	output DIO21,  // 6.89
	output DIO22,  // 6.90
	output DIO23,  // 6.91
	output DIO24,  // 6.92
	output DIO25,  // 6.93
	output DIO26,  // 6.96
	output DIO27,  // 6.97
	output DIO28,  // 6.98
	output DIO29,  // 6.99
	output DIO30,  // 6.100
	output DIO31,  // 6.101
	input DIO32,  // 6.102
	input DIO33,  // 6.105
	input DIO34,  // 6.106
	input DIO35,  // 8.141
	inout DIO36,  // 7.110
	input DIO37,  // 8.140
	inout DIO38,  // 7.111
	input DIO39,  // 8.135
	inout DIO40,  // 7.112
	input DIO41,  // 8.132
	inout DIO42,  // 7.113
	input DIO43,  // 8.131
	input DIO44,  // 7.114
	input DIO45,  // 8.130
	input DIO46,  // 7.118
	input DIO47,  // 8.127
	input DIO48,  // 7.119
	input DIO49,  // 8.124
	input DIO50,  // 8.120
	input DIO51   // 8.123
);
	
	wire clk;
	wire res_n;
	
	MainPLL	pll	(
		.inclk0(CLOCK1),
		.c0 (clk),
		.locked (res_n)
	);
	
	// --- LEMO input/output --------------------------------------
	assign OUT1 = clk;
	assign OUT2 = 1'b0;
	
	// Signals mapping with DIO (see KiCAD design) ---------------------
	wire [3:0]TEST_STRUCTURE_SEL;
	wire TEST_STRUCTURE_AOUT_RESET;
	wire TEST_STRUCTURE_RESET;
	wire TEST_STRUCTURE_ENA;
	wire TEST_STRUCTURE_BLOCK_RESET;
	wire TEST_STRUCTURE_BLOCK_HOLD;
	wire TEST_STRUCTURE_POLARITY;
	wire pulse_generator_trigger;
	assign {DIO23,DIO22,DIO21,DIO20} = TEST_STRUCTURE_SEL;
	assign DIO27 = TEST_STRUCTURE_AOUT_RESET;
	assign DIO26 = TEST_STRUCTURE_RESET;
	assign DIO24 = TEST_STRUCTURE_ENA;
	assign DIO25 = TEST_STRUCTURE_BLOCK_RESET;
	assign DIO28 = TEST_STRUCTURE_BLOCK_HOLD;
	assign DIO29 = TEST_STRUCTURE_POLARITY;
	assign pulse_generator_trigger = DIO34;
	
	// Internal signals for the sequencer ------------------------------
	reg [9:0]internal_RESET_release_time;
	reg [9:0]internal_AOUT_RESET_release_time;
	reg [9:0]internal_measure_time;
	reg [3:0]internal_SEL;
	reg internal_BLOCK_RESET;
	reg internal_BLOCK_HOLD;
	reg internal_POLARITY;
	wire run_sequencer;
	assign run_sequencer = time_since_last_trigger_arrived==10'd36;
	
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
	
	spi16 raspi_spi(
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

	assign spi_d = 16'd0;
	
	// Command decoder -------------------------------------------------
	// Not an expert in SPI here, but what I see from the previous implementation
	// of this is that we have our data (i.e. the command) in the `spi_q`
	// wire. So here I define my format for the commands being
	//     spi_q[15:0] = CCCCDDDDDDDDDDDD
	// where `CCCC` is a code identifying which command it is and
	// `DDD...` is data for such command.
	localparam CMD_CODE_FOR_SETTING_BLOCK_RESET = 4'b0001;
	localparam CMD_CODE_FOR_SETTING_BLOCK_HOLD = 4'b0010;
	localparam CMD_CODE_FOR_SETTING_POLARITY = 4'b0011;
	localparam CMD_CODE_FOR_SETTING_RESET_RELEASE_TIME = 4'b0100;
	localparam CMD_CODE_FOR_SETTING_AOUT_RESET_RELEASE_TIME = 4'b0101;
	localparam CMD_CODE_FOR_SETTING_MEASURE_TIME = 4'b0110;
	localparam CMD_CODE_FOR_SETTING_SEL = 4'b0111;
	localparam CMD_CODE_FOR_CMD_ENA = 4'b1001;
	
	reg cmd_enable_spi_commands;
	
	always @(posedge clk or negedge res_n) begin
		ENA_US1 <= 1; // Enable the voltage regulator.
		if (!res_n)
			cmd_enable_spi_commands <= 1'b0;
		else begin
			if (spi_write) begin
				cmd_enable_spi_commands <= (spi_q[15:12] == CMD_CODE_FOR_CMD_ENA);
				if (spi_enable) begin
					case (spi_q[15:12])
						CMD_CODE_FOR_SETTING_SEL: internal_SEL <= spi_q;
						CMD_CODE_FOR_SETTING_BLOCK_RESET: internal_BLOCK_RESET <= spi_q;
						CMD_CODE_FOR_SETTING_BLOCK_HOLD: internal_BLOCK_HOLD <= spi_q;
						CMD_CODE_FOR_SETTING_POLARITY: internal_POLARITY <= spi_q;
						CMD_CODE_FOR_SETTING_RESET_RELEASE_TIME: internal_RESET_release_time <= spi_q;
						CMD_CODE_FOR_SETTING_AOUT_RESET_RELEASE_TIME: internal_AOUT_RESET_release_time <= spi_q;
						CMD_CODE_FOR_SETTING_MEASURE_TIME: internal_measure_time <= spi_q;
						endcase
					end
				end
			end
		end
	
	always @(posedge clk or negedge res_n) begin // Enable or disable SPI commands
		if (!res_n) spi_enable <= 1'd0;
		else if (cmd_enable_spi_commands) 
			spi_enable <= spi_q[0];
		end
	
	// -----------------------------------------------------------------
	reg pulse_generator_trigger_has_arrived;
	reg [9:0]time_since_last_trigger_arrived;
	always @(posedge clk) begin
		if (!pulse_generator_trigger)
			pulse_generator_trigger_has_arrived <= 1'b1;
		if (pulse_generator_trigger_has_arrived) begin
			time_since_last_trigger_arrived <= time_since_last_trigger_arrived + 9'd1;
			if (time_since_last_trigger_arrived == 9'd99)
				pulse_generator_trigger_has_arrived <= 1'b0;
			end
		else
			time_since_last_trigger_arrived <= 9'd0;
		end
	// -----------------------------------------------------------------
	
	sequencer_for_PIX_V1_SW_28_10_19 DUT (
		.clk(clk),
		.reset(1'b0),
		.run_sequencer(run_sequencer), // Setting this to 1 starts the sequencer.
		.RESET_release_time(internal_RESET_release_time), // After this time since the `run_sequencer` signal, the `_RESET` is released.
		.AOUT_RESET_release_time(internal_AOUT_RESET_release_time), // After this time since the `run_sequencer` signal, the `AOUT_RESET` is released.
		.measure_time(internal_measure_time), // After this time since the `run_sequencer` signal, the state machine goes out of the "measure" state.
		.SEL_input(internal_SEL), // When the `run_sequencer` signal arrives, this value will be applied to the `SEL` output.
		.BLOCK_RESET_input(internal_BLOCK_RESET), // When the `run_sequencer` signal arrives, this value will be applied to the `BLOCK_RESET` output.
		.BLOCK_HOLD_input(internal_BLOCK_HOLD), // When the `run_sequencer` signal arrives, this value will be applied to the `BLOCK_HOLD` output.
		.POLARITY_input(internal_POLARITY), // When the `run_sequencer` signal arrives, this value will be applied to the `POLARITY` output.
		.ready_flag(ready_flag), // 1 means that the sequencer is ready to start a new run, 0 means it is not.
		.measure_flag(measure_flag),
		.SEL(TEST_STRUCTURE_SEL),
		.ENA(TEST_STRUCTURE_ENA),
		.BLOCK_RESET(TEST_STRUCTURE_BLOCK_RESET),
		._RESET(TEST_STRUCTURE_RESET),
		.AOUT_RESET(TEST_STRUCTURE_AOUT_RESET),
		.BLOCK_HOLD(TEST_STRUCTURE_BLOCK_HOLD),
		.POLARITY(TEST_STRUCTURE_POLARITY)
	);
	
	endmodule

	
