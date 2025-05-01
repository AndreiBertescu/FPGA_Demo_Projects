`timescale 1ns / 1ps

module moving_circle #(
    WIDTH  = 1280,
    HEIGHT = 720,

    CFG_XC = WIDTH / 2,
    CFG_R = 20,
    CFG_COLOR = {8'd255, 8'd0, 8'd0},

    ACCELERATION = 1,  //pixels per second^2
    FRAME_DURATION = 2
) (
    input pixelClk,
    input rst_n,

    input frame_finished,  //active if switch isn't active and a frame is finished

    input [8 - 1 : 0] mem_pointer,
    output reg finished_falling,

    input fifo_pop,
    input [11 : 0] column,
    input [10 : 0] row,
    input [8*3 - 1 : 0] color_in,
    output reg [8*3 - 1 : 0] color_out
);

  reg [10 : 0] center_y;
  reg [8 - 1 : 0] frame_counter;
  reg [8 - 1 : 0] velocity;

  wire ball_finished_falling;
  assign ball_finished_falling = center_y >= (HEIGHT + CFG_R - mem_pointer);

  //frame_counter
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) frame_counter <= 'b0;
    else if (frame_counter == FRAME_DURATION) frame_counter <= 'b0;
    else if (frame_finished) frame_counter <= frame_counter + 1;
  end

  //velocity
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) velocity <= 'b0;
    else if (ball_finished_falling) velocity <= 'b0;
    else if (frame_counter == FRAME_DURATION) velocity <= velocity + ACCELERATION;
  end

  //center_y
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) center_y <= CFG_R;
    else if (ball_finished_falling) center_y <= CFG_R;
    else if (frame_counter == FRAME_DURATION) center_y <= center_y + velocity;
  end

  //finished_falling
  always @(posedge pixelClk or negedge rst_n) begin
    if (~rst_n) finished_falling <= 1'b0;
    else if (finished_falling) finished_falling <= 1'b0;
    else if (ball_finished_falling) finished_falling <= 1'b1;
  end

  //assign colors
  assign in_circle = (column - CFG_XC) ** 2 + (row - center_y) ** 2 <= CFG_R ** 2;

  always @(*) begin
    if (in_circle) color_out <= CFG_COLOR;
    else color_out <= color_in;
  end

endmodule
