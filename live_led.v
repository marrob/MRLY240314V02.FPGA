//clk:PIN_23, led: PIN_87
//led_blink.v
module live_led(input clk, output reg led);
  reg[24:0]cnt = 25'd0;
  always@(posedge clk) begin
    cnt<=cnt + 25'd1;
    if(cnt == 25'd25000000)begin
      led <=~led;
      cnt <= 25'd0;
    end
  end
endmodule


`timescale 10ps/1ps
module live_led_tb();
  reg clk;
  wire led;
  integer i;
  live_led uut(.clk(clk), .led(led));
  initial begin
    clk = 1'd0;
    for(i=0; i<10; i = i + 1)
     #1 clk = ~clk;
  end
endmodule