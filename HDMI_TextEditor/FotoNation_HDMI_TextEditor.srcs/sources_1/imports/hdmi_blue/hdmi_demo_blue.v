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
    parameter RESOLUTION = "FULL_HD"
) (
    input clk, // Clock signal
    input rst, // Async reset, active high

    input change_flag,

    // HDMI OUT
    output       hdmi_out_clk_n,
    output       hdmi_out_clk_p,
    output [2:0] hdmi_out_data_n,
    output [2:0] hdmi_out_data_p
);

  localparam WIDTH = (RESOLUTION == "FULL_HD") ? 1920 : ((RESOLUTION == "HD") ? 1280 : ((RESOLUTION == "VGA") ? 640 : 800 ));
  localparam HEIGHT = (RESOLUTION == "FULL_HD") ? 1080 : ((RESOLUTION == "HD") ? 720  : ((RESOLUTION == "VGA") ? 480 : 600 ));
  localparam FRAME_DURATION = 60;

  localparam CHARACTER_SIZE = 32;
  localparam MARGIN = 25;
  localparam VERT_SPACING = 5;
  localparam HORZ_SPACING = 10;

  //character cells
  localparam VERT_SPACES = (WIDTH - MARGIN*2) / (CHARACTER_SIZE + VERT_SPACING) - 1;
  localparam HORZ_SPACES = (HEIGHT - MARGIN*2) / (CHARACTER_SIZE + HORZ_SPACING) - 1;

  //clocks
  wire pixelClk; // frequency according to RESOLUTION
  wire serialClk; // frequency = 5x pixelClk

  //reset
  wire rst_n;
  assign rst_n = ~rst;

  //aux
  reg [$clog2(60) - 1 : 0] time_counter;
  reg [32 - 1 : 0] second_counter;
  reg [8*3 - 1 : 0] romania;

  integer j, k;
  reg row_d;
  wire frame_finished;
  reg [8 - 1 : 0] frame_counter;

  //character memory
  reg [7 - 1 : 0] string [HORZ_SPACES - 1 : 0][VERT_SPACES - 1 : 0];
  wire [8 - 1 : 0] char_i;

  //vio activity detector
  wire [2 - 1 : 0] change_cntr;
  reg [2 - 1 : 0] change_cntr_d;
  wire char_changed;

  //memory interface
  reg [12 - 1 : 0] mem_addr;
  wire [CHARACTER_SIZE - 1 : 0] mem_out;

  //HDMI driver interface
  reg [8 * 3 - 1 : 0] fifo_data;
  wire [11 : 0] column;
  wire [10 : 0] row;
  
  //character cell counters
  wire[$clog2(VERT_SPACES + 1) - 1 : 0] char_x;
  wire[$clog2(HORZ_SPACES + 1) - 1 : 0] char_y;
  reg [$clog2(VERT_SPACES + 1) - 1 : 0] char_x_d;
  reg [$clog2(HORZ_SPACES + 1) - 1 : 0] char_y_d;

  //character cell pixel counters
  reg [$clog2(CHARACTER_SIZE + VERT_SPACING) - 1 : 0] x_ptr;
  reg [$clog2(CHARACTER_SIZE + HORZ_SPACING) - 1 : 0] y_ptr;

  //last character coordinates
  reg [8 - 1 : 0] last_char_x;
  reg [8 - 1 : 0] last_char_y;

  //clock generator
  clk_wiz_pixel_serial i_clk_wiz_pixel_serial (
      .clk_in1 (clk),
      .clk_out1(pixelClk),
      .clk_out2(serialClk)
  );

  //HDMI driver
  hdmi_drv #(
      .RESOLUTION(RESOLUTION)
  ) i_hdmi_drv (
      .pixelClk (pixelClk),      // frequency according to RESOLUTION
      .serialClk (serialClk),    // frequency = 5x pixelClk
      .rst_n (rst_n),            // Async reset, active low
      .cfg_enable (1'b1),        // module enable
      .fifo_data (fifo_data),
      .column (column),
      .row (row),
      .hdmi_out_clk_n (hdmi_out_clk_n),
      .hdmi_out_clk_p (hdmi_out_clk_p),
      .hdmi_out_data_n (hdmi_out_data_n),
      .hdmi_out_data_p (hdmi_out_data_p)
  );

  //vio
  vio_0 vio_i(
    .clk (pixelClk),
    .probe_out0 (char_i),
    .probe_out1 (change_cntr),
    .probe_in0 (last_char_x),
    .probe_in1 (last_char_y),
    .probe_in2 (second_counter)
  );

  //character texture atlas = memory
  blk_mem_gen_0 char_atlas (
      .clka (pixelClk),
      .wea  (1'b0),
      .addra(mem_addr),
      .dina (),
      .douta(mem_out)
  );

  //end of frame condition
  assign frame_finished = (row_d & ~row[10]);
  assign char_changed = (change_cntr_d != change_cntr);

  //character coordinates
  assign char_x = (column - MARGIN) / (CHARACTER_SIZE + VERT_SPACING);
  assign char_y = (row - MARGIN) / (CHARACTER_SIZE + HORZ_SPACING);

  //mem_addr
  always @(*) begin
     mem_addr <= ((string[char_y][char_x] / 10) * CHARACTER_SIZE * 10) + (string[char_y][char_x] % 10) + (y_ptr * 10);
  end
  
  //row MSB delay
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) row_d <= 1'b0;
    else row_d <= row[10];
  end
  
  //change_cntr delay
  always @(posedge pixelClk) begin
    change_cntr_d[1 : 0] <= change_cntr[1 : 0];
  end

  //char_x_d delay
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) char_x_d <= 'b0;
    else char_x_d <= char_x;
  end

  //char_y_d delay
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) char_y_d <= 'b0;
    else char_y_d <= char_y;
  end

  //frame_counter
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) frame_counter <= 'b0;
    else if (frame_counter == FRAME_DURATION) frame_counter <= 'b0;
    else if (frame_finished) frame_counter <= frame_counter + 1;
  end

  //time_counter
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) time_counter <= 'b0;
    else if (time_counter == 60) time_counter <= 'b0;
    else if (frame_finished) time_counter <= time_counter + 1;
  end

  //second_counter
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) second_counter <= 'b0;
    else if (time_counter == 60) second_counter <= second_counter + 1;
  end

  //x_ptr
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) x_ptr <= -1;
    else if ((char_x_d != char_x) | (column < MARGIN)) x_ptr <= -1;
    else x_ptr <= x_ptr + 1;
  end

  //y_ptr
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) y_ptr <= -1;
    else if ((char_y_d != char_y) | (row < MARGIN)) y_ptr <= -1;
    else if (column == 0) y_ptr <= y_ptr + 1;
  end

  //last_char_x
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) last_char_x <= 0;
    else if(char_changed) begin
      case(char_i)
        8'd3: if (last_char_x == 0) last_char_x <= VERT_SPACES; //backspace
              else last_char_x <= last_char_x - 1;

        8'd2: last_char_x <= 0; //enter

        8'd4: if(last_char_x == 0) last_char_x <= VERT_SPACES; //left arrow
              else last_char_x <= last_char_x - 1;

        8'd6: if(last_char_x == VERT_SPACES) last_char_x <= 0; //right arrow
              else last_char_x <= last_char_x + 1;
        
        default:  if (last_char_x == VERT_SPACES) last_char_x <= 0; //space
                  else last_char_x <= last_char_x + 1;
      endcase
    end
  end

  //last_char_y
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) last_char_y <= 0;
    else if(char_changed) begin
      case (char_i)
        8'd3: if (last_char_x == 0 & last_char_y != 0) last_char_y <= last_char_y - 1; //backspace

        8'd2: if(last_char_y == HORZ_SPACES) last_char_y <= 0; //enter
              else last_char_y <= last_char_y + 1;

        8'd8: if(last_char_y == 0) last_char_y <= HORZ_SPACES; //up arrow
              else last_char_y <= last_char_y - 1;

        8'd5: if(last_char_y == HORZ_SPACES) last_char_y <= 0; //down arrow
              else last_char_y <= last_char_y + 1;

        default:  if (last_char_y == HORZ_SPACES) last_char_y <= 0; //space
                  else if(last_char_x == VERT_SPACES) last_char_y <= last_char_y + 1;
      endcase
    end
  end

  //background
  always @(*) begin
    if(change_flag)
      if (column < WIDTH / 3) 
        romania <= {8'd0, 8'd43, 8'd127};
       else if (column < 2 * (WIDTH / 3)) 
        romania <= {8'd252, 8'd209, 8'd22};
       else 
        romania <= {8'd206, 8'd17, 8'd38};
    else
      romania <= {8'd255, 8'd255, 8'd255};
  end

  //set color
  always @(*) begin
    if ((x_ptr < CHARACTER_SIZE) & (y_ptr < CHARACTER_SIZE) & (row < HORZ_SPACES * (CHARACTER_SIZE + HORZ_SPACING)) & (column < VERT_SPACES * (CHARACTER_SIZE + VERT_SPACING))) begin
      if((char_x == last_char_x) & (char_y == last_char_y)) begin //flashing bar
        if((frame_counter < FRAME_DURATION /2) & (x_ptr < 5)) fifo_data <= {8'd0, 8'd0, 8'd0};
        else fifo_data <= romania;
      end else if (mem_out[CHARACTER_SIZE - 1 - x_ptr] == 0) fifo_data <= romania; //character
        else fifo_data <= {8'd0, 8'd0, 8'd0};
    end  
    else fifo_data <= romania; //blank screen
  end

  //char decoder and initializer
  always @(posedge pixelClk or negedge rst_n) begin
    if(~rst_n) begin
      for(j = 0; j < HORZ_SPACES; j = j + 1)
        for(k = 0; k < VERT_SPACES; k = k + 1)
         string[j][k] <= 0;
    end else if(char_changed) begin
      case (char_i)
        8'h41 : string[last_char_y][last_char_x] <= 33;  //A
        8'h42 : string[last_char_y][last_char_x] <= 34;  //B
        8'h43 : string[last_char_y][last_char_x] <= 35;  //C
        8'h44 : string[last_char_y][last_char_x] <= 36;  //D
        8'h45 : string[last_char_y][last_char_x] <= 37;  //E
        8'h46 : string[last_char_y][last_char_x] <= 38;  //F
        8'h47 : string[last_char_y][last_char_x] <= 39;  //G
        8'h48 : string[last_char_y][last_char_x] <= 40;  //H
        8'h49 : string[last_char_y][last_char_x] <= 41;  //I
        8'h4a : string[last_char_y][last_char_x] <= 42;  //J
        8'h4b : string[last_char_y][last_char_x] <= 43;  //K
        8'h4c : string[last_char_y][last_char_x] <= 44;  //L
        8'h4d : string[last_char_y][last_char_x] <= 45;  //M
        8'h4e : string[last_char_y][last_char_x] <= 46;  //N
        8'h4f : string[last_char_y][last_char_x] <= 47;  //O
        8'h50 : string[last_char_y][last_char_x] <= 48;  //P
        8'h51 : string[last_char_y][last_char_x] <= 49;  //Q
        8'h52 : string[last_char_y][last_char_x] <= 50;  //R
        8'h53 : string[last_char_y][last_char_x] <= 51;  //S
        8'h54 : string[last_char_y][last_char_x] <= 52;  //T
        8'h55 : string[last_char_y][last_char_x] <= 53;  //U
        8'h56 : string[last_char_y][last_char_x] <= 54;  //V
        8'h57 : string[last_char_y][last_char_x] <= 55;  //W
        8'h58 : string[last_char_y][last_char_x] <= 56;  //X
        8'h59 : string[last_char_y][last_char_x] <= 57;  //Y
        8'h5a : string[last_char_y][last_char_x] <= 58;  //Z
        8'h61 : string[last_char_y][last_char_x] <= 65;  //a
        8'h62 : string[last_char_y][last_char_x] <= 66;  //b
        8'h63 : string[last_char_y][last_char_x] <= 67;  //c
        8'h64 : string[last_char_y][last_char_x] <= 68;  //d
        8'h65 : string[last_char_y][last_char_x] <= 69;  //e
        8'h66 : string[last_char_y][last_char_x] <= 70;  //f
        8'h67 : string[last_char_y][last_char_x] <= 71;  //g
        8'h68 : string[last_char_y][last_char_x] <= 72;  //h
        8'h69 : string[last_char_y][last_char_x] <= 73;  //i
        8'h6a : string[last_char_y][last_char_x] <= 74;  //j
        8'h6b : string[last_char_y][last_char_x] <= 75;  //k
        8'h6c : string[last_char_y][last_char_x] <= 76;  //l
        8'h6d : string[last_char_y][last_char_x] <= 77;  //m
        8'h6e : string[last_char_y][last_char_x] <= 78;  //n
        8'h6f : string[last_char_y][last_char_x] <= 79;  //o
        8'h70 : string[last_char_y][last_char_x] <= 80;  //p
        8'h71 : string[last_char_y][last_char_x] <= 81;  //q
        8'h72 : string[last_char_y][last_char_x] <= 82;  //r
        8'h73 : string[last_char_y][last_char_x] <= 83;  //s
        8'h74 : string[last_char_y][last_char_x] <= 84;  //t
        8'h75 : string[last_char_y][last_char_x] <= 85;  //u
        8'h76 : string[last_char_y][last_char_x] <= 86;  //v
        8'h77 : string[last_char_y][last_char_x] <= 87;  //w
        8'h78 : string[last_char_y][last_char_x] <= 88;  //x
        8'h79 : string[last_char_y][last_char_x] <= 89;  //y
        8'h7a : string[last_char_y][last_char_x] <= 90;  //z
        8'h30 : string[last_char_y][last_char_x] <= 16;  //0
        8'h31 : string[last_char_y][last_char_x] <= 17;  //1
        8'h32 : string[last_char_y][last_char_x] <= 18;  //2
        8'h33 : string[last_char_y][last_char_x] <= 19;  //3
        8'h34 : string[last_char_y][last_char_x] <= 20;  //4
        8'h35 : string[last_char_y][last_char_x] <= 21;  //5
        8'h36 : string[last_char_y][last_char_x] <= 22;  //6
        8'h37 : string[last_char_y][last_char_x] <= 23;  //7
        8'h38 : string[last_char_y][last_char_x] <= 24;  //8
        8'h39 : string[last_char_y][last_char_x] <= 25;  //9
        8'h3a : string[last_char_y][last_char_x] <= 1;   //!
        8'h3b : string[last_char_y][last_char_x] <= 3;   //#
        8'h3c : string[last_char_y][last_char_x] <= 4;   //$
        8'h3d : string[last_char_y][last_char_x] <= 5;   //%
        8'h3e : string[last_char_y][last_char_x] <= 6;   //&
        8'h3f : string[last_char_y][last_char_x] <= 8;   //(
        8'h20 : string[last_char_y][last_char_x] <= 9;   //)
        8'h21 : string[last_char_y][last_char_x] <= 10;  //*
        8'h22 : string[last_char_y][last_char_x] <= 11;  //+
        8'h23 : string[last_char_y][last_char_x] <= 12;  //.
        8'h24 : string[last_char_y][last_char_x] <= 13;  //-
        8'h25 : string[last_char_y][last_char_x] <= 26;  //:
        8'h26 : string[last_char_y][last_char_x] <= 28;  //<
        8'h27 : string[last_char_y][last_char_x] <= 29;  //=
        8'h28 : string[last_char_y][last_char_x] <= 30;  //>
        8'h29 : string[last_char_y][last_char_x] <= 31;  //?
        8'h2a : string[last_char_y][last_char_x] <= 32;  //@
        8'h2b : string[last_char_y][last_char_x] <= 15;  ///
        default : string[last_char_y][last_char_x] <= 0;  //empty space
      endcase
    end
  end

endmodule
