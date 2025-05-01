`timescale 1ns / 1ps

module pattern_blue (
    input pixelClk,
    input rst_n,

    input stop_motion,
    input advance_frame_btn,

    input fifo_pop,
    input [11 : 0] column,
    input [10 : 0] row,
    output reg [8*3 - 1 : 0] fifo_data
);

  localparam WIDTH = 1280;
  localparam HEIGHT = 720;

  localparam BALL_AMOUNT = 6;
  localparam SEED = 1841635546;

  //aux
  wire frame_finished;
  reg advance_frame_btn_d;  //advance_frame_btn_d delay
  reg row_d;  //row delay
  integer j;

  //memory block for keeping track of line data
  reg [$clog2(BALL_AMOUNT + 2) - 1 : 0] finished_ball;
  reg [$clog2(BALL_AMOUNT + 1) - 1 : 0] mem[HEIGHT - 1 : 0];
  reg [10 : 0] mem_pointer;
  wire [4 - 1 : 0] line_height;

  //used for generate block
  genvar i;
  wire [BALL_AMOUNT : 0] finished_falling;
  wire [8*3 - 1 : 0] colors[BALL_AMOUNT : 0];

  //row MSB delay
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) row_d <= 1'b0;
    else row_d <= row[10];
  end

  //row MSB delay
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) advance_frame_btn_d <= 1'b0;
    else advance_frame_btn_d <= advance_frame_btn_d;
  end

  assign frame_finished = (row_d & ~row[10]) & (~stop_motion | advance_frame_btn);

  generate
    for (i = 0; i < BALL_AMOUNT; i = i + 1) begin : generate_balls
      moving_circle #(
          .WIDTH (WIDTH),
          .HEIGHT(HEIGHT),

          .CFG_XC      ((WIDTH / (BALL_AMOUNT + 1)) * (i + 1)),  //random 10 bit number
          .CFG_R       ((SEED >> i) & {5{1'b1}}),                //random 6 bit number
          .CFG_COLOR   ((SEED >> i * 2) & {24{1'b1}}),           //random 24 bit color
          .ACCELERATION(((SEED >> i * 2) & {2{1'b1}}) + 1),      //random 2 bit color

          .FRAME_DURATION(2)
      ) moving_circle_i (
          .pixelClk(pixelClk),
          .rst_n(rst_n),

          .frame_finished(frame_finished),  //active if switch isn't active and a frame is finished

          .mem_pointer(mem_pointer),
          .finished_falling(finished_falling[i]),

          .fifo_pop(fifo_pop),
          .column(column),
          .row(row),
          .color_in(colors[i]),
          .color_out(colors[i+1])
      );
    end
  endgenerate

  assign line_height = SEED >> (finished_ball - 1);

  //finished_ball
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) finished_ball <= 'b0;
    else if (finished_ball != 0) finished_ball <= 'b0;
    else begin
      for (j = 0; j < BALL_AMOUNT; j = j + 1) if (finished_falling[j]) finished_ball <= j + 1;
    end
  end

  //memory
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) begin
      for (j = 0; j < HEIGHT; j = j + 1) mem[j] <= 'b0;
    end else begin
      if (finished_ball != 0)
        for (j = 0; j <= line_height; j = j + 1) mem[mem_pointer+j] <= finished_ball - 1;
    end
  end

  //mem_pointer
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) mem_pointer <= 'b0;
    else if (mem_pointer >= HEIGHT) mem_pointer <= 'b0;
    else begin
      for (j = 0; j < BALL_AMOUNT; j = j + 1)
        if (finished_ball != 0) mem_pointer <= mem_pointer + line_height;
    end
  end

  //background color
  assign colors[0] = {8'd200, 8'd200, 8'd200};

  //fill color
  always @(*) begin
    if (HEIGHT - row <= mem_pointer) fifo_data <= ((SEED >> mem[HEIGHT-row] * 2) & {24{1'b1}});
    else fifo_data <= colors[BALL_AMOUNT];
  end

endmodule
