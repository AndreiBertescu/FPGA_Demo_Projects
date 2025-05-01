//---------------------------------------------------------------------------------------
// The material in this file is property of FotoNation
// Author      : DN
//---------------------------------------------------------------------------------------
// Description : Blink a LED (clock fq = 125MHz)
//---------------------------------------------------------------------------------------
// Modification history :
// 02/23/2022     DN      : Initial draft
// 07/22/2024     DN      : Parameter for NO_BITS
//---------------------------------------------------------------------------------------

module blink #(
parameter NO_BITS = 25
)(
input   clk   , // clock signal
input   rst   , // async reset, active high
output  led   ,
output  led_n
);

reg [NO_BITS-1:0] count; // 25 bits counter 125MHz/2^25 = 3.72Hz

always @(posedge clk) 
if (rst) count <= 'b0; else
         count <= count + 1;

assign led    = count[NO_BITS-1];
assign led_n  = ~led;

endmodule // blink