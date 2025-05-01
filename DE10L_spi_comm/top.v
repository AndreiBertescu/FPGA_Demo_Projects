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
	output 				GSENSOR_SDO,
	inout  				GSENSOR_SDI
);
	
	localparam TP 					 = 1;
	localparam IN_FREQ 				 = 50_000_000;
	localparam [8-1 : 0] HEX_BALL_LO = 8'b10100011;
	localparam [8-1 : 0] HEX_BALL_HI = 8'b10011100;

	// Control signals
	wire 					clk;
	wire 					clk_sample;
	wire 					locked;
	reg [2 : 0] 			reset_FF;
	wire 					reset;
	reg 					key_d;
	
	// SPI setup signals
    wire [6-1 : 0]  		addr_i;       			 
    wire            		is_read_opp_i;      
    wire [4-1 : 0]  		byte_amount_i;      
    wire            		start_i; 
    wire            		ready_o;    
	assign 					addr_i 	       = 6'h32;	// DATAX0 register
	assign 					is_read_opp_i  = 1'b1;
	assign 					byte_amount_i  = 4'd4;	// DATAX0 - DATAY1 bytes
	assign 					start_i 	   = SW[0] ? clk_sample : (key_d & ~KEY[1]);	// Enable/disable automatic data retreival
	
	// SPI write signals - unused
    wire [8-1 : 0]  		data_i;             
    wire            		is_tx_fifo_empty_o; 
    wire            		push_data_i;  
	assign 					data_i = 8'b0;
	assign 					push_data_i = 0;

	// SPI read signals
    wire [8-1 : 0]  		data_o;             
    wire            		is_rx_fifo_empty_o; 
	reg 					is_rx_fifo_empty_d;
    wire            		pop_data_i;  
	assign 					pop_data_i = ~is_rx_fifo_empty_o;
	
	reg [2-1 : 0] 			data_ptr;
	reg [32-1 : 0] 			received_data;
	wire [32-1 : 0] 		mask;
	wire signed [16-1 : 0] 	datax;
	wire signed [16-1 : 0] 	datay;
	assign 					mask = {32{1'b0}} | (8'hff << (data_ptr * 8));
	assign 					datax = received_data[16-1 : 0];		// Range = aprox -270 : +256 - slightly offset
	assign 					datay = received_data[32-1 : 16]; 
	
	
	// Clock generator IP
	clk_wiz clk_wiz_0(
		.areset		(~KEY[0]		),
		.inclk0		(MAX10_CLK1_50 	),
		.c0			(clk			),
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
	
	
	// Clock divider to create sample frequency
    clock_divider #(
        .FREQ_IN    (IN_FREQ    ),
        .FREQ_OUT   (50			),
        .MAKE_PULSE (1          )
    ) clock_divider_0 (
        .clk        (clk        ),
        .reset_i    (reset      ),
        .clk_o      (clk_sample )
    );
	
	// Delay generators
	always @(posedge clk) begin
		key_d <= KEY[1];
	    is_rx_fifo_empty_d <= is_rx_fifo_empty_o;
	end
	
	
	// SPI to req_ack converter
	spi_block_V2 #(
        .TP                 (TP                 ),
        .IN_FREQ            (50_000_000         ),
        .SPI_FREQ           (2_000_000          ),
        .ADDR_WORD_SIZE     (6 + 2      		),
        .FIFO_DEPTH         (8                  ),
		.IS_THREE_WIRE		(1					)
    ) spi_block_inst (
        .clk                (clk             	),
        .reset_i            (reset              ),

		.spi_cs_o			(GSENSOR_CS_N		),
		.spi_clk_o			(GSENSOR_SCLK		),
		.spi_data_o			(GSENSOR_SDO		),
		.spi_data_io		(GSENSOR_SDI		),

        .addr_i       		(addr_i       		),
        .is_read_opp_i      (is_read_opp_i      ),
        .byte_amount_i      (byte_amount_i      ),
        .start_i            (start_i            ),
        .ready_o            (ready_o            ),

        .data_i             (data_i             ),
        .is_tx_fifo_empty_o (is_tx_fifo_empty_o ),
        .push_data_i        (push_data_i        ),

        .data_o             (data_o             ),
        .is_rx_fifo_empty_o (is_rx_fifo_empty_o ),
        .pop_data_i         (pop_data_i         ) 
    );
	
	
    // SPI data retreival
	// data_ptr - used to track which byte is being received
	always @(posedge clk or posedge reset) begin
		if(reset)
			data_ptr <= 'b0;
		else if(start_i)
			data_ptr <= 'b0;
		else if(~is_rx_fifo_empty_d)
			data_ptr <= data_ptr + 1;
	end
	
	// received_data - used to store the 4 bytes received in a transaction
	// Keeps the previous received bytes with a mask, and adds the newly received byte at the right place
	always @(posedge clk or posedge reset) begin
		if(reset)
			received_data <= 32'b0;
		else if(start_i)
			received_data <= 32'b0;
		else if(~is_rx_fifo_empty_d)
			received_data <= (received_data & (~mask)) + (data_o << (data_ptr * 8));
	end
	
	
	// Output logic
	assign HEX0 = (datax <= -180				) ? ((datay > 0) ? HEX_BALL_LO : HEX_BALL_HI) : 8'hff;
	assign HEX1 = (datax > -180 & datax <= -80	) ? ((datay > 0) ? HEX_BALL_LO : HEX_BALL_HI) : 8'hff;
	assign HEX2 = (datax > -80 & datax <= 0		) ? ((datay > 0) ? HEX_BALL_LO : HEX_BALL_HI) : 8'hff;
	assign HEX3 = (datax > 0   & datax <= 80 	) ? ((datay > 0) ? HEX_BALL_LO : HEX_BALL_HI) : 8'hff;
	assign HEX4 = (datax > 80  & datax <= 180 	) ? ((datay > 0) ? HEX_BALL_LO : HEX_BALL_HI) : 8'hff;
	assign HEX5 = (datax > 180				 	) ? ((datay > 0) ? HEX_BALL_LO : HEX_BALL_HI) : 8'hff;
	
	assign LEDR = ((datax < 0) ? 10'b0000011111 : 10'b1111100000);
	
endmodule
