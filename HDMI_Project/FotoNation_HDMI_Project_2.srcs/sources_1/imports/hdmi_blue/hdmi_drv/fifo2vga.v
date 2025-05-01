//---------------------------------------------------------------------------------------
// The material in this file is property of FotoNation
// Author      : (LB)
//---------------------------------------------------------------------------------------
// Description :  Generate VGA interface from a fifo
//---------------------------------------------------------------------------------------
// Modification history :
// 04/04/2020             : Initial draft
// 02/23/2022     DN      : Extend data to 8+8+8
//                        : added column and row outputs
//                        : convert define in parameters
//---------------------------------------------------------------------------------------

module fifo2vga #(
parameter RESOLUTION = "HD"   // FULL_HD
                              // HD
                              // VGA
                              // SVGA
)(
//system interface
input              clk        , // Clock signal
input              rst_n      , // Async reset, active low
//configuration interface      
input              cfg_enable ,//module cfg_enable
						
//fifo pop interfaces   
output reg         fifo_pop   ,
input  [8+8+8-1:0] fifo_data  ,
output reg [11:0]  column     ,
output reg [10:0]  row        ,

//VGA interface                           
output reg              vga_v_sync , //vertical synchronization signal
output reg              vga_h_sync , //horizontal synchronization signal 
output reg              vga_data_en, //data enable
output reg  [8+8+8-1:0] vga_data     //image data
);

// V_BPORCH  = vertical back porch in pixels clocks cycles
// V_VISIBLE = vertical visible number of pixels
// V_FPORCH  = vertical front porch in pixel clock cycles
// V_SYNC    = vertical sync pulse in pixel clock cycles
//             
// H_BPORCH  = horizontal back porch in lines
// H_VISIBLE = horizontal visible number of pixels
// H_FPORCH  = horizontal front porch in lines
// H_SYNC    = horizontal sync pulse lines

localparam H_VISIBLE  = (RESOLUTION == "FULL_HD") ? 1920 : ((RESOLUTION == "HD") ? 1280 : ((RESOLUTION == "VGA") ? 640 : 800 )) ;
localparam H_FPORCH   = (RESOLUTION == "FULL_HD") ? 88   : ((RESOLUTION == "HD") ? 72   : ((RESOLUTION == "VGA") ? 16  : 40  )) ;
localparam H_SYNC     = (RESOLUTION == "FULL_HD") ? 44   : ((RESOLUTION == "HD") ? 80   : ((RESOLUTION == "VGA") ? 96  : 128 )) ;
localparam H_BPORCH   = (RESOLUTION == "FULL_HD") ? 148  : ((RESOLUTION == "HD") ? 216  : ((RESOLUTION == "VGA") ? 48  : 88  )) ;
                                                                                        
localparam V_VISIBLE  = (RESOLUTION == "FULL_HD") ? 1080 : ((RESOLUTION == "HD") ? 720  : ((RESOLUTION == "VGA") ? 480 : 600 )) ;
localparam V_FPORCH   = (RESOLUTION == "FULL_HD") ? 4    : ((RESOLUTION == "HD") ? 3    : ((RESOLUTION == "VGA") ? 10  : 1   )) ;
localparam V_SYNC     = (RESOLUTION == "FULL_HD") ? 5    : ((RESOLUTION == "HD") ? 5    : ((RESOLUTION == "VGA") ? 2   : 4   )) ;
localparam V_BPORCH   = (RESOLUTION == "FULL_HD") ? 36   : ((RESOLUTION == "HD") ? 22   : ((RESOLUTION == "VGA") ? 33  : 23  )) ;
    
reg [11:0] pixcnt;
reg [10:0] lncnt ;
 
//--------------------------------------------------------------------------------------------------
//                                                  CODE
//--------------------------------------------------------------------------------------------------
wire eol_event      ;
wire eof_event      ;
wire visible        ;
wire h_visible      ;
wire v_visible      ;
reg  fifo_pop_delay ;             

assign eol_event = (pixcnt == (H_SYNC + H_BPORCH + H_VISIBLE + H_FPORCH- 1 ));
assign eof_event = (lncnt  == (V_SYNC + V_BPORCH + V_VISIBLE + V_FPORCH- 1 )) & eol_event;

assign h_visible = (pixcnt > (H_SYNC + H_BPORCH - 4)) & ((pixcnt < (H_SYNC + H_BPORCH + H_VISIBLE-3)));
assign v_visible = (lncnt  > (V_SYNC + V_BPORCH - 1)) & ((lncnt  < (V_SYNC + V_BPORCH + V_VISIBLE)));
assign visible   = h_visible & v_visible;

// vertical counter
always @(posedge clk)  
if (~rst_n)                   pixcnt <=  0; else                     
if (~cfg_enable | eol_event ) pixcnt <=  0; else
                              pixcnt <=  pixcnt + 1;

// horizontal counter
always @(posedge clk)       
if (~rst_n)                  lncnt <=  0; else                                   
if (~cfg_enable | eof_event) lncnt <=  0; else
                             lncnt <=  lncnt + eol_event;

// active pixels
always@ (posedge clk)                                         
if (~rst_n) fifo_pop <=  1'b0; else
            fifo_pop <=  visible & cfg_enable;     
            
always@ (posedge clk)                                         
fifo_pop_delay <=  fifo_pop;     

always @(posedge clk)                                         
if (~rst_n)                   vga_h_sync <=  1'b0; else
if (~cfg_enable | eol_event)  vga_h_sync <=  1'b0; else
if (pixcnt == (H_SYNC-1))    vga_h_sync <=  1'd1; 

always @(posedge clk )                                         
if (~rst_n)                   vga_v_sync <=  1'b0; else
if (~cfg_enable | eof_event)  vga_v_sync <=  1'b0; else
if (lncnt == (V_SYNC-1) )    vga_v_sync <=  eol_event; 

// sampled one cycle after fifo_pop
always @(posedge clk)                                         
if (~cfg_enable   ) vga_data <=  0; else
if (fifo_pop_delay) vga_data <=  fifo_data; else 
                    vga_data <=  0; 
              
always @(posedge clk)                                         
if (~rst_n)  vga_data_en <=  1'b0; else
             vga_data_en <=  fifo_pop_delay;    

// column/row for driver reference, when fifo_pop
always @(posedge clk)                                         
if (~rst_n) column  <= 'd0; else  
            column  <= pixcnt - (H_SYNC + H_BPORCH - 4) - 1 ;
always @(posedge clk)                                         
if (~rst_n) row     <= 'd0; else 
            row     <= lncnt  - (V_SYNC + V_BPORCH - 1) - 1 ;

endmodule // fifo2vga
