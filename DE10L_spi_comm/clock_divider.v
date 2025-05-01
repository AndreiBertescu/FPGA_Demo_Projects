`timescale 1ns / 1ns

module clock_divider #(
    parameter FREQ_IN    = 100_000_000,  // 100 MHz
    parameter FREQ_OUT   = 9600,
    parameter MAKE_PULSE = 0
)(
    input       clk,
    input       reset_i,
    output reg  clk_o
);  

    localparam COUNT_MAX = FREQ_IN / FREQ_OUT;
    reg [$clog2(COUNT_MAX)-1:0] counter;
   
    
    // Clock divider counter
    always @(posedge clk or posedge reset_i) begin
        if (reset_i)
            counter  <= {$clog2(COUNT_MAX){1'b0}};
        else if (counter == COUNT_MAX - 1)
            counter  <= {$clog2(COUNT_MAX){1'b0}};
        else
            counter  <= counter + 1;
    end

    // Output clock signal
    always @(posedge clk) begin
        if(MAKE_PULSE)
            clk_o <=  (counter == COUNT_MAX/2);
        else
            clk_o <=  (counter < COUNT_MAX/2);
    end

endmodule