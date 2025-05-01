`timescale 1ns / 1ns

module vga_feeder (
    input 					clk,
	input 					reset_i,
    input 					sw_i,

    input 					eof_event_i,
    input [12-1 : 0] 		column_i,
    input [12-1 : 0] 		row_i,
    output reg [12-1 : 0] 	pix_data_o
);

	localparam REFRESH_RATE		= 60;
	localparam WIDTH 			= 640;
	localparam HEIGHT 			= 480;
	localparam CIRCLE_RADIUS 	= 50;
	localparam LINE_SIZE 		= 3;

	reg [8 - 1 : 0] frame_counter;
	reg [12-1 : 0]  circle_and_lines;
	reg [12-1 : 0]  blank_screen;


	// pix_data_o selector - based on sw_i
	always @(*) begin
		if(sw_i)
			pix_data_o <= blank_screen;
		else
			pix_data_o <= circle_and_lines;
	end
	
	
	// circle_and_lines - draws a horizontal line, vertical line, and a circle in the middle
	// Drawing z-order is top -> down
	always @(*) begin
		if (((row_i - HEIGHT / 2) ** 2) + ((column_i - WIDTH / 2) ** 2) < (CIRCLE_RADIUS ** 2))	// Circle
			circle_and_lines <= {4'hF, 4'hF, 4'h0};
		else if (((column_i > WIDTH / 2 - LINE_SIZE) & (column_i < WIDTH / 2 + LINE_SIZE)) |	// Vertical line
			((row_i > HEIGHT / 2 - LINE_SIZE) 	& (row_i < HEIGHT / 2 + LINE_SIZE)) )			// Horizontal line
			circle_and_lines <= {4'hF, 4'hF, 4'hF};
		else
			circle_and_lines <= {4'h0, 4'h0, 4'hF};
	end
	
	
	// blank_screen selector - based on sw_i
	always @(*) begin
		if(frame_counter < 30)
			blank_screen <= {4'h0, 4'h0, 4'hF};
		else if(frame_counter < 60)
			blank_screen <= {4'h0, 4'hF, 4'h0};
		else if(frame_counter < 90)
			blank_screen <= {4'hF, 4'h0, 4'h0};
		else
			blank_screen <= {4'hF, 4'hF, 4'hF};
	end
	
	
	// Counter to keep track of no. of frames that passed
	always @(posedge clk or posedge reset_i) begin
		if(reset_i)
		  frame_counter <= {8{1'b0}};
		else if(frame_counter == 120)
		  frame_counter <= {8{1'b0}};
		else if(eof_event_i)
		  frame_counter <= frame_counter + 1;
	end

endmodule
