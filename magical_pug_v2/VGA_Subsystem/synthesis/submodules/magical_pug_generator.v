
//------------------------------------------------------------------------------
//                                                                            
//               Magical PUG Game Design Prototype                  
//                                                                            
//--------------------------------------------------------------------------------
// 
// @file magical_pug_generator.v
// @brief obstacle tackling game : 
//		controls:keys, switches
//		display: VGA monitor, 7 segment display, LEDs
// @version: 1.0 
// Date of current revision:  @date [2020-04-25]  
// Target FPGA: [Intel Altera DE1- Cyclone V] 
// Tools used: [Quartus Prime 18.1] for editing and synthesis 
//             
//  Functional Description:  This file contains the game logic for magical_pug.
//							It involves editing display, executing commands on keys and switch inputs 
//  
//  Designed for: [PLESD Course Project 3 Module 4]
//               
//
//  Designed by:  @author [Deepesh Sonigra] 
//                [University of Colorado Boulder]
//                [deepesh.sonigra@colorado.edu] 
// 				
//				 @author [Om Raheja] 
//                [University of Colorado Boulder]
//                [om.raheja@colorado.edu]
//	
//	Reference :
//
//------------------------------------------------------------------------------

/**
		Module Magical pug generator: contains interfaces for the game
**/
	module magical_pug_generator (
		// Inputs
		clk,  			// clock
		reset, 			// reset 
		ready,			// ready state for the display
		keys,			// the key inputs for the game
		// Outputs
		data,			// Display data containing 24 bits of color
		startofpacket,  // start of packet
		endofpacket,	// end of packet
		empty,			
		score,			// contains the score: no of pipes passed
		valid,			// if the data is valid
		switch,			// switch input to change level
		digit_0,		// digit 0 for 7 segment display
		digit_1,		// digit 1 for 7 segment display
		digit_2			// digit 2 for 7 segment display
	);

	/*****************************************************************************
	 *                           Parameter Declarations                          *
	 *****************************************************************************/

	// data Width parameters
	parameter DW							= 23;
	parameter WW							= 10;
	parameter HW							= 9;

	
	// The picture resolution set for the game
	parameter WIDTH						= 640;
	parameter HEIGHT					= 480;


	parameter PIPE1_X					= 200;
	parameter PIPE2_X					= 400;
	parameter PIPE3_X					= 600;
	
	// Pipe length for 3 pipes set
	
	parameter PIPE1_Y1					= 130;
	parameter PIPE1_Y2					= 270;
	
	parameter PIPE2_Y1					= 220;
	parameter PIPE2_Y2					= 380;
	
	parameter PIPE3_Y1					= 100;
	parameter PIPE3_Y2					= 285;
	
	parameter PIPE_WIDTH				= 25; 

	// Magical pug character parameters
	parameter MAGICAL_PUG_START_X		= 75;
	parameter MAGICAL_PUG_START_Y		= 200;
	parameter MAGICAL_PUG_WIDTH 		= 30;
	parameter MAGICAL_PUG_JUMP 		= 50;
	parameter PUG_FALL_RATE				= 80000;
	
	// Game speed variable
	integer GAME_SPEED;

	/*****************************************************************************
	 *                             Port Declarations                             *
	 *****************************************************************************/

	// Inputs
	input clk;
	input reset;
	input ready;
	input [3:0] keys;
	input switch;

	// Outputs
	output [9:0] score;
	output [DW: 0] data;
	output startofpacket;
	output endofpacket;
	output empty;
	output valid;
	output [6:0] digit_0;
	output [6:0] digit_1;
	output [6:0] digit_2;


	/*****************************************************************************
	 *                 Internal Wires and Registers Declarations                 *
	 *****************************************************************************/

	// Internal Wires
	reg [7: 0]	red;
	reg [7: 0]	green;
	reg [7: 0]	blue;

	// Internal Registers
	reg	[WW: 0]	x;
	reg	[HW: 0]	y;

	// Game Control
	reg start_of_game;
	reg end_of_game;
	reg reset_game;

	// Bird Position
	reg	[WW: 0]	pug_x;
	reg	[HW: 0]	pug_y;
	reg [31:0]	fall_speed_param;
	reg fall;

	// Pipe 1 Position
	reg	[WW: 0]	p1_x;
	// Pipe 2 Position
	reg	[WW: 0]	p2_x;
	// Pipe 3 Position 
	reg	[WW: 0]	p3_x;


	/*****************************************************************************
	 *                 Input control wires and registers                 *
	 *****************************************************************************/
	// Jump Key States (Key0 on board)
	wire jump_key_pressed;
	wire jump_key_released;
	wire jump_key_state;

	// Start Game Key  (Key 3 on board)
	wire start_key_pressed;
	wire start_key_released;
	wire start_key_state;

	// Reset Game key (key 2 on board)
	wire reset_key_pressed;
	wire reset_key_released;
	wire reset_key_state;

	// parameter used to change speed
	reg [31:0]	speed_param;

	/*****************************************************************************
	 *                 Output control wires and registers                 *
	 *****************************************************************************/

	 //7-Segment Display
	reg [3:0] dig0;
	reg [3:0] dig1;
	reg [3:0] dig2;

	// score display paramters
	reg [9:0] score;
	reg[6:0] digit_0;
	reg[6:0] digit_1;
	reg[6:0] digit_2;

	/*****************************************************************************
	 *               		 Clock Processing   						        *
	 *****************************************************************************/

	// running through each pixel on screen
	always @(posedge clk)
	begin
		if (reset)
			x <= 'h0;
		else if (ready)
		begin
			if (x == (WIDTH - 1))
			begin
				x <= 'h0;
				if (y == (HEIGHT - 1))
					y <= 'h0;
				else
					y <= y + 1'b1;					
			end		
			else
				x <= x + 1'b1;
		end
	end


	// Determine Game Start
	always @(posedge clk)
	begin
		if (reset) begin
			// Start Position
			start_of_game <= 0;
			reset_game <= 0;
		end
		
		else begin
		// Changing the game speed using switch0
			if(switch)
				GAME_SPEED <= 150000;
			else
				GAME_SPEED <= 250000;
				
			if (start_key_pressed) begin
				start_of_game <= 1;
			 	reset_game <= 0;
			end		
			else if (reset_key_pressed) begin
				reset_game <= 1;
				start_of_game <= 0;
			end
			else if (end_of_game) begin
				start_of_game <= 0;
			end
		end
	end


	always @(posedge clk)
	begin
		if (reset) begin
			fall <= 0;
			pug_x <= MAGICAL_PUG_START_X;
			pug_y <= MAGICAL_PUG_START_Y;
			fall_speed_param <= 0;
		end
		else begin
			if (start_of_game) begin
				
				// Jumpkey pressed
				if (jump_key_pressed) begin
					pug_y <= pug_y - MAGICAL_PUG_JUMP;
					fall <= 0;
					// error handline screen resolution
					if (pug_y < MAGICAL_PUG_JUMP ) 
						pug_y <= MAGICAL_PUG_JUMP;	
				end
				// jump key released
				else if (jump_key_released) 
					fall <= 1;
				
				else begin
					if (fall == 1) begin
						fall_speed_param <= fall_speed_param + 1;

						if (fall_speed_param > PUG_FALL_RATE) begin
							pug_y <= pug_y + 1;
							fall_speed_param <= 0;

							// Error Handling screen resolution
							if (pug_y >= (HEIGHT - MAGICAL_PUG_WIDTH)) 
								pug_y <= HEIGHT - MAGICAL_PUG_WIDTH;				
						end
					end
				end
			end
			else if (reset_game) begin
				// Start Position
				fall <= 0;
				pug_x <= MAGICAL_PUG_START_X;
				pug_y <= MAGICAL_PUG_START_Y;
				fall_speed_param <= 0;
			end	
			
			else;
		end
	end

	// move pipes
	always @(posedge clk)
	begin
		if (reset) begin
			// Start Position
			p1_x <= PIPE1_X;
			p2_x <= PIPE2_X;
			p3_x <= PIPE3_X;
			speed_param <= 0;
			score <= 0;
		end
		else begin
			if (start_of_game) begin
				speed_param <= speed_param + 1;

				if (speed_param > GAME_SPEED) begin
					speed_param <= 0;
					p1_x <= p1_x - 'd1;
					p2_x <= p2_x - 'd1;
					p3_x <= p3_x - 'd1;

					if (p1_x <= 10) begin
						p1_x <= 'd640;
						score = score + 1;
					end

					else if (p2_x <= 10) begin
						p2_x <= 'd640;
						score = score + 1;
					end
					
					else if (p3_x <= 10) begin
						p3_x <= 'd640;
						score = score + 1;
					end
					else;
				end
			end		
			else if (reset_game) begin
				// Start Position
				p1_x <= PIPE1_X;
				p2_x <= PIPE2_X;
				p3_x <=PIPE3_X;
				speed_param <= 0;
				score <= 0;
			end
		end
	end


	// Animation
	always @(posedge clk)
	begin
		// Get Score
		dig2 <= score / 100;
		dig1 <= (score / 10) % 10;
		dig0 <= (score % 10);		

		// Faux Display Segments Boolean Termsreg dig0_a_segment;

		case (dig0)
			0: digit_0 <= 7'b1000000;
			1: digit_0 <= 7'b1111001;
			2: digit_0 <= 7'b0100100;
			3: digit_0 <= 7'b0110000;
			4: digit_0 <= 7'b0011001;
			5: digit_0 <= 7'b0010010;
			6: digit_0 <= 7'b0000010;
			7: digit_0 <= 7'b1111000;
			8: digit_0 <= 7'b0000000;
			9: digit_0 <= 7'b0010000;
			default: digit_0 <= 0;
		endcase	

		case (dig1)
			0: digit_1 <= 7'b1000000;
			1: digit_1 <= 7'b1111001;
			2: digit_1 <= 7'b0100100;
			3: digit_1 <= 7'b0110000;
			4: digit_1 <= 7'b0011001;
			5: digit_1 <= 7'b0010010;
			6: digit_1 <= 7'b0000010;
			7: digit_1 <= 7'b1111000;
			8: digit_1 <= 7'b0000000;
			9: digit_1 <= 7'b0010000;
			default: digit_1 <= 0;
		endcase	

		case (dig2)
			0: digit_2 <= 7'b1000000;
			1: digit_2 <= 7'b1111001;
			2: digit_2 <= 7'b0100100;
			3: digit_2 <= 7'b0110000;
			4: digit_2 <= 7'b0011001;
			5: digit_2 <= 7'b0010010;
			6: digit_2 <= 7'b0000010;
			7: digit_2 <= 7'b1111000;
			8: digit_2 <= 7'b0000000;
			9: digit_2 <= 7'b0010000;
			default: digit_2 <= 0;
		endcase

		
		
		// Pug dimensations
		if ( ((x >= pug_x) && (x < (pug_x + MAGICAL_PUG_WIDTH))) && ((y >= pug_y) && (y < (pug_y + MAGICAL_PUG_WIDTH))) ) begin
			red <= 8'd222;
			blue <= 8'd135;
			green <= 8'd184;
		end
			
		
		// Pipe 1 top
		else if ( ((x > p1_x) && (x < (p1_x + PIPE_WIDTH))) && (y <  PIPE1_Y1)) begin
			
			if(y < 40)	begin
				green <= 8'd255;
				red <= 8'd255;
				blue <= 8'd255;
			end
			else if ((y > 40) && (y < 80)) begin
				green <= 8'd0;
				red <= 8'd255;
				blue <= 8'd0;
			end
			else begin
				green <= 8'd255;
				red <= 8'd255;
				blue <= 8'd255;
			end
			
		end
		
		// Pipe 1 bottom
		else if ( ((x > p1_x) && (x < (p1_x + PIPE_WIDTH))) && (y > PIPE1_Y2) ) begin
			if(y < 330) begin
				green <= 8'd255;
				red <= 8'd255;
				blue <= 8'd255;
			end
			else if ( y < 400)begin
				green <= 8'd0;
				red <= 8'd255;
				blue <= 8'd0;
			end
			else begin
				green <= 8'd255;
				red <= 8'd255;
				blue <= 8'd255;
			end
		end
		
		 
		// Pipe 2 top
		else if ( ((x > p2_x) && (x < (p2_x + 25))) && (y < PIPE2_Y1) ) begin
			if(y < 70)	begin
				green <= 8'd255;
				red <= 8'd255;
				blue <= 8'd255;
			end
			else if ((y > 70) && (y < 140)) begin
				green <= 8'd0;
				red <= 8'd255;
				blue <= 8'd0;
			end
			else begin
				green <= 8'd255;
				red <= 8'd255;
				blue <= 8'd255;
			end
		end
		
		
		//  Pipe 2 bottom
		else if ( ((x > p2_x) && (x < (p2_x + 25))) && (y > PIPE2_Y2) ) begin
			if(y < 430) begin
				green <= 8'd255;
				red <= 8'd255;
				blue <= 8'd255;
			end
			else begin
				green <= 8'd0;
				red <= 8'd255;
				blue <= 8'd0;
			end

		end
		

		// Pipe 3 top
		else if ( ((x > p3_x) && (x < (p3_x + 25))) && (y < PIPE3_Y1) ) begin
			if(y < 50)	begin
				green <= 8'd255;
				red <= 8'd255;
				blue <= 8'd255;
			end
			else  begin
				green <= 8'd0;
				red <= 8'd255;
				blue <= 8'd0;
			end
			
		end


		//Pipe 3 bottom
		else if ( ((x > p3_x) && (x < (p3_x + PIPE_WIDTH))) && (y > PIPE3_Y2) ) begin

			if(y < 350)	begin
				green <= 8'd255;
				red <= 8'd255;
				blue <= 8'd255;
			end
			else if (y < 420) begin
				green <= 8'd0;
				red <= 8'd255;
				blue <= 8'd0;
			end
			else begin
				green <= 8'd255;
				red <= 8'd255;
				blue <= 8'd255;
			end
		end
		
	
	// rest of the picture(sky color)	
		else begin
			red <= 8'd179;
			green <= 8'd242;
			blue <= 8'd255;
		end
	end

	//Collision Logic comparing pug xy coordinates with Pipes
	always @(posedge clk)
	begin
		if (reset) 
			end_of_game <= 0;
		
		else if (start_of_game) begin
			if ( (p1_x > (MAGICAL_PUG_START_X - PIPE_WIDTH)) && (p1_x < (MAGICAL_PUG_START_X + MAGICAL_PUG_WIDTH)) ) begin
				if (pug_y <= PIPE1_Y1 || (pug_y + MAGICAL_PUG_WIDTH) >= PIPE1_Y2 ) 
					end_of_game <= 1;
				else 
					end_of_game <= 0;	
			end
		
			else if( (p2_x > (MAGICAL_PUG_START_X - PIPE_WIDTH)) && (p2_x < (MAGICAL_PUG_START_X + MAGICAL_PUG_WIDTH)) ) begin
				if (pug_y <= PIPE2_Y1 || (pug_y + MAGICAL_PUG_WIDTH) >= PIPE2_Y2 ) 
					end_of_game <= 1;
				else 
					end_of_game <= 0;			
			end
		
			else if( (p3_x > (MAGICAL_PUG_START_X - PIPE_WIDTH)) && (p3_x < (MAGICAL_PUG_START_X + MAGICAL_PUG_WIDTH)) ) begin
				if (pug_y <= PIPE3_Y1 || (pug_y + MAGICAL_PUG_WIDTH) >= PIPE3_Y2 ) 
					end_of_game <= 1;
				else 
					end_of_game <= 0;	
			end
			else;
		end
		
		else if (reset_game) 
			end_of_game <= 0;
		
		else;
		
	end

	/*****************************************************************************
	 *                            Combinational Logic                            *
	 *****************************************************************************/

	// Output Assignments

	assign data				= {red, green, blue};
	assign startofpacket	= (x == 0) & (y == 0);
	assign endofpacket		= (x == (WIDTH - 1)) & (y == (HEIGHT - 1));
	assign empty			= 1'b0;
	assign valid			= 1'b1;
	

	/*****************************************************************************
	 *                              Internal Modules                             *
	 *****************************************************************************/

		key_debouncer key0 (
			.clk (clk),
			.button (keys[0]),
			.button_state (jump_key_state),
			.pressed (jump_key_pressed),
			.released (jump_key_released)
		);

		key_debouncer key2 (
			.clk (clk),
			.button (keys[2]),
			.button_state (reset_key_state),
			.pressed (reset_key_pressed),
			.released (reset_key_released)
		);

		key_debouncer key3 (
			.clk (clk),
			.button (keys[3]),
			.button_state (start_key_state),
			.pressed (start_key_pressed),
			.released (start_key_released)
		);

	endmodule
