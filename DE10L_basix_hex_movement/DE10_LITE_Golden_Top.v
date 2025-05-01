module top(
	input       		MAX10_CLK1_50
	
	output reg [9:0]    LEDR,
	input [9:0]			SW,
	input [1:0]			KEY,
	
	output reg [7:0]	HEX0,
	output reg [7:0]	HEX1,
	output reg [7:0]	HEX2,
	output reg [7:0]	HEX3,
	output reg [7:0]	HEX4,
	output reg [7:0]	HEX5
);

	localparam 			 TP 	 = 1;
	localparam 			 IN_FREQ 	 = 50_000_000;	// 50 MHz
	localparam [8-1 : 0] HEX_BALL_LO = 8'b01011100;
	localparam [8-1 : 0] HEX_BALL_HI = 8'b01100011;

	wire 			clk;
	reg [2 : 0] 	reset_FF;
	wire 			reset;
	
	wire 			slow_clk;
	reg  			slow_clk_d;
	reg [4-1 : 0] 	counter;
	
	
	// Clock generator IP
	clk_wiz clk_wiz_0(
		.areset		(KEY[0]			),
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
	
	
	// 7-segment displays pattern generator
	always @(posedge clk or posedge reset) begin
		if(reset)
			HEX0 <= {8{1'b0}};
			HEX1 <= {8{1'b0}};
			HEX4 <= {8{1'b0}};
			HEX5 <= {8{1'b0}};
		else if(SW[0])
			HEX0 <= slow_clk ? HEX_BALL_LO : HEX_BALL_HI;
			HEX1 <= slow_clk ? HEX_BALL_HI : HEX_BALL_LO;
			HEX4 <= slow_clk ? HEX_BALL_HI : HEX_BALL_LO;
			HEX5 <= slow_clk ? HEX_BALL_LO : HEX_BALL_HI;
		else 
			HEX0 <= slow_clk ? HEX_BALL_LO : HEX_BALL_HI;
			HEX1 <= slow_clk ? HEX_BALL_LO : HEX_BALL_HI;
			HEX4 <= slow_clk ? HEX_BALL_LO : HEX_BALL_HI;
			HEX5 <= slow_clk ? HEX_BALL_LO : HEX_BALL_HI;
	end
	
	
	// slow_clk delay
	always @(posedge clk) begin
		slow_clk_d <= slow_clk;
	end
	
	// 32-bit counter
	always @(posedge clk or posedge reset) begin
		if(reset)
			counter <= {4{1'b0}};
		else if(counter == 4'd9)
			counter <= {4{1'b0}};
		else if(~slow_clk_d & slow_clk)	//posedge detector
			counter <= counter + 1;
	end
	
	// Use two 7-segment displays to show counter value
	always @(posedge clk or posedge reset) begin
		if(reset)
			HEX2 <= {8{1'b0}};
			HEX3 <= {8{1'b0}};
		else
			case (counter)
				4'd0: 	  begin HEX2 = 8'b00111111;
								HEX3 = 8'b00111111; end
				4'd1: 	  begin HEX2 = 8'b00000110;
								HEX3 = 8'b00000110; end
				4'd2: 	  begin HEX2 = 8'b01011011;
								HEX3 = 8'b01011011; end
				4'd3: 	  begin HEX2 = 8'b01001111;
								HEX3 = 8'b01001111; end
				4'd4: 	  begin HEX2 = 8'b01100110;
								HEX3 = 8'b01100110; end
				4'd5: 	  begin HEX2 = 8'b01101101;
								HEX3 = 8'b01101101; end
				4'd6: 	  begin HEX2 = 8'b01111101;
								HEX3 = 8'b01111101; end
				4'd7: 	  begin HEX2 = 8'b00000111;
								HEX3 = 8'b00000111; end
				4'd8: 	  begin HEX2 = 8'b01111111;
								HEX3 = 8'b01111111; end
				default:  begin HEX2 = 8'b01101111;
								HEX3 = 8'b01101111; end
			endcase
    end

endmodule
