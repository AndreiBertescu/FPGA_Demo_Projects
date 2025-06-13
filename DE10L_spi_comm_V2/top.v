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
	
	output 				GSENSOR_CS_N,
	output 				GSENSOR_SCLK,
	inout  				GSENSOR_SDI
);

	localparam [8-1 : 0] HEX_BALL_LO = 8'b10100011;
	localparam [8-1 : 0] HEX_BALL_HI = 8'b10011100;
	
	wire 		clk;
	wire 		spi_clk;
	wire 		reset;
		
	wire        req;		
	wire        is_read_op;		
	wire [5:0] 	addr;	
	wire [7:0] 	wr_data;
	
	wire		ack;			
	wire [7:0] 	rd_data;	
	
	wire signed [16-1 : 0] datax;
	wire signed [8-1 : 0] datay;
		
	
	// Clock generator IP
	clk_wiz clk_wiz_0(
		.areset		(~KEY[0]		),
		.inclk0		(MAX10_CLK1_50 	),
		.c0			(clk			),	// 2MHz
		.c1			(spi_clk		),	// 2MHz - 220 deg offset
		.locked		(locked			)
	);
	
	
	// SPI to req_ack converter
	spi_sequencer #(
		.TP			(1			)
	) spi_sequencer_inst (
		.reset_i	(~locked   	),
		.clk_i		(clk		),  	
		.enable_i   (SW[0]		),

		// Req-ack interface
		.req_o		(req		),			
		.is_read_op (is_read_op ),  	
		.addr_o		(addr		),		
		.wr_data_o	(wr_data	),		
		
		.ack_i		(ack		),			
		.rd_data_i	(rd_data	),
		
		// Output
		.data_X_o   (datax  	),
		.data_Y_o   (datay		)
	);
	
	
	//assign is_read_op = SW[9];
	
	// SPI to req_ack converter
	spi_block_V1 #(
		.TP			(1			)
	) spi_block_V1_inst (
		.reset_i	(~locked   	),
		.clk_i		(clk		),  		
		.spi_clk_i	(spi_clk	),  	

		// Req-ack interface
		.req_i		(req		),			
		.is_read_op (is_read_op ),  	
		.addr_i		(addr		),		
		.wr_data_i	(wr_data	),		
		
		.ack_o		(ack		),			
		.rd_data_o	(rd_data	),		

		// SPI interface
		.spi_cs_o	(GSENSOR_CS_N	),
		.spi_clk_o	(GSENSOR_SCLK	),
		.spi_data_io(GSENSOR_SDI	),
	);
	
	
	// Assign received values to 7-segment displays
	assign HEX0 = (datax <= -180				) ? ((datay > 0) ? HEX_BALL_LO : HEX_BALL_HI) : 8'hff;
	assign HEX1 = (datax > -180 & datax <= -80	) ? ((datay > 0) ? HEX_BALL_LO : HEX_BALL_HI) : 8'hff;
	assign HEX2 = (datax > -80 & datax <= 0		) ? ((datay > 0) ? HEX_BALL_LO : HEX_BALL_HI) : 8'hff;
	assign HEX3 = (datax > 0   & datax <= 80 	) ? ((datay > 0) ? HEX_BALL_LO : HEX_BALL_HI) : 8'hff;
	assign HEX4 = (datax > 80  & datax <= 180 	) ? ((datay > 0) ? HEX_BALL_LO : HEX_BALL_HI) : 8'hff;
	assign HEX5 = (datax > 180				 	) ? ((datay > 0) ? HEX_BALL_LO : HEX_BALL_HI) : 8'hff;
	assign LEDR = {2'b10, datay};

endmodule
