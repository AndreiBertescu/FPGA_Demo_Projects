//---------------------------------------------------------------------------------------
// The material in this file is property of FotoNation
// Author      : DN
//---------------------------------------------------------------------------------------
// Description : HDMI driver (FIFO interface for video image)
//---------------------------------------------------------------------------------------
// Modification history :
// 02/23/2022     DN      : Initial draft
//---------------------------------------------------------------------------------------

module hdmi_drv #(
parameter RESOLUTION = "HD"   // FULL_HD
                              // HD
                              // VGA
                              // SVGA
)(
//system interface
input              pixelClk   , // frequency according to RESOLUTION
input              serialClk  , // frequiency = 5x pixelClk

input              rst_n      , // Async reset, active low
//configuration interface      
input              cfg_enable , //module enable
						
//fifo pop interfaces   
output             fifo_pop   ,
input  [8+8+8-1:0] fifo_data  ,
output     [11:0]  column     ,
output     [10:0]  row        ,

// HDMI OUT
output        hdmi_out_clk_n  ,
output        hdmi_out_clk_p  ,
output [2:0]  hdmi_out_data_n ,
output [2:0]  hdmi_out_data_p 
);

wire          vga_v_sync  ; // vertical synchronization signal
wire          vga_h_sync  ; // horizontal synchronization signal 
wire          vga_data_en ; // data enable
wire  [23:0]  vga_data    ; // image data

fifo2vga #(
.RESOLUTION (RESOLUTION   )
) i_fifo2vga (
.clk        (pixelClk     ), // Clock signal
.rst_n      (rst_n        ), // Async reset, active low
.cfg_enable (cfg_enable   ), // module cfg_enable
.fifo_pop   (fifo_pop     ),
.fifo_data  (fifo_data    ), // 
.column     (column       ),
.row        (row          ),
.vga_v_sync (vga_v_sync   ), // vertical synchronization signal
.vga_h_sync (vga_h_sync   ), // horizontal synchronization signal 
.vga_data_en(vga_data_en  ), // data enable
.vga_data   (vga_data     )  // image data                       
);
 
rgb2dvi i_rgb2dvi(
.PixelClk    (pixelClk             ),
.SerialClk   (serialClk            ),
.aRst_n      (rst_n                ),
.vid_pData   (vga_data             ), 
.vid_pVDE    (vga_data_en          ),
.vid_pHSync  (vga_h_sync           ),
.vid_pVSync  (vga_v_sync           ),
.TMDS_Clk_p  (hdmi_out_clk_p       ),
.TMDS_Clk_n  (hdmi_out_clk_n       ),
.TMDS_Data_p (hdmi_out_data_p      ),
.TMDS_Data_n (hdmi_out_data_n      )
);   

endmodule // hdmi_drv