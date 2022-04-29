`timescale 1ns/1ps

module sequencer_for_PIX_V1_SW_28_10_19 (
	//-------------------------------------------------------------------//
	// This is the sequencer module to interface with the test structure //
	// that I am calling "PIX_V1_SW_28_10_19" which is the one produced  //
	// by S. Widerkehr that contains 4 TDC test structures.              //
	//-------------------------------------------------------------------//
	input clk,
	input reset,

	input run_sequencer, // Setting this to 1 starts the sequencer.
	input [9:0]RESET_release_time, // After this time since the `run_sequencer` signal, the `_RESET` is released.
	input [9:0]AOUT_RESET_release_time, // After this time since the `run_sequencer` signal, the `AOUT_RESET` is released.
	input [9:0]measure_time, // After this time since the `run_sequencer` signal, the state machine goes out of the "measure" state.
	input [3:0]SEL_input, // When the `run_sequencer` signal arrives, this value will be applied to the `SEL` output.
	input BLOCK_RES_input, // When the `run_sequencer` signal arrives, this value will be applied to the `BLOCK_RES` output.
	input BLOCK_HOLD_input, // When the `run_sequencer` signal arrives, this value will be applied to the `BLOCK_HOLD` output.
	input POLARITY_input, // When the `run_sequencer` signal arrives, this value will be applied to the `POLARITY` output.

	output wire ready_flag, // 1 means that the sequencer is ready to start a new run, 0 means it is not.
	output wire measure_flag, // This is what Beat called "measure".

	// PIX_V1_SW_28_10_19 test structure ---//
	output reg [3:0]SEL,                    //
	output reg ENA,                         //
	output reg BLOCK_RES,                   //
	output reg _RESET,                      //
	output reg AOUT_RESET,                  //
	output reg BLOCK_HOLD,                  //
	output reg POLARITY                    //
	// -------------------------------------//
	);
	// State machine (SM) states ---------------------------------//
	localparam SM_INITIALIZE = 5'd0;                              //
	localparam SM_WAITING_FOR_RUN_SIGNAL = 5'd1;                  //
	localparam SM_MEASURE = 5'd2;                                 //
	localparam SM_FINALIZE = 5'd3;                                //
	reg [4:0]current_state;                                       //
	reg [4:0]previous_state;                                      //
	wire state_did_not_change = previous_state == current_state;  //
	// -----------------------------------------------------------//
	
	reg [9:0]current_state_time_count; // This counts the number of clock cycles that the state machine has been in the "current_state" state. Each time the state changes, this will be reseted to 0.
	
	assign ready_flag = (current_state == SM_WAITING_FOR_RUN_SIGNAL);
	assign measure_flag = (current_state == SM_MEASURE);
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			current_state <= SM_INITIALIZE;
			previous_state <= SM_INITIALIZE;
			current_state_time_count <= 9'd0;
			end
		else begin // if NOT reset
			if (state_did_not_change) begin
				current_state_time_count <= current_state_time_count + 9'd1; 
				end
			else begin
				previous_state <= current_state;
				current_state_time_count <= 9'd0; 
				end
			case (current_state) // State machine machinery ---
				SM_INITIALIZE: begin // Things to do before the system is ready to trigger.
					SEL <= SEL_input;
					BLOCK_RES <= BLOCK_RES_input;
					BLOCK_HOLD <= BLOCK_HOLD_input;
					POLARITY <= POLARITY_input;
					ENA <= 1'b1;
					AOUT_RESET <= 1'b0;
					_RESET <= 1'b0;
					if (current_state_time_count == 9'd20) current_state <= SM_WAITING_FOR_RUN_SIGNAL; // After this time, we move to the next state. This delay is to ensure the structure was already fully reset.
					end
				SM_WAITING_FOR_RUN_SIGNAL: begin
					if (run_sequencer) current_state <= SM_MEASURE; 
					end
				SM_MEASURE: begin // Whatever has to be done to measure, should be done here.
					if (current_state_time_count == RESET_release_time) _RESET <= 1'b1;
					if (current_state_time_count == AOUT_RESET_release_time) AOUT_RESET <= 1'b1;
					if (current_state_time_count == measure_time) current_state <= SM_FINALIZE;
					end
				SM_FINALIZE: // Things to do after the measurement has been done.
					current_state <= SM_INITIALIZE;
				endcase
			end // else
		end // always
	endmodule
