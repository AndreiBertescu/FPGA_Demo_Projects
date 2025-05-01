`timescale 1ns / 1ns

module top(
	input       		MAX10_CLK1_50,
	
	output reg [9:0]    LEDR,
	input [9:0]			SW,
	input [1:0]			KEY,
	
	output				VGA_HS,
	output				VGA_VS, 
	output [4-1 : 0]	VGA_R,
	output [4-1 : 0]	VGA_G,
	output [4-1 : 0]	VGA_B
);

	localparam 			 TP 	 	 = 1;
	localparam 			 IN_FREQ 	 = 25_000_000;

	wire 			clk;
	wire 			locked;
	reg [2 : 0] 	reset_FF;
	wire 			reset;
	
	wire 			slow_clk;
	reg  			slow_clk_d;
	reg [4-1 : 0] 	counter;
	
	wire 			vga_eof;		
	wire [12-1 : 0] vga_col;		
	wire [12-1 : 0] vga_row;		
	wire [12-1 : 0] vga_pix_data;
	
	
	// Clock generator IP
	clk_wiz clk_wiz_0(
		.areset		(~KEY[0]		),
		.inclk0		(MAX10_CLK1_50 	),
		.c0			(clk			),	// 25MHz for VGA
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
	
	
	// Clock divider to create a 1Hz signal
    clock_divider #(
        .FREQ_IN    (IN_FREQ	),
        .FREQ_OUT   (1		    ),
        .MAKE_PULSE (0          )
    ) clock_divider_0 (
        .clk        (clk        ),
        .reset_i    (reset      ),
        .clk_o      (slow_clk   )
    );
	
	// LEDs pattern generator
	always @(posedge clk or posedge reset) begin
		if(reset)
			LEDR <= {10{1'b0}};
		else if(SW[1])
			LEDR <= {10{1'b1}};
		else if(SW[0])
			LEDR <= slow_clk ? {10'h2aa} : {10'h155};
		else 
			LEDR <= slow_clk ? {10'h1f} : {10'h3e0};
	end
	
	
	// VGA driver
	vga_driver #(
		.RESOLUTION("VGA")   // FULL_HD - HD - VGA - SVGA
	) vga_driver_inst (
		.clk			(clk					),
		.reset_i		(reset					),
		
		// Internal interface
		.eof_event_o	(vga_eof				),
		.column_o		(vga_col				),
		.row_o			(vga_row				),
		.pix_data_o		(vga_pix_data			),
		
		// VGA interface       
		.vga_h_sync_o	(VGA_HS					),                    
		.vga_v_sync_o	(VGA_VS					),
		.vga_data_o		({VGA_R, VGA_G, VGA_B}	)    
	);
	
	// VGA feeder
	vga_feeder vga_feeder_inst (
		.clk			(clk			),
		.reset_i		(reset			),
		.sw_i			(SW[0]			),
		
		.eof_event_i	(vga_eof		),
		.column_i		(vga_col		),
		.row_i			(vga_row		),
		.pix_data_o		(vga_pix_data	)
	);

endmodule
