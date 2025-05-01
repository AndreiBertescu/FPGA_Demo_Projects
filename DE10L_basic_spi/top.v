`timescale 1ns / 1ns

module top(
	input       		MAX10_CLK1_50,
	
	output reg [9:0]    LEDR,
	input [9:0]			SW,
	input [1:0]			KEY,
	
	output 				GSENSOR_CS_N,
	output 				GSENSOR_SCLK,
	inout  				GSENSOR_SDI
);

	wire 		clk;
	wire 		spi_clk;
	wire 		reset;
		
	wire		ack_o;		
	reg			ack;		
	wire [7:0] 	rd_data_o;
	
	reg 		key_d;
	wire        req_i;		
	wire        is_read_op;		
	wire [5:0] 	addr_i;	
	wire [7:0] 	wr_data_i;
	reg [7:0]	data;
	
	assign req_i 		= ~key_d & KEY[1];	// negedge detector
	assign is_read_op 	= SW[9];
	assign addr_i 		= SW[8:3];
		
	
	// Clock generator IP
	clk_wiz clk_wiz_0(
		.areset		(~KEY[0]		),
		.inclk0		(MAX10_CLK1_50 	),
		.c0			(clk			),	// 2MHz
		.c1			(spi_clk		),	// 2MHz - 220 deg offset
		.locked		(locked			)
	);
	
	assign reset = ~locked;
	
	
	// LEDs asignment with received data from spi
	always @(posedge clk or posedge reset) begin
		if(reset)
			LEDR <= {10{1'b0}};
		else if(ack_o)
			LEDR <= {2'b00, rd_data_o};
	end
	
	// button delay
	always @(posedge clk) begin
		key_d <= KEY[1];
	end
	
	// SPI to req_ack converter
	spi_block_V1 #(
		.TP			(1			)
	) spi_block_V1_inst (
		.reset_i	(reset   	),
		.clk_i		(clk		),  		
		.spi_clk_i	(spi_clk	),  	

		// Req-ack interface
		.req_i		(req_i		),			
		.is_read_op (is_read_op ),  	
		.addr_i		(addr_i		),		
		.wr_data_i	(8'd0		),		
		
		.ack_o		(ack_o		),			
		.rd_data_o	(rd_data_o	),		

		// SPI interface
		.spi_cs_o	(GSENSOR_CS_N	),
		.spi_clk_o	(GSENSOR_SCLK	),
		.spi_data_io(GSENSOR_SDI	),
	);

endmodule
