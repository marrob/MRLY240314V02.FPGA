//clk:PIN_23, led: PIN_87
//led_blink.v
module live_led(
  input clk,
  input reset,
  output reg led
);
  reg[25:0]cnt;
  
  always@(posedge clk or posedge reset)
    if(reset)begin 
      cnt = 0;
      led = 0;
    end else begin
      cnt<=cnt + 26'd1;
      if(cnt == 26'd50000000)begin
        led <=~led;
        cnt <= 26'd0;
      end
    end
endmodule


`timescale 10ps/1ps
module live_led_tb();
  reg clk, reset;
  wire led;
  integer i;
  
  live_led uut(.reset(reset), .clk(clk), .led(led));
  initial begin
    clk = 1'd0;
    for(i=0; i<10; i = i + 1)
     #1 clk = ~clk;
  end
endmodule