`timescale 1ns / 1ns

module spi_block_V2 #(
    parameter TP             = 1,
    parameter IN_FREQ        = 100_000_000,  // 100 MHz
    parameter SPI_FREQ       = 1_000_000,    // 1 MHz
    parameter ADDR_WORD_SIZE = 8,
    parameter FIFO_DEPTH     = 8,
	parameter IS_THREE_WIRE	 = 0
)(
    input        		reset_i,
    input        		clk,

    output       		spi_cs_o,
    output       		spi_clk_o,
    output       		spi_data_o,
    inout        		spi_data_io,
		
    input [6-1 : 0] 	addr_i,				// Reg address
    input        		is_read_opp_i, 		// Is read operation
    input [4-1 : 0]     byte_amount_i,      // Nr. of bytes to read/write
	input        		start_i,			// Starts the transaction
    output       		ready_o,			// Can start transaction
	
    input [8-1 : 0]		data_i,             // Data to be loaded in tx_fifo
    output         		is_tx_fifo_empty_o, // Is tx_fifo empty
    input          		push_data_i,        // Load signal

    output [8-1 : 0]	data_o,             // Data from rx_fifo
    output          	is_rx_fifo_empty_o, // Is rx_fifo empty
    input           	pop_data_i          // Get data from rx_fifo
);


    // Used if addres word width is greater that 8 bits
    localparam SH_REG_SIZE = (ADDR_WORD_SIZE + 1 > 8) ? (ADDR_WORD_SIZE + 1) : 8;
    
    // State machine values
    localparam S_IDLE       = 5'b00001;
    localparam S_STALL      = 5'b00010;
    localparam S_LOAD_ADDR  = 5'b00100;
    localparam S_LOAD_DATA  = 5'b01000;
    localparam S_READ_DATA  = 5'b10000;

    // Control signals
    reg                         start_slow;
    reg [7-1 : 0]               state;
    reg [4-1 : 0]               counter;
    reg [4-1 : 0]               aux_counter;
    
    reg [ADDR_WORD_SIZE -1 : 0] fused_addr;
    reg [4-1 : 0]               byte_amount;
    wire[8-1 : 0]               data_out_tx;

    // Shift registers
    reg [SH_REG_SIZE-1 : 0]     shift_reg_tx;
    reg [8-1 : 0]               shift_reg_rx;

    // Clock-domain-switching helper signals
    reg                         push_data_rx;
    reg                         push_data_rx_slow;
    reg                         push_data_rx_slow_d;
    reg                         pop_data_tx;
    reg                         pop_data_tx_slow;
    reg                         pop_data_tx_slow_d;
    
    assign spi_clk_o = (state != S_IDLE & state != S_STALL) ? clk_spi : 1'b1;
    assign spi_cs_o  = ready_o;
    assign ready_o   = (state == S_IDLE);
	
	
	// Clock divider to create I2C frequency
    clock_divider #(
        .FREQ_IN    (IN_FREQ    ),
        .FREQ_OUT   (SPI_FREQ   ),
        .MAKE_PULSE (0          )
    ) clock_divider_0 (
        .clk        (clk        ),
        .reset_i    (reset_i    ),
        .clk_o      (clk_spi    )
    );

////// FAST CLOCK DOMAIN

    // Input and output FIFO's
    fifo #(
        .DATA_WIDTH     (8                  ),
        .DEPTH          (FIFO_DEPTH         )
    ) tx_fifo (
        .clk            (clk                ),
        .rst_n          (~reset_i           ),

        .write_enable   (push_data_i        ),
        .data_i         (data_i             ),

        .read_enable    (pop_data_tx        ),
        .data_o         (data_out_tx        ),

        .full           (                   ),
        .empty          (is_tx_fifo_empty_o )
    );
    
    fifo #(
        .DATA_WIDTH     (8                  ),
        .DEPTH          (FIFO_DEPTH         )
    ) rx_fifo (
        .clk            (clk                ),
        .rst_n          (~reset_i           ),

        .write_enable   (push_data_rx       ),
        .data_i         (shift_reg_rx       ),

        .read_enable    (pop_data_i         ),
        .data_o         (data_o             ),

        .full           (                   ),
        .empty          (is_rx_fifo_empty_o )
    );
    
    
    // Read register to get address and is_read_opp_i
    always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			fused_addr <= #TP {ADDR_WORD_SIZE{1'b0}};
		else if(start_i & ready_o)
			fused_addr <= #TP {is_read_opp_i, ((byte_amount_i <= 1) ? 1'b0 : 1'b1), addr_i};
    end


    // Read only register to get byte_amount
    always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			byte_amount <= #TP {8{1'b0}};
		else if(start_i & ready_o)
			byte_amount <= #TP (byte_amount_i == 0) ? 1 : byte_amount_i;
    end


    // Makes start_i last until it is detected
    always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			start_slow <= #TP 1'b0;
        else if(!ready_o)
			start_slow <= #TP 1'b0;
		else if(start_i)
			start_slow <= #TP 1'b1;
    end
    

    // Used to jump clock domains - implements posedge detector for push_data_rx 
    always @(posedge clk) begin
        push_data_rx_slow_d <= #TP push_data_rx_slow;
    end

    always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			push_data_rx <= #TP 1'b0;
        else if(push_data_rx)
			push_data_rx <= #TP 1'b0;
		else if(push_data_rx_slow & (~push_data_rx_slow_d))
			push_data_rx <= #TP 1'b1;
    end

    // Used to jump clock domains - implements posedge detector for pop_data_tx
    always @(posedge clk) begin
        pop_data_tx_slow_d <= #TP pop_data_tx_slow;
    end

    always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			pop_data_tx <= #TP 1'b0;
        else if(pop_data_tx)
			pop_data_tx <= #TP 1'b0;
		else if(pop_data_tx_slow & (~pop_data_tx_slow_d) & (aux_counter < byte_amount))
			pop_data_tx <= #TP 1'b1;
    end


//////SLOW CLOCK DOMAIN

    // Signal to store data read from sda - push_data_rx_slow
    always @(negedge clk_spi or posedge reset_i) begin
		if(reset_i)
			push_data_rx_slow <= #TP 1'b0;
        else if(push_data_rx_slow)
			push_data_rx_slow <= #TP 1'b0;
		else if((state == S_READ_DATA) & (counter == 7))
			push_data_rx_slow <= #TP 1'b1;
    end

    // Signal to get data from tx_fifo - pop_data_tx_slow
    always @(negedge clk_spi or posedge reset_i) begin
		if(reset_i)
			pop_data_tx_slow <= #TP 1'b0;
        else if(pop_data_tx_slow)
			pop_data_tx_slow <= #TP 1'b0;
		else if((state == S_LOAD_ADDR || state == S_LOAD_DATA) & (counter == 1))
			pop_data_tx_slow <= #TP 1'b1;
    end


    // MOSI shift register
    always @(negedge clk_spi or posedge reset_i) begin
		if(reset_i)
			shift_reg_tx <= #TP {SH_REG_SIZE{1'b0}};

        // Loads RW bit, MB bit and addr
		else if(state == S_STALL)   
			shift_reg_tx <= #TP {fused_addr, {(SH_REG_SIZE - ADDR_WORD_SIZE){1'b0}}}; 

        // Loads data from fifo
		else if(((state == S_LOAD_ADDR) & (counter == ADDR_WORD_SIZE - 1) & ~fused_addr[ADDR_WORD_SIZE - 1]) |
                ((state == S_LOAD_DATA) & (counter == 7)))
			shift_reg_tx <= #TP {data_out_tx, {(SH_REG_SIZE - 8){1'b0}}};

		else
			shift_reg_tx <= #TP {shift_reg_tx[SH_REG_SIZE-1 : 0], 1'b0};
    end
	
	
	// If a 3-wire protocol is used, switch the output source
	assign spi_data_o = IS_THREE_WIRE ? 1'b0 : shift_reg_tx[SH_REG_SIZE - 1];
	assign spi_data_io = (IS_THREE_WIRE & (state != S_READ_DATA)) ? shift_reg_tx[SH_REG_SIZE - 1] : 1'bz;
		

    // MISO receive shift register
    // ALWAYS READ ON POSEDGE SIGNAL
    always @(posedge clk_spi or posedge reset_i) begin
		if(reset_i)
			shift_reg_rx <= #TP {8{1'b1}};
		else
			shift_reg_rx <= #TP {shift_reg_rx[6 : 0], spi_data_io};
    end


    // State machine
    always @(negedge clk_spi or posedge reset_i) begin
		if(reset_i)
			state <= #TP S_IDLE;

        // After start pulls spi_cs low
        else if(start_slow & ready_o)
			state <= #TP S_STALL;
			
        // After start loads is_read_opp_i, multiple_bytes and address
        else if(state == S_STALL)
			state <= #TP S_LOAD_ADDR;

        // After address is loaded, initiate data read/write
        else if((state == S_LOAD_ADDR) & (counter == ADDR_WORD_SIZE - 1))
            state <= #TP (is_read_opp_i) ? S_READ_DATA : S_LOAD_DATA;

        // Stop transfer if enough bytes have been sent
        else if((state == S_LOAD_DATA) & (counter == 7) & (aux_counter == byte_amount - 1)) 
            state <= #TP S_IDLE;

        // Stop transfer if enough bytes have been read
        else if((state == S_READ_DATA) & (counter == 7) & (aux_counter == byte_amount - 1)) 
            state <= #TP S_IDLE;
    end


    // Counter used to keep count of how many bits were sent/received
    always @(negedge clk_spi or posedge reset_i) begin
		if(reset_i)
			counter <= #TP {4{1'b0}};
		else if((state == S_IDLE) | (state == S_STALL) | 
                (state == S_LOAD_ADDR && counter == ADDR_WORD_SIZE - 1) |
                ((state == S_READ_DATA || state == S_LOAD_DATA) & counter == 7))
			counter <= #TP {4{1'b0}};
		else
			counter <= #TP counter + 1;
    end


    // Auxiliary counter used to keep count of how many bytes were sent/received
    // Increments when a byte has been written/read
    always @(negedge clk_spi or posedge reset_i) begin
		if(reset_i)
			aux_counter <= #TP {4{1'b0}};
		else if(state == S_IDLE)
			aux_counter <= #TP {4{1'b0}};
		else if((state == S_READ_DATA || state == S_LOAD_DATA) & (counter == 7))
			aux_counter <= #TP aux_counter + 1;
    end
    
endmodule

