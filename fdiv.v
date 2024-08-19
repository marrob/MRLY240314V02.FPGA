`timescale 10ps/1ps
module fdiv 
  #( parameter DIVISOR = 2 )(
  input wire clk_in,
  input wire reset,
  output reg clk_out
);

  reg [31:0] cnt = 0;

  always @(posedge clk_in or posedge reset) begin
    if (reset) begin
      cnt <= 0;
      clk_out <= 0;
    end else begin
      if (cnt == (DIVISOR/2 - 1)) begin
          cnt <= 0;
          clk_out <= ~clk_out;
      end else begin
          cnt <= cnt + 1;
      end
    end
  end
endmodule

//--- Unit Tests --------------------------------------------------------------