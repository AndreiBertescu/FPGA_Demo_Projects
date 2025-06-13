module spi_sequencer #(
	parameter TP = 1
)(
    input        clk_i,
    input        reset_i,
	input 		 enable_i,

    // Req-ack interface
	output        req_o,			
    output        is_read_op,  	
    output  [5:0] addr_o,		
    output  [7:0] wr_data_o,		
	
    input    	  ack_i,			
    input [7:0]   rd_data_i,
	
	// Output
	output reg [16-1 : 0] data_X_o,
	output reg [8-1 : 0] data_Y_o
);

	// Program ROM
	localparam logic [15-1:0] PRG_MEM [0:1] = '{
		//{1'b0, 8'h00, 8'b0000_0000}, // Power control
		{1'b0, 6'h31, 8'b0100_0100}, // 3 Wire, Left Justify
		//{1'b0, 8'h00, 8'b0000_1000}, // Power control
		//{1'b1, 6'h32, 8'bx},
		//{1'b1, 6'h33, 8'bx},
		//{1'b1, 6'h34, 8'bx},
		{1'b1, 6'h31, 8'bx}
	};
	
	reg[4-1 : 0] prg_counter;
	
	// Map instruction to values
	assign req_o 		= enable_i;
	assign is_read_op   = PRG_MEM[prg_counter][14];
	assign addr_o 		= PRG_MEM[prg_counter][13:8];
	assign wr_data_o 	= PRG_MEM[prg_counter][7:0];
	
	
	// Program counter
	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i)
			prg_counter <= 'b0;
		else if(ack_i & (prg_counter == 'd1))
			prg_counter <= 'b0;//prg_counter - 'd3;
		else if(ack_i)
			prg_counter <= prg_counter + 'd1;
	end
	
	
	// Map spi output to propper values
	always @(posedge clk_i or posedge reset_i) begin
		if(reset_i) begin
			data_X_o <= 'b0;
			data_Y_o <= 'b0;
		end else if(ack_i) begin
			//data_X_o[7 : 0]  <= (prg_counter == 1) ? rd_data_i : data_X_o[7 : 0] ;
			//data_X_o[15 : 8] <= (prg_counter == 2) ? rd_data_i : data_X_o[15 : 8];
			data_Y_o  <= (prg_counter == 0) ? rd_data_i : data_Y_o;
			//data_Y_o[15 : 8] <= (prg_counter == 3) ? rd_data_i : data_Y_o[15 : 8];
		end
	end

endmodule

