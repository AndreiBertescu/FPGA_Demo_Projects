`timescale 1ns / 1ns

module spi_wrapper #(
	parameter TP 			= 1,
	parameter IN_FREQ 		= 50_000_000,
	parameter SAMPLE_FREQ 	= 50
)(
	input       				clk,
	input 						reset_i,
	input 						SW,
			
	output 						GSENSOR_CS_N,
	output 						GSENSOR_SCLK,
	output 						GSENSOR_SDO,
	inout  						GSENSOR_SDI,
	
	output signed [16-1 : 0]	datax_o,
	output signed [16-1 : 0]	datay_o,
	output reg [8-1 : 0]		devid_o
);
	
	// SPI setup signals
    wire [6-1 : 0]  addr_i;       			 
    wire            is_read_opp_i;      
    wire [4-1 : 0]  byte_amount_i;      
    wire            start_i; 
    wire            ready_o;    
	assign 			addr_i 	       = SW ? 6'h0 : 6'h32;	// DEVID / DATAX0 register
	assign 			is_read_opp_i  = 1'b1;
	assign 			byte_amount_i  = 4'd4;	// DATAX0 - DATAY1 bytes
	assign 			start_i 	   = clk_sample;
	
	// SPI write signals - unused
    wire [8-1 : 0]  data_i;             
    wire            is_tx_fifo_empty_o; 
    wire            push_data_i;  
	assign 			data_i = 8'b0;
	assign 			push_data_i = 0;

	// SPI read signals
    wire [8-1 : 0]  data_o;             
    wire            is_rx_fifo_empty_o; 
	reg 			is_rx_fifo_empty_d;
    wire            pop_data_i;  
	assign 			pop_data_i = ~is_rx_fifo_empty_o;
	
	reg [2-1 : 0] 	data_ptr;
	reg [32-1 : 0] 	received_data;
	wire [32-1 : 0] mask;
	assign 			mask = {32{1'b0}} | (8'hff << (data_ptr * 8));
	assign datax_o = SW ? 16'b0 : received_data[16-1 : 0] + 16;		// Range = aprox -270 : +256 - slightly offset
	assign datay_o = SW ? 16'b0 : received_data[32-1 : 16]; 
	
	
	// Device_id register
	always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			devid_o <= 8'b0;
		else if(SW & ~is_rx_fifo_empty_d)
			devid_o <= received_data[8-1 : 0];
	end

	
	// Clock divider to create sample frequency
    clock_divider #(
        .FREQ_IN    (IN_FREQ    ),
        .FREQ_OUT   (SAMPLE_FREQ),
        .MAKE_PULSE (1          )
    ) clock_divider_0 (
        .clk        (clk        ),
        .reset_i    (reset_i    ),
        .clk_o      (clk_sample )
    );
	
	// Delay generator
	always @(posedge clk) begin
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
        .reset_i            (reset_i            ),

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
	always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			data_ptr <= 'b0;
		else if(start_i)
			data_ptr <= 'b0;
		else if(~is_rx_fifo_empty_d)
			data_ptr <= data_ptr + 1;
	end
	
	// received_data - used to store the 4 bytes received in a transaction
	// Keeps the previous received bytes with a mask, and adds the newly received byte at the right place
	always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			received_data <= 32'b0;
		else if(start_i)
			received_data <= 32'b0;
		else if(~is_rx_fifo_empty_d)
			received_data <= (received_data & (~mask)) + (data_o << (data_ptr * 8));
	end
	
endmodule
