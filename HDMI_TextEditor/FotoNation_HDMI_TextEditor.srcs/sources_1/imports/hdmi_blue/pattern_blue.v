module pattern_blue (
    input pixelClk,
    input rst_n,

    input [11:0] column,
    input [10:0] row,
    output reg [8*3 - 1 : 0] fifo_data
);

  localparam WIDTH = 1280;
  localparam HEIGHT = 720;
  localparam FRAME_DURATION = 60;

  localparam CHARACTER_SIZE = 32;
  localparam MARGIN = 25;
  localparam VERT_SPACING = 5;
  localparam HORZ_SPACING = 10;

  //character cells
  localparam VERT_SPACES = (WIDTH - MARGIN*2) / (CHARACTER_SIZE + VERT_SPACING);
  localparam HORZ_SPACES = (HEIGHT - MARGIN*2) / (CHARACTER_SIZE + HORZ_SPACING);
  
  //aux
  reg [$clog2(60) - 1 : 0] time_counter;
  reg [32 - 1 : 0] second_counter;

  integer j, k;
  reg row_d;
  wire frame_finished;
  reg [8 - 1 : 0] frame_counter;

  //character memory
  reg[12 - 1 : 0] string [HORZ_SPACES - 1 : 0][VERT_SPACES - 1 : 0];
  wire [8 - 1 : 0] char_i;

  //vio activity detector
  wire [2 - 1 : 0] change_cntr;
  reg [2 - 1 : 0] change_cntr_d;
  wire char_changed;

  //memory interface
  reg [12 - 1 : 0] mem_addr;
  wire [CHARACTER_SIZE - 1 : 0] mem_out;
  
  //character cell counters
  wire[$clog2(VERT_SPACES + 1) - 1 : 0] char_x;
  wire[$clog2(HORZ_SPACES + 1) - 1 : 0] char_y;
  reg [$clog2(VERT_SPACES + 1) - 1 : 0] char_x_d;
  reg [$clog2(HORZ_SPACES + 1) - 1 : 0] char_y_d;

  //character cell pixel counters
  reg [$clog2(CHARACTER_SIZE + VERT_SPACING) - 1 : 0] x_ptr;
  reg [$clog2(CHARACTER_SIZE + HORZ_SPACING) - 1 : 0] y_ptr;

  //last character coordinates
  reg [$clog2(CHARACTER_SIZE + VERT_SPACING) - 1 : 0] last_char_x;
  reg [$clog2(CHARACTER_SIZE + HORZ_SPACING) - 1 : 0] last_char_y;

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
     mem_addr <= string[char_y][char_x] + (y_ptr * 10);
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

        default:  if (last_char_y == HORZ_SPACES) last_char_y <= 0; //space
                  else if(last_char_x == VERT_SPACES) last_char_y <= last_char_y + 1;
      endcase
    end
  end

  //set color
  always @(*) begin
    if ((x_ptr < CHARACTER_SIZE) & (y_ptr < CHARACTER_SIZE) & (row < HEIGHT - MARGIN) & (column < WIDTH - MARGIN)) begin
      if((char_x == last_char_x) & (char_y == last_char_y)) begin //flashing bar
        if((frame_counter < FRAME_DURATION /2) & (x_ptr < 5)) fifo_data <= {8'd255, 8'd255, 8'd255};
        else fifo_data <= {8'd0, 8'd0, 8'd0};
      end else if (mem_out[CHARACTER_SIZE - 1 - x_ptr] == 0) fifo_data <= {8'd0, 8'd0, 8'd0}; //character
        else fifo_data <= {8'd255, 8'd255, 8'd255};
    end  
    else fifo_data <= {8'd0, 8'd0, 8'd0}; //blank screen
  end

  //char decoder and initializer
  always @(posedge pixelClk or negedge rst_n) begin
    if(~rst_n) begin
      for(j = 0; j < HORZ_SPACES; j = j + 1)
        for(k = 0; k < VERT_SPACES; k = k + 1)
         string[j][k] <= 0;
    end else if(char_changed) begin
      case (char_i)
        8'h41 : string[last_char_y][last_char_x] <= 30 * CHARACTER_SIZE + 3;  //A
        8'h42 : string[last_char_y][last_char_x] <= 30 * CHARACTER_SIZE + 4;  //B
        8'h43 : string[last_char_y][last_char_x] <= 30 * CHARACTER_SIZE + 5;  //C
        8'h44 : string[last_char_y][last_char_x] <= 30 * CHARACTER_SIZE + 6;  //D
        8'h45 : string[last_char_y][last_char_x] <= 30 * CHARACTER_SIZE + 7;  //E
        8'h46 : string[last_char_y][last_char_x] <= 30 * CHARACTER_SIZE + 8;  //F
        8'h47 : string[last_char_y][last_char_x] <= 30 * CHARACTER_SIZE + 9;  //G
        8'h48 : string[last_char_y][last_char_x] <= 40 * CHARACTER_SIZE;      //H
        8'h49 : string[last_char_y][last_char_x] <= 40 * CHARACTER_SIZE + 1;  //I
        8'h4a : string[last_char_y][last_char_x] <= 40 * CHARACTER_SIZE + 2;  //J
        8'h4b : string[last_char_y][last_char_x] <= 40 * CHARACTER_SIZE + 3;  //K
        8'h4c : string[last_char_y][last_char_x] <= 40 * CHARACTER_SIZE + 4;  //L
        8'h4d : string[last_char_y][last_char_x] <= 40 * CHARACTER_SIZE + 5;  //M
        8'h4e : string[last_char_y][last_char_x] <= 40 * CHARACTER_SIZE + 6;  //N
        8'h4f : string[last_char_y][last_char_x] <= 40 * CHARACTER_SIZE + 7;  //O
        8'h50 : string[last_char_y][last_char_x] <= 40 * CHARACTER_SIZE + 8;  //P
        8'h51 : string[last_char_y][last_char_x] <= 40 * CHARACTER_SIZE + 9;  //Q
        8'h52 : string[last_char_y][last_char_x] <= 50 * CHARACTER_SIZE;      //R
        8'h53 : string[last_char_y][last_char_x] <= 50 * CHARACTER_SIZE + 1;  //S
        8'h54 : string[last_char_y][last_char_x] <= 50 * CHARACTER_SIZE + 2;  //T
        8'h55 : string[last_char_y][last_char_x] <= 50 * CHARACTER_SIZE + 3;  //U
        8'h56 : string[last_char_y][last_char_x] <= 50 * CHARACTER_SIZE + 4;  //V
        8'h57 : string[last_char_y][last_char_x] <= 50 * CHARACTER_SIZE + 5;  //W
        8'h58 : string[last_char_y][last_char_x] <= 50 * CHARACTER_SIZE + 6;  //X
        8'h59 : string[last_char_y][last_char_x] <= 50 * CHARACTER_SIZE + 7;  //Y
        8'h5a : string[last_char_y][last_char_x] <= 50 * CHARACTER_SIZE + 8;  //Z
        8'h61 : string[last_char_y][last_char_x] <= 60 * CHARACTER_SIZE + 5;  //a
        8'h62 : string[last_char_y][last_char_x] <= 60 * CHARACTER_SIZE + 6;  //b
        8'h63 : string[last_char_y][last_char_x] <= 60 * CHARACTER_SIZE + 7;  //c
        8'h64 : string[last_char_y][last_char_x] <= 60 * CHARACTER_SIZE + 8;  //d
        8'h65 : string[last_char_y][last_char_x] <= 60 * CHARACTER_SIZE + 9;  //e
        8'h66 : string[last_char_y][last_char_x] <= 70 * CHARACTER_SIZE;      //f
        8'h67 : string[last_char_y][last_char_x] <= 70 * CHARACTER_SIZE + 1;  //g
        8'h68 : string[last_char_y][last_char_x] <= 70 * CHARACTER_SIZE + 2;  //h
        8'h69 : string[last_char_y][last_char_x] <= 70 * CHARACTER_SIZE + 3;  //i
        8'h6a : string[last_char_y][last_char_x] <= 70 * CHARACTER_SIZE + 4;  //j
        8'h6b : string[last_char_y][last_char_x] <= 70 * CHARACTER_SIZE + 5;  //k
        8'h6c : string[last_char_y][last_char_x] <= 70 * CHARACTER_SIZE + 6;  //l
        8'h6d : string[last_char_y][last_char_x] <= 70 * CHARACTER_SIZE + 7;  //m
        8'h6e : string[last_char_y][last_char_x] <= 70 * CHARACTER_SIZE + 8;  //n
        8'h6f : string[last_char_y][last_char_x] <= 70 * CHARACTER_SIZE + 9;  //o
        8'h70 : string[last_char_y][last_char_x] <= 80 * CHARACTER_SIZE;      //p
        8'h71 : string[last_char_y][last_char_x] <= 80 * CHARACTER_SIZE + 1;  //q
        8'h72 : string[last_char_y][last_char_x] <= 80 * CHARACTER_SIZE + 2;  //r
        8'h73 : string[last_char_y][last_char_x] <= 80 * CHARACTER_SIZE + 3;  //s
        8'h74 : string[last_char_y][last_char_x] <= 80 * CHARACTER_SIZE + 4;  //t
        8'h75 : string[last_char_y][last_char_x] <= 80 * CHARACTER_SIZE + 5;  //u
        8'h76 : string[last_char_y][last_char_x] <= 80 * CHARACTER_SIZE + 6;  //v
        8'h77 : string[last_char_y][last_char_x] <= 80 * CHARACTER_SIZE + 7;  //w
        8'h78 : string[last_char_y][last_char_x] <= 80 * CHARACTER_SIZE + 8;  //x
        8'h79 : string[last_char_y][last_char_x] <= 80 * CHARACTER_SIZE + 9;  //y
        8'h7a : string[last_char_y][last_char_x] <= 90 * CHARACTER_SIZE;      //z
        8'h30 : string[last_char_y][last_char_x] <= 10 * CHARACTER_SIZE + 6;  //0
        8'h31 : string[last_char_y][last_char_x] <= 10 * CHARACTER_SIZE + 7;  //1
        8'h32 : string[last_char_y][last_char_x] <= 10 * CHARACTER_SIZE + 8;  //2
        8'h33 : string[last_char_y][last_char_x] <= 10 * CHARACTER_SIZE + 9;  //3
        8'h34 : string[last_char_y][last_char_x] <= 20 * CHARACTER_SIZE;      //4
        8'h35 : string[last_char_y][last_char_x] <= 20 * CHARACTER_SIZE + 1;  //5
        8'h36 : string[last_char_y][last_char_x] <= 20 * CHARACTER_SIZE + 2;  //6
        8'h37 : string[last_char_y][last_char_x] <= 20 * CHARACTER_SIZE + 3;  //7
        8'h38 : string[last_char_y][last_char_x] <= 20 * CHARACTER_SIZE + 4;  //8
        8'h39 : string[last_char_y][last_char_x] <= 20 * CHARACTER_SIZE + 5;  //9
        default : string[last_char_y][last_char_x] <= 0;  //empty space
      endcase
    end
  end

endmodule
