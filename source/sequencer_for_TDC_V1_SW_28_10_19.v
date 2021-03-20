`timescale 1ns/1ps

module sequencer_for_TDC_V1_SW_28_10_19 (
	//-------------------------------------------------------------------//
	// This is the sequencer module to interface with the test structure //
	// that I am calling "TDC_V1_SW_28_10_19" which is the one produced  //
	// by S. Widerkehr that contains 4 TDC test structures.              //
	//-------------------------------------------------------------------//
	input clk,
	input reset,

	input run_sequencer, // Setting this to 1 starts the sequencer.
	input [7:0]t_start_coarse,
	input [7:0]t_stop_coarse,

	output ready_flag, // 1 means that the sequencer is ready to start a new run, 0 means it is not.
	output reg measure_flag, // This is what Beat called "measure".
	output reg write, // This tells the RAM memory when to write.
	output reg[15:0]data, // This sends the data to the RAM memory.

	// TDC_V1_SW_28_10_19 test structure ---//
	output reg [3:0]SEL,                    //
	output reg PSTART,                      //
	output reg PSTOP,                       //
	output reg RES,                         //
	input [6:0]DOUT,                        //
	input [20:0]SAFF                        //
	// -------------------------------------//
);
	// State machine states --------------------------------------//
	localparam SM_IDLE = 5'd0;                                    //
	localparam SM_WAIT_FOR_RUN_SIGNAL = 5'd1;                     //
	localparam SM_START_MEASURE_SEQUENCE = 5'd2;                  //
	localparam SM_MEASURE_SEQUENCE = 5'd3;                        //
	localparam SM_READOUT_SEQUENCE = 5'd4;                        //
	reg [4:0]current_state;                                       //
	reg [4:0]previous_state;                                      //
	wire state_did_not_change = previous_state == current_state;  //
	// -----------------------------------------------------------//
	
	reg [9:0]current_state_time_count; // This counts the number of clock cycles that the state machine has been in the "current_state" state. Each time the state changes, this will be reseted to 0.
	
	assign ready_flag = (current_state == SM_WAIT_FOR_RUN_SIGNAL);
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			current_state <= SM_IDLE;
			previous_state <= SM_IDLE;
			current_state_time_count <= 9'd0;
			SEL <= 4'b0000;
			PSTART <= 1'b0;
			PSTOP <= 1'b0;
			RES <= 1'b1;
			measure_flag <= 1'b0;
			write <= 1'b0; end
		else begin // if NOT reset
			if (state_did_not_change) begin
				current_state_time_count <= current_state_time_count + 9'd1; end
			else begin
				previous_state <= current_state;
				current_state_time_count <= 9'd0; end
			case (current_state) // State machine machinery ---
				SM_IDLE: begin
					SEL <= 4'b0000;
					PSTART <= 1'b0;
					PSTOP <= 1'b0;
					RES <= 1'b1;
					current_state <= SM_WAIT_FOR_RUN_SIGNAL; end
				SM_WAIT_FOR_RUN_SIGNAL: begin
					if (run_sequencer) current_state <= SM_START_MEASURE_SEQUENCE; end
				SM_START_MEASURE_SEQUENCE: begin
					measure_flag <= 1'b1;
					RES <= 0; // Remove the "reset" signal from the test structure.
					current_state <= SM_MEASURE_SEQUENCE; end
				SM_MEASURE_SEQUENCE: begin
					if (current_state_time_count[7:0] == t_start_coarse) PSTART <= 1;
					if (current_state_time_count[7:0] == t_stop_coarse) PSTOP <= 1; 
					if (current_state_time_count[8]) begin // Finish the measure sequence.
						current_state <= SM_READOUT_SEQUENCE;
						measure_flag <= 1'b0; end/*if*/ end/*SM_MEASURE_SEQUENCE*/
				SM_READOUT_SEQUENCE: begin: readout_mechanism
					reg [2:0]write_counter; // This counter is used to write the many bytes from each TDC into the memory.
					if (SEL == 4'b0000) begin
						SEL <= 4'b0001;
						write_counter <= 3'b000; end
					else begin
						write_counter <= write_counter + 3'd1;
						case (write_counter)
							3'd0: begin
								write <= 1'b1; // This will tell the RAM block in the base board to write the data.
								data[15:0] <= {DOUT[6:0], 4'd0, SAFF[20:16]}; end // This will be written to the RAM in the base board module.
							3'd1:
								data[15:0] <= SAFF[15:0]; // This will be written to the RAM in teh base board module.
							3'd2: begin
								write <= 1'b0; // Tell the RAM to not write anymore.
								SEL <= {SEL<<1}; // Move to the next TDC structure.
								write_counter <= 3'd0; // Reset the write counter so for the next TDC structure we repeat the cycle again.
								if (SEL == 4'b1000) // If we are in the last test structure...
									current_state <= SM_IDLE; end // When the last TDC was read, we have finished.
							endcase
						end
					end
				endcase
			end
		end
	endmodule
