//---------------------------------------------------------------------------------------
// The material in this file is property of FotoNation
// Author      : DN
//---------------------------------------------------------------------------------------
// Description : Demo for HDMI driver 
// WARNING     : Reconfigure clk_wiz_pixel_serial according to RESOLUTION
//
// RESOLUTION   pixelClk     
//---------------------------------------
// FULL_HD      148.5 MHz    
// HD           74.250 MHz    1280 x 720
// VGA          25.175 MHz
// SVGA         40.000 MHz
// serialClk = 5X pixelClk
//---------------------------------------------------------------------------------------
// Modification history :
// 02/23/2022     DN      : Initial draft
// 07/22/2024     DN      : Reset active high
// 07/22/2024     DN      : Pattern BLUE
//---------------------------------------------------------------------------------------

module hdmi_demo_blue #(
parameter RESOLUTION = "HD"   // FULL_HD
                              // HD
                              // VGA
                              // SVGA
)(
input         clk             , // Clock signal
input         rst             , // Async reset, active high
// control inputs
input         stop_motion     ,
input         advance_frame_btn     ,
input [1:0]   speed_btn       ,  // speed (from buttons)

// HDMI OUT
output        hdmi_out_clk_n  ,
output        hdmi_out_clk_p  ,
output [2:0]  hdmi_out_data_n ,
output [2:0]  hdmi_out_data_p , 
// Blinking LED
output        led_btn             ,
output        led             ,
output        led_n  
);


wire             pixelClk    ; // frequency according to RESOLUTION
wire             serialClk   ; // frequency = 5x pixelClk
wire             rst_n       ;
wire [8+8+8-1:0] fifo_data   ;
wire             fifo_pop    ;
wire     [11:0]  column      ;
wire     [10:0]  row         ;

assign rst_n = ~rst;
assign led_btn = advance_frame_btn;

// 3.72Hz blinking LED for debug purpose
blink i_blink (
.clk   (clk   ), 
.rst   (rst   ), 
.led   (led   ),
.led_n (led_n )
);

// clock generator
clk_wiz_pixel_serial i_clk_wiz_pixel_serial (
.clk_in1  (clk        ), 
.clk_out1 (pixelClk   ), 
.clk_out2 (serialClk  )  
);

// debug purpose, full BLUE screen
pattern_blue i_pattern_blue(
.pixelClk         (pixelClk)         ,
.rst_n            (rst_n)            ,

.stop_motion      (stop_motion)      ,
.advance_frame_btn(advance_frame_btn),

.fifo_pop         (fifo_pop         ),
.column           (column           ),
.row              (row              ),
.fifo_data        (fifo_data        )
);

hdmi_drv #(
.RESOLUTION       (RESOLUTION      )
) i_hdmi_drv (
.pixelClk         (pixelClk        ), // frequency according to RESOLUTION
.serialClk        (serialClk       ), // frequency = 5x pixelClk
.rst_n            (rst_n           ), // Async reset, active low
.cfg_enable       (1'b1            ), // module enable
.fifo_pop         (fifo_pop        ),
.fifo_data        (fifo_data       ),
.column           (column          ),
.row              (row             ),
.hdmi_out_clk_n   (hdmi_out_clk_n  ),
.hdmi_out_clk_p   (hdmi_out_clk_p  ),
.hdmi_out_data_n  (hdmi_out_data_n ),
.hdmi_out_data_p  (hdmi_out_data_p )
);

endmodule // hdmi_demo_blue