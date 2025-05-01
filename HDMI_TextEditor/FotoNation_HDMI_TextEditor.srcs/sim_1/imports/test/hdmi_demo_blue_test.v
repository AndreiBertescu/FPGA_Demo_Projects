//---------------------------------------------------------------------------------------
// The material in this file is property of FotoNation
// Author      : DN
//---------------------------------------------------------------------------------------
// Description : Test for HDMI driver demo 
//---------------------------------------------------------------------------------------
// Modification history :
// 02/23/2022     DN      : Initial draft
// 07/22/2024     DN      : Reviewed interface
//---------------------------------------------------------------------------------------

`timescale 1ns / 1ns

module hdmi_demo_blue_test #(
    parameter RESOLUTION = "FULL_HD"
);

  reg clk;
  reg rst;

  initial begin
    clk <= 1'b0;
    forever #4 clk <= ~clk;
  end

  initial begin
    rst <= 1'b1;
    @(posedge clk);
    rst <= 1'b0;  // activate reset
    @(posedge clk);
    @(posedge clk);
    rst <= 1'b1;
    @(posedge clk);  // de-activate synchronously
  end

  hdmi_demo_blue #(
      .RESOLUTION(RESOLUTION)
  ) i_hdmi_demo_blue (
      .clk(clk),  // Clock signal
      .rst(rst),  // Async reset, active low

      // HDMI OUT
      .hdmi_out_clk_n (),
      .hdmi_out_clk_p (),
      .hdmi_out_data_n(),
      .hdmi_out_data_p()
  );

endmodule  // hdmi_demo_blue_test
