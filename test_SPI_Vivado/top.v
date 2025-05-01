module top(
	input       		MAX10_CLK1_50
	
	output reg [9:0]    LEDR,
	input [9:0]			SW,
	
	output reg [7:0]	HEX0,
	output reg [7:0]	HEX1,
	output reg [7:0]	HEX2,
	output reg [7:0]	HEX3,
	output reg [7:0]	HEX4,
	output reg [7:0]	HEX5,
	
	output 				GSENSOR_CS_N,
	output 				GSENSOR_SCLK,
	input  				GSENSOR_SDI,
	output 				GSENSOR_SDO
);
	
	localparam TP = 1;
	localparam [8-1 : 0] HEX_BALL_LO = 8'b01011100;
	localparam [8-1 : 0] HEX_BALL_HI = 8'b01100011;

	wire 			clk;
	wire 			spi_clk;
	reg [2 : 0] 	reset_FF;
	wire 			reset;
		
	wire		ack_o;		
	wire [7:0] 	rd_data_o;
	
	reg 		key_d;
	wire        req_i;		
	wire        is_read_op;		
	wire  [5:0] addr_i;	
	wire  [7:0] wr_data_i;
	
	assign req_i = key_d & ~KEY[1];	// negedge detector
	assign is_read_op = 1'b1;
	assign addr_i = 5'h00;			// DEVID register
	assign wr_data_i = 8'h00;
		
	
	// Clock generator IP
	clk_wiz clk_wiz_0(
		.areset		(KEY[0]			),
		.inclk0		(MAX10_CLK1_50 	),
		.c0			(clk			),
		.c1			(spi_clk		),
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
	
	
	// LEDs asignment with received data from spi
	always @(posedge clk or posedge reset) begin
		if(reset)
			LEDR <= {10{1'b0}};
		else if(ack_o)
			LEDR <= {KEY, rd_data_o};
	end
	
	// button delay
	always @(posedge clk) begin
		key_d <= KEY[1];
	end
	
	
	// SPI to req_ack converter
	spi_block #(
		.TP			(1			)
	) DUV (
		.reset_i	(reset   	),
		.clk_i		(clk		),  		
		.spi_clk_i	(spi_clk	),  	
		

		// Req-ack interface
		.req_i		(req_i		),			
		.is_read_op (is_read_op ),  	
		.addr_i		(addr_i		),		
		.wr_data_i	(wr_data_i	),		
		
		.ack_o		(ack_o		),			
		.rd_data_o	(rd_data_o	),		

		// SPI interface
		.spi_cs_no	(GSENSOR_CS_N	),
		.spi_clk_o	(GSENSOR_SCLK	),
		.spi_data_o	(GSENSOR_SDO	),
		.spi_data_i	(GSENSOR_SDI	),
		.spi_oe_o	(				)
	);

endmodule
