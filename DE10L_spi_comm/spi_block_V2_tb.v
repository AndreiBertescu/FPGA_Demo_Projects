`timescale 1ns / 1ns

module spi_block_V2_tb();

    localparam HALF_100_MHZ_CLOCK_PERIOD    = 5; //half of the period of the 100 MHz clock
    localparam TP                           = 1;
    localparam ADDR_SIZE                    = 6;

    reg                   clk;
    reg                   reset_i;
		
		wire       			  spi_cs_o;
		wire       			  spi_clk_o;
		wire       			  spi_data_o;
		wire        		  spi_data_i;
		assign spi_data_i = 1'b1;

    reg [ADDR_SIZE-1 : 0] addr_i;       			 
    reg                   is_read_opp_i;      
    reg [4-1 : 0]         byte_amount_i;      
    reg                   start_i;            
    wire                  ready_o;            

    reg [8-1 : 0]         data_i;             
    wire                  is_tx_fifo_empty_o; 
    reg                   push_data_i;        

    wire [8-1 : 0]        data_o;             
    wire                  is_rx_fifo_empty_o; 
    reg                   pop_data_i;         


    // Clock generator
    initial begin
        clk <= 1'b0;
        forever begin
            #HALF_100_MHZ_CLOCK_PERIOD clk <= ~clk;
        end
    end
    

    // Main test loop
    initial begin
        addr_i    			= 0;
        is_read_opp_i   = 0;
        byte_amount_i   = 0;
        start_i         = 0;
        data_i          = 0;
        push_data_i     = 0;
        pop_data_i      = 0;

        // Wait reset
        reset_i = 0;
        @(posedge clk);
        reset_i = 1;
        repeat (10) @(posedge clk);
        reset_i = 0;

        // Load data to fifo
        push_data_i = #TP 1;
        data_i = 'h6b;
        @(posedge clk);
        push_data_i = #TP 0;

        // Set other parameters
        addr_i    			= 6'b101010;
        is_read_opp_i   = 0;
        byte_amount_i   = 1;

        // Start data transfer
        start_i = #TP 1;
        @(posedge clk);
        start_i = #TP 0;

        // Wait send to finish -------------------------------------------
        @(posedge ready_o);
        repeat (10) @(posedge clk);

				// Load data to fifo
        push_data_i = #TP 1;
        data_i = 'h18;
        @(posedge clk);
        data_i = #TP 'ha5;
        @(posedge clk);
        data_i = #TP 'h5a;
        @(posedge clk);
        push_data_i = #TP 0;

        // Set other parameters
        addr_i    			= 6'b101010;
        is_read_opp_i   = 0;
        byte_amount_i   = 3;

        // Start data transfer
        start_i = #TP 1;
        @(posedge clk);
        start_i = #TP 0;
				
        // Wait send to finish -------------------------------------------
        @(posedge ready_o);
        repeat (10) @(posedge clk);

        // Set other parameters
        addr_i    			= 6'b101010;
        is_read_opp_i   = 1;
        byte_amount_i   = 3;

        // Start data transfer
        start_i = #TP 1;
        @(posedge clk);
        start_i = #TP 0;

        // Wait send to finish -------------------------------------------
        @(posedge ready_o);
        repeat (10) @(posedge clk);

				// Read received bytes
        pop_data_i = #TP 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        pop_data_i = #TP 0;
        
        repeat (300) @(posedge clk);
        $finish;
    end


    // DUV
    spi_block_V2 #(
        .TP                 (TP                 ),
        .IN_FREQ            (100_000_000        ),  // 100 MHz
        .SPI_FREQ           (1_000_000          ),  // 1 MHz
        .ADDR_WORD_SIZE     (ADDR_SIZE + 2      ),
        .FIFO_DEPTH         (8                  )
    ) DUV (
        .clk                (clk                ),
        .reset_i            (reset_i            ),

		.spi_cs_o			(spi_cs_o			),
		.spi_clk_o			(spi_clk_o			),
		.spi_data_o			(spi_data_o			),
		.spi_data_i			(spi_data_i			),

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

endmodule