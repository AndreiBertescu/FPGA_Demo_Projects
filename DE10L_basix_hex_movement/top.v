`timescale 1ns / 1ns

module top(
	input       	MAX10_CLK1_50,
	input [1:0]		KEY,
	
	output [7:0]	HEX0,
	output [7:0]	HEX1,
	output [7:0]	HEX2,
	output [7:0]	HEX3,
	output [7:0]	HEX4,
	output [7:0]	HEX5
);

	localparam 			 TP 	 	 = 1;
	localparam 			 IN_FREQ 	 = 50_000_000;	// 50 MHz

	
	// Clock divider to create a 1Hz signal
    clock_divider #(
        .FREQ_IN    (IN_FREQ		),
        .FREQ_OUT   (1		    	),
        .MAKE_PULSE (1          	)
    ) clock_divider_0 (
        .clk        (MAX10_CLK1_50	),
        .reset_i    (~KEY[0]      	),
        .clk_o      (slow_clk   	)
    );
	
	
	hex_handler hex_handler_inst(
		.clk		(MAX10_CLK1_50	),
		.reset		(~KEY[0]		),
		.slow_clk	(slow_clk		),
		
		.HEX0		(HEX0			),
		.HEX1		(HEX1			),
		.HEX2		(HEX2			),
		.HEX3		(HEX3			),
		.HEX4		(HEX4			),
		.HEX5		(HEX5			)
	);

endmodule
