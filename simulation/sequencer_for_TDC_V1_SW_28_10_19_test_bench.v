`timescale 1ns/1ps // time-unit = 1 ns, precision = 1 ps
`include "../source/sequencer_for_TDC_V1_SW_28_10_19.v"

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
		$dumpfile("sequencer_for_TDC_V1_SW_28_10_19_test_bench.vcd");              //
		$dumpvars(0, sequencer_test_bench);                                        //
		end                                                                        //
	// ----------------------------------------------------------------------------//
	
	reg reset;
	reg run_sequencer;
	reg [7:0]t_start_coarse;
	reg [7:0]t_stop_coarse;
	wire ready_flag;
	wire measure_flag;
	wire write;
	wire [15:0]data;
	wire [3:0]SEL;
	wire PSTART;
	wire PSTOP;
	wire RES;
	reg [6:0]DOUT;
	reg [20:0]SAFF;
	
	sequencer_for_TDC_V1_SW_28_10_19 DUT (
		.clk(clk),
		.reset(reset),
		.run_sequencer(run_sequencer), // Setting this to 1 starts the sequencer.
		.t_start_coarse(t_start_coarse),
		.t_stop_coarse(t_stop_coarse),
		.ready_flag(ready_flag), // 1 means that the sequencer is ready to start a new run, 0 means it is not.
		.measure_flag(measure_flag), // This is what Beat called "measure".
		.write(write), // This tells the RAM memory when to write.
		.data(data), // This sends the data to the RAM memory.
		.SEL(SEL),
		.PSTART(PSTART),
		.PSTOP(PSTOP),
		.RES(RES),
		.DOUT(DOUT),
		.SAFF(SAFF)
	);
	
	initial begin
		reset = 1;
		run_sequencer = 0;
		t_start_coarse = 8'd0;
		t_stop_coarse = 8'd0;
		DOUT = 7'b1111111;
		SAFF = 21'd0;
		
		#(2*CLK_PERIOD);
		
		reset = 0;
		
		#CLK_PERIOD;
		run_sequencer = 1;
		#CLK_PERIOD;
		run_sequencer = 0;
		
		#(1000*CLK_PERIOD);
		run_sequencer = 1;
		#CLK_PERIOD;
		run_sequencer = 0;
		end
	
	
endmodule
