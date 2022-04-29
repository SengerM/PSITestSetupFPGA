`timescale 1ns/1ps // time-unit = 1 ns, precision = 1 ps
`include "../source/sequencer_for_PIX_V1_SW_28_10_19.v"

module sequencer_test_bench;
	reg clk;
	
	localparam CLK_HALF_PERIOD = 1;
	localparam CLK_PERIOD = CLK_HALF_PERIOD+CLK_HALF_PERIOD;
	localparam SIMULATION_CLK_CYCLES = 11111;
	
	// Simulation stuff -----------------------------------------------------------//
	initial clk = 1;                                                               //
	always #CLK_HALF_PERIOD clk = ~clk;                                            //
	initial #SIMULATION_CLK_CYCLES $finish;                                        //
	initial begin                                                                  //
		$dumpfile("sequencer_for_PIX_V1_SW_28_10_19_test_bench.vcd");              //
		$dumpvars(0, sequencer_test_bench);                                        //
		end                                                                        //
	// ----------------------------------------------------------------------------//
	
	reg reset;

	reg run_sequencer; // Setting this to 1 starts the sequencer.
	reg [9:0]RESET_release_time; // After this time since the `run_sequencer` signal, the `_RESET` is released.
	reg [9:0]AOUT_RESET_release_time; // After this time since the `run_sequencer` signal, the `AOUT_RESET` is released.
	reg [9:0]measure_time; // After this time since the `run_sequencer` signal, the state machine goes out of the "measure" state.
	reg [3:0]SEL_input; // When the `run_sequencer` signal arrives, this value will be applied to the `SEL` output.
	reg BLOCK_RES_input; // When the `run_sequencer` signal arrives, this value will be applied to the `BLOCK_RES` output.
	reg BLOCK_HOLD_input; // When the `run_sequencer` signal arrives, this value will be applied to the `BLOCK_HOLD` output.
	reg POLARITY_input; // When the `run_sequencer` signal arrives, this value will be applied to the `POLARITY` output.

	wire ready_flag; // 1 means that the sequencer is ready to start a new run, 0 means it is not.
	wire measure_flag; // This is what Beat called "measure".

	// PIX_V1_SW_28_10_19 test structure ---//
	wire [3:0]SEL;
	wire ENA;
	wire BLOCK_RES;
	wire _RESET;
	wire AOUT_RESET;
	wire BLOCK_HOLD;
	wire POLARITY;
	// -------------------------------------//
	
	sequencer_for_PIX_V1_SW_28_10_19 DUT (
		.clk(clk),
		.reset(reset),
		.run_sequencer(run_sequencer), // Setting this to 1 starts the sequencer.
		.RESET_release_time(RESET_release_time), // After this time since the `run_sequencer` signal, the `_RESET` is released.
		.AOUT_RESET_release_time(AOUT_RESET_release_time), // After this time since the `run_sequencer` signal, the `AOUT_RESET` is released.
		.measure_time(measure_time), // After this time since the `run_sequencer` signal, the state machine goes out of the "measure" state.
		.SEL_input(SEL_input), // When the `run_sequencer` signal arrives, this value will be applied to the `SEL` output.
		.BLOCK_RES_input(BLOCK_RES_input), // When the `run_sequencer` signal arrives, this value will be applied to the `BLOCK_RES` output.
		.BLOCK_HOLD_input(BLOCK_HOLD_input), // When the `run_sequencer` signal arrives, this value will be applied to the `BLOCK_HOLD` output.
		.POLARITY_input(POLARITY_input), // When the `run_sequencer` signal arrives, this value will be applied to the `POLARITY` output.
		.ready_flag(ready_flag), // 1 means that the sequencer is ready to start a new run, 0 means it is not.
		.measure_flag(measure_flag),
		.SEL(SEL),
		.ENA(ENA),
		.BLOCK_RES(BLOCK_RES),
		._RESET(_RESET),
		.AOUT_RESET(AOUT_RESET),
		.BLOCK_HOLD(BLOCK_HOLD),
		.POLARITY(POLARITY)
	);
	
	initial begin
		reset = 1;
		run_sequencer = 0;
		SEL_input = 4'd3;
		BLOCK_RES_input = 1'b0;
		BLOCK_HOLD_input = 1'b0;
		POLARITY_input = 1'b0;
		RESET_release_time = 10'd5;
		AOUT_RESET_release_time = 10'd7;
		measure_time = 9'd33;
		
		#(2*CLK_PERIOD);
		
		reset = 0;
		
		#CLK_PERIOD;
		run_sequencer = 1;
		#CLK_PERIOD;
		run_sequencer = 0;
		
		#(1000*CLK_PERIOD);
		run_sequencer = 1;
		#(50*CLK_PERIOD);
		run_sequencer = 0;
		end
	
	
endmodule
