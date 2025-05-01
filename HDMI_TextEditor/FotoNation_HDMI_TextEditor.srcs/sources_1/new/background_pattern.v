`timescale 1ns / 1ns

module background_pattern #(
    WIDTH  = 1280,
    HEIGHT = 720
) (
    input change_flag,
    input pixelClk,
    input eof_event,

    input [11 : 0] column,
    input [10 : 0] row,
    output reg [8*3 -1 : 0] fifo_data
);

  localparam BIG_R = 200;
  localparam SMALL_R = BIG_R / 2;
  
  reg [7 - 1 : 0] frame_counter;
  reg [8*3 - 1 : 0] romania;
  reg [8*3 - 1 : 0] ukraine;
  reg [8*3 - 1 : 0] koreea;

  always @(posedge pixelClk) begin
    if (frame_counter == 120) begin
      frame_counter <= {7{1'b0}};
    end else if (eof_event) begin
      frame_counter <= frame_counter + 1;
    end
  end

  always @(*) begin
    if (column < WIDTH / 3) begin
      romania <= {8'd0, 8'd43, 8'd127};
    end else if (column < 2 * (WIDTH / 3)) begin
      romania <= {8'd252, 8'd209, 8'd22};
    end else begin
      romania <= {8'd206, 8'd17, 8'd38};
    end
  end

  always @(*) begin
    if (row < HEIGHT / 2) begin
      ukraine <= {8'd0, 8'd87, 8'd183};
    end else begin
      ukraine <= {8'd255, 8'd215, 8'd2};
    end
  end

  always @(*) begin
    if (((row - HEIGHT / 2) ** 2) + ((column - WIDTH / 2 - SMALL_R) ** 2) < (SMALL_R ** 2)) begin
      koreea <= {8'd15, 8'd100, 8'd205};  //right
    end else if(((row - HEIGHT / 2) ** 2) + ((column - WIDTH / 2 + SMALL_R) ** 2) < (SMALL_R ** 2)) begin
      koreea <= {8'd205, 8'd46, 8'd58};  //left
    end else if((((row - HEIGHT / 2) ** 2) + ((column - WIDTH / 2) ** 2) < (BIG_R ** 2)) & (row < HEIGHT / 2)) begin
      koreea <= {8'd205, 8'd46, 8'd58};  //up
    end else if((((row - HEIGHT / 2) ** 2) + ((column - WIDTH / 2) ** 2) < (BIG_R ** 2)) & (row >= HEIGHT / 2)) begin
      koreea <= {8'd15, 8'd100, 8'd205};  //down
    end else begin
      koreea <= {8'd255, 8'd255, 8'd255};
    end
  end

  always @(*) begin
    if (~change_flag) begin
      if (frame_counter < 60) begin
        fifo_data <= romania;
      end else begin
        fifo_data <= ukraine;
      end
    end else begin
        fifo_data <= koreea;
    end
  end

endmodule
