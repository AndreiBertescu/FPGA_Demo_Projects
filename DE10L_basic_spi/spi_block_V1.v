module spi_block_V1 #(
	parameter TP = 1
)(
    input        reset_i,
    input        clk_i,  		// max 5MHz for ADXL345 sensor
    input        spi_clk_i,  	// same frequency as clk_i, 220 deg phase offset

    // Req-ack interface
	input        req_i,			// starts the transaction
    input        is_read_op,  	// is read operation - should be ready on req_i
    input  [5:0] addr_i,		// reg address - should be ready on req_i
    input  [7:0] wr_data_i,		// input data - should be ready on req_i
	
    output reg   ack_o,			// transaction complete
    output [7:0] rd_data_o,		// output data - ready when ack_o

    // SPI interface
    output	     spi_cs_o,
    output       spi_clk_o,
    inout        spi_data_io
);

localparam SHREG_WIDTH = 16;

reg [SHREG_WIDTH-1 : 0] shift_reg;
reg [SHREG_WIDTH-1 : 0] shift_cnt;

assign spi_cs_o  = ~shift_cnt[0];
assign spi_clk_o  = spi_cs_o ? 1'b1 : spi_clk_i;

assign spi_data_io = shift_cnt[8] ? shift_reg[SHREG_WIDTH-1] : 1'bz;
assign rd_data_o  = shift_reg[7:0];


// Shift register counter - counts up to its length
always @ (posedge clk_i or posedge reset_i) begin
    if (reset_i)
        shift_cnt <= #TP {SHREG_WIDTH{1'b0}};
    else if (req_i && spi_cs_o)
        shift_cnt <= #TP {SHREG_WIDTH{1'b1}};
    else
        shift_cnt <= #TP shift_cnt >> 1;
end


// IO shift register - for SPI bus
always @ (posedge clk_i or posedge reset_i) begin
    if (reset_i)
        shift_reg <= #TP {(SHREG_WIDTH){1'b0}};
    else if (~spi_cs_o)
        shift_reg <= #TP (shift_reg << 1) | spi_data_io;
    else if (req_i)
        shift_reg <= #TP {is_read_op, 1'b0, addr_i, wr_data_i};
end


// Acknowledge register
always @ (posedge clk_i or posedge reset_i) begin
    if (reset_i)
        ack_o <= #TP 1'b0;
    else
        ack_o <= #TP (shift_cnt[1:0] == 2'b01);
end

endmodule

