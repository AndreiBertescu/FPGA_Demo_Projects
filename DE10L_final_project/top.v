`timescale 1ns / 1ns

module top(
	input       		MAX10_CLK1_50,
	
	output [9:0]    	LEDR,
	input [9:0]			SW,
	input [1:0]			KEY,
	
	output [7:0]		HEX0,
	output [7:0]		HEX1,
	output [7:0]		HEX2,
	output [7:0]		HEX3,
	output [7:0]		HEX4,
	output [7:0]		HEX5,
	
	output				VGA_HS,
	output				VGA_VS, 
	output [4-1 : 0]	VGA_R,
	output [4-1 : 0]	VGA_G,
	output [4-1 : 0]	VGA_B,
	
	output 				GSENSOR_CS_N,
	output 				GSENSOR_SCLK,
	output 				GSENSOR_SDO,
	inout  				GSENSOR_SDI
);

	localparam 		TP 	 	 = 1;
	localparam 		IN_FREQ  = 25_000_000;

	wire 			clk;
	wire 			locked;
	reg [2 : 0] 	reset_FF;
	wire 			reset;
	
	wire 			vga_eof;		
	wire [12-1 : 0] vga_col;		
	wire [12-1 : 0] vga_row;		
	wire [12-1 : 0] vga_pix_data;
	
	wire signed [16-1 : 0] datax;
	wire signed [16-1 : 0] datay;
	wire [8-1 : 0] 		   devid;
	assign LEDR = {2'b00, devid};
	
	
	// Clock generator IP
	clk_wiz clk_wiz_0(
		.areset		(~KEY[0]		),
		.inclk0		(MAX10_CLK1_50 	),
		.c0			(clk			),	// 25MHz for VGA
		.locked		(locked			)
	);
	
	// Reset structure - ensures reset deasertion is synchronized
	always @(posedge clk or negedge locked) begin
		if (~locked) begin
			reset_FF <= #TP 3'h7;
		end else begin
			reset_FF <= #TP {reset_FF[1:0], 1'b0};
		end
	end
	assign reset = reset_FF[2];
	
	
	// VGA driver
	vga_driver #(
		.RESOLUTION("VGA")   // FULL_HD - HD - VGA - SVGA
	) vga_driver_inst (
		.clk			(clk					),
		.reset_i		(reset					),
		
		// Internal interface
		.eof_event_o	(vga_eof				),
		.column_o		(vga_col				),
		.row_o			(vga_row				),
		.pix_data_o		(vga_pix_data			),
		
		// VGA interface       
		.vga_h_sync_o	(VGA_HS					),                    
		.vga_v_sync_o	(VGA_VS					),
		.vga_data_o		({VGA_R, VGA_G, VGA_B}	)    
	);
	
	
	// VGA feeder - converts input data to pixel data to be sent to the VGA driver
	vga_feeder #(
		.RESOLUTION("VGA")   // FULL_HD - HD - VGA - SVGA
	) vga_feeder_inst (
		.clk			(clk			),
		.reset_i		(reset			),
		.sw_i			(SW[0]			),
		
		.eof_event_i	(vga_eof		),
		.column_i		(vga_col		),
		.row_i			(vga_row		),
		.pix_data_o		(vga_pix_data	),
		
		.datax_i		(datax			),
		.datay_i		(datay			)
	);
	
	
	// SPI wrapper - automatically gets the orientation data from the accelerometer
	spi_wrapper #(
		.TP				(1				),
		.IN_FREQ		(IN_FREQ		),
		.SAMPLE_FREQ	(50				)
	) spi_wrapper_inst (
		.clk			(clk			),
		.reset_i		(reset			),
		.SW				(SW[2]			),
		
		.GSENSOR_CS_N	(GSENSOR_CS_N	),
		.GSENSOR_SCLK	(GSENSOR_SCLK	),
		.GSENSOR_SDO	(GSENSOR_SDO	),
		.GSENSOR_SDI	(GSENSOR_SDI	),
		
		.datax_o		(datax			),
		.datay_o		(datay			),
		.devid_o		(devid  		)
	);
	
	 
	// 7-segment displays pattern generator
	hex_wrapper #(
		.IN_FREQ	(IN_FREQ)
	) hex_wrapper_inst (
		.clk		(clk	),
		.reset_i	(reset	),
		.SW			(SW[1]	),
		
		.HEX0		(HEX0	),
		.HEX1		(HEX1	),
		.HEX2		(HEX2	),
		.HEX3		(HEX3	),
		.HEX4		(HEX4	),
		.HEX5       (HEX5	),
		
		.datax_i	(datax	),
		.datay_i	(datay	)
	);

endmodule
