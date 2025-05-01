module spi_block_V1_tb();

localparam HALF_CLOCK_PERIOD = 5;
localparam OFFSET_PERIOD = 0;
localparam TP = 1;

reg         reset_i;
reg         clk;	
reg         spi_clk;
	
reg        	req_i;		
reg        	is_read_op;		
reg  [5:0] 	addr_i;	
reg  [7:0] 	wr_data_i;
	
wire		ack_o;		
wire [7:0] 	rd_data_o;
		
wire       	spi_cs_no;
wire       	spi_clk_o;
wire       	spi_data_o;
wire        spi_data_i;
wire       	spi_oe_o;

assign spi_data_i = 1'b1;


// Clock generator
initial begin
	clk <= 1'b0;
	forever begin
		#HALF_CLOCK_PERIOD clk <= ~clk;
	end
end

// SPI clock generator
initial begin
	spi_clk <= 1'b0;
	#OFFSET_PERIOD
	forever begin
		#HALF_CLOCK_PERIOD spi_clk <= ~spi_clk;
	end
end


// Main test loop
initial begin
//	req_i 		= 0;
//	is_read_op 	= 0;
//	addr_i 		= 0;
//	wr_data_i 	= 0;


	// Wait reset
	reset_i = #TP 0;
	@(posedge clk);
	reset_i = #TP 1;
	repeat (10) @(posedge clk);
	reset_i = #TP 0;
	@(posedge clk);
	
	
	is_read_op 	=  1'b1;
	addr_i 		= 8'h75;
	wr_data_i 	= 8'h00;
	req_i 		= 1'b1;
//	// Start transaction
//	is_read_op 	= #TP 1'b0;
//	addr_i 		= 8'ha5;
//	wr_data_i 	= 8'ha5;
//	req_i 		= 1'b1;
//	@(posedge clk);
//	is_read_op 	= #TP 1'b0;
//	addr_i 		= 8'h00;
//	wr_data_i 	= 8'h00;
////	req_i 		= 1'b0;

//	// Wait transaction to finish
//	@(posedge ack_o);
//	repeat (30) @(posedge clk);
	
	
	// Start transaction
	is_read_op 	= #TP 1'b1;
	addr_i 		= 8'h75;
	wr_data_i 	= 8'h00;
	req_i 		= 1'b1;
	@(posedge clk);
//	is_read_op 	= #TP 1'b0;
//	addr_i 		= 8'h00;
//	wr_data_i 	= 8'h00;
//	req_i 		= 1'b0;

	// Wait transaction to finish
	@(posedge ack_o);
	repeat (30) @(posedge clk);
	
	
	// End
	repeat (10) @(posedge clk);
	$finish;
end
	

spi_block_V1 DUV (
    .reset_i	(reset_i	),
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
    .spi_cs_o	(spi_cs_no	),
    .spi_clk_o	(spi_clk_o	),
    .spi_data_o	(spi_data_o	),
    .spi_data_i	(spi_data_i	),
    .spi_oe_o	(spi_oe_o	)
);

endmodule
