`timescale 1ns / 1ns

module vga_feeder #(
	parameter RESOLUTION = "HD" // FULL_HD - HD - VGA - SVGA
)(
    input 					clk,
	input 					reset_i,
    input 					sw_i,

    input 					eof_event_i,
    input [12-1 : 0] 		column_i,
    input [12-1 : 0] 		row_i,
    output [12-1 : 0]     	pix_data_o,
	
	input signed [16-1 : 0]	datax_i,
	input signed [16-1 : 0]	datay_i
);
	
	localparam WIDTH  			= (RESOLUTION == "FULL_HD") ? 1920 : ((RESOLUTION == "HD") ? 1280 : ((RESOLUTION == "VGA") ? 640 : 800 )) ;
	localparam HEIGHT  			= (RESOLUTION == "FULL_HD") ? 1080 : ((RESOLUTION == "HD") ? 720  : ((RESOLUTION == "VGA") ? 480 : 600 )) ;
	localparam REFRESH_RATE		= 60;
	localparam CIRCLE_RADIUS 	= 20;
	localparam LINE_SIZE 		= 1;

	reg [8 - 1 : 0] 		frame_counter;
	reg [12-1 : 0]  		circle_and_lines;
	reg [12-1 : 0]  		blank_screen;
	
	reg [32-1 : 0] 			center_x;
	reg [32-1 : 0] 			center_y;
	
	reg signed [16-1 : 0] 	datax_buf;
	reg signed [16-1 : 0] 	datay_buf;
	
	
	//	Assign the circle center based on the received inclination data
	always @(*) begin
		if(WIDTH/2 - datax_buf < CIRCLE_RADIUS)
			center_x <= CIRCLE_RADIUS;
		else if(WIDTH/2 - datax_buf > WIDTH - CIRCLE_RADIUS)
			center_x <= WIDTH - CIRCLE_RADIUS;
		else 
			center_x <= WIDTH/2 - datax_buf;
	end
	
	always @(*) begin
		if(HEIGHT/2 + datay_buf < CIRCLE_RADIUS)
			center_y <= CIRCLE_RADIUS;
		else if(HEIGHT/2 + datay_buf > HEIGHT - CIRCLE_RADIUS)
			center_y <= HEIGHT - CIRCLE_RADIUS;
		else 
			center_y <= HEIGHT/2 + datay_buf;
	end

	// pix_data_o selector - based on sw_i
	assign pix_data_o = sw_i ? blank_screen : circle_and_lines;

	
	// circle_and_lines - draws a horizontal line, vertical line, and a circle in the middle
	// Drawing z-order is top -> down
	always @(*) begin
		if (((row_i - center_y) ** 2) + ((column_i - center_x) ** 2) < (CIRCLE_RADIUS ** 2))	// Circle
			circle_and_lines <= {4'hF, 4'hF, 4'hF};	// white
		else if (((column_i > WIDTH / 2 - LINE_SIZE) & (column_i < WIDTH / 2 + LINE_SIZE)) |	// Vertical line
			((row_i > HEIGHT / 2 - LINE_SIZE) 	& (row_i < HEIGHT / 2 + LINE_SIZE)) )			// Horizontal line
			circle_and_lines <= {4'hA, 4'hA, 4'hA}; // near white
		else
			circle_and_lines <= {4'h3, 4'h3, 4'h3};	// gray
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
	
	// Synchronises the input signals to the end of a frame
	always @(posedge clk or posedge reset_i) begin
		if(reset_i) begin
			datax_buf <= {16{1'b0}};
			datay_buf <= {16{1'b0}};
		end else if(eof_event_i) begin
			datax_buf <= datax_i;
			datay_buf <= datay_i;
		end
	end

endmodule
