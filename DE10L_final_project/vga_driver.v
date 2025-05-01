`timescale 1ns / 1ns

module vga_driver #(
	parameter RESOLUTION = "HD" // FULL_HD - HD - VGA - SVGA
)(
	input              clk,
	input              reset_i,
							
	// Internal interface 
	output 					eof_event_o,
	output reg [12-1 : 0]  	column_o,
	output reg [12-1 : 0]  	row_o,
	input [12-1 : 0] 		pix_data_o,

	//VGA interface                           
	output reg              vga_h_sync_o,
	output reg              vga_v_sync_o,
	output reg [12-1 : 0] 	vga_data_o 
);

	localparam H_VISIBLE  = (RESOLUTION == "FULL_HD") ? 1920 : ((RESOLUTION == "HD") ? 1280 : ((RESOLUTION == "VGA") ? 640 : 800 )) ;
	localparam H_FPORCH   = (RESOLUTION == "FULL_HD") ? 88   : ((RESOLUTION == "HD") ? 72   : ((RESOLUTION == "VGA") ? 16  : 40  )) ;
	localparam H_SYNC     = (RESOLUTION == "FULL_HD") ? 44   : ((RESOLUTION == "HD") ? 80   : ((RESOLUTION == "VGA") ? 96  : 128 )) ;
	localparam H_BPORCH   = (RESOLUTION == "FULL_HD") ? 148  : ((RESOLUTION == "HD") ? 216  : ((RESOLUTION == "VGA") ? 48  : 88  )) ;
																							
	localparam V_VISIBLE  = (RESOLUTION == "FULL_HD") ? 1080 : ((RESOLUTION == "HD") ? 720  : ((RESOLUTION == "VGA") ? 480 : 600 )) ;
	localparam V_FPORCH   = (RESOLUTION == "FULL_HD") ? 4    : ((RESOLUTION == "HD") ? 3    : ((RESOLUTION == "VGA") ? 10  : 1   )) ;
	localparam V_SYNC     = (RESOLUTION == "FULL_HD") ? 5    : ((RESOLUTION == "HD") ? 5    : ((RESOLUTION == "VGA") ? 2   : 4   )) ;
	localparam V_BPORCH   = (RESOLUTION == "FULL_HD") ? 36   : ((RESOLUTION == "HD") ? 22   : ((RESOLUTION == "VGA") ? 33  : 23  )) ;
		
	reg [12-1 : 0] pixel_counter;
	reg [12-1 : 0] line_counter;
	
	wire eol_event;
	wire h_visible;
	wire v_visible;  
	wire visible;
	         
	assign eol_event   = (pixel_counter == (H_SYNC + H_BPORCH + H_VISIBLE + H_FPORCH- 1 ));
	assign eof_event_o = (line_counter  == (V_SYNC + V_BPORCH + V_VISIBLE + V_FPORCH- 1 )) & eol_event;
	assign h_visible   = (pixel_counter > (H_SYNC + H_BPORCH - 4)) & ((pixel_counter < (H_SYNC + H_BPORCH + H_VISIBLE-3)));
	assign v_visible   = (line_counter  > (V_SYNC + V_BPORCH - 1)) & ((line_counter  < (V_SYNC + V_BPORCH + V_VISIBLE)));
	assign visible     = h_visible & v_visible;


	// Vertical counter
	always @(posedge clk or posedge reset_i) begin
		if (reset_i)                   
			pixel_counter <=  {12{1'b0}};                    
		else if (eol_event) 
			pixel_counter <=  {12{1'b0}}; 
		else
			pixel_counter <=  pixel_counter + 1;
	end

	// Horizontal counter
	always @(posedge clk or posedge reset_i) begin    
		if (reset_i)                  
			line_counter <=  {12{1'b0}}; 
		else if (eof_event_o) 
			line_counter <=  {12{1'b0}}; 
		else
			line_counter <=  line_counter + eol_event;
    end


	// Horizontal sync
	always @(posedge clk or posedge reset_i) begin                                           
		if (reset_i)                   
			vga_h_sync_o <=  1'b0; 
		else if (eol_event)  
			vga_h_sync_o <=  1'b0; 
		else if (pixel_counter == (H_SYNC-1))    
			vga_h_sync_o <=  1'd1; 
	end

	// Vertical sync
	always @(posedge clk or posedge reset_i ) begin                                           
	if (reset_i)                   
		vga_v_sync_o <=  1'b0; 
	else if (eof_event_o)  
		vga_v_sync_o <=  1'b0; 
	else if (line_counter == (V_SYNC-1) )    
		vga_v_sync_o <=  eol_event; 
	end
	
	
	// Sampled one cycle after visible
	always @(posedge clk or posedge reset_i) begin                                      
		if (reset_i) 
			vga_data_o <= 'd0;                         
		else if (visible) 
			vga_data_o <= pix_data_o; 
		else 
			vga_data_o <= 'd0;
	end


	// column_o generator - tells the 'outside' which pixel is being drawn
	always @(posedge clk or posedge reset_i) begin                                           
		if (reset_i) 
			column_o <= {12{1'd0}};  
		else
			column_o <= pixel_counter - (H_SYNC + H_BPORCH - 4) - 1 ;
	end
	
	// row_o generator
	always @(posedge clk or posedge reset_i) begin                                           
		if (reset_i) 
			row_o <= {12{1'd0}}; 
		else 
			row_o <= line_counter  - (V_SYNC + V_BPORCH - 1) - 1 ;
	end

endmodule