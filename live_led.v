`timescale 10ps/1ps
//clk:PIN_23, led: PIN_87, reset: PIN_25
//live_led.v
module live_led
#(parameter COUNT_UP_TO = 26'd25000000)(
  input wire reset,
  input wire clk,
  output reg led
);
  
  reg[25:0]cnt = 26'd0;
  always@(posedge clk or posedge reset)
  begin
    if(reset)
    begin
      led <= 1'd0;
      cnt <= 26'd0;
    end
    else
    begin
      cnt <= cnt + 26'd1;
      if(cnt == COUNT_UP_TO)
      begin
        led <= ~led;
        cnt <= 26'd0;
      end
    end
  end
endmodule

//--- Unit Tests --------------------------------------------------------------
module live_led__basics_tb();
  reg clk,
      reset;
  wire led;
  integer i;
  live_led #(.COUNT_UP_TO(2)) uut(
    .reset_n(reset),
    .clk(clk), 
    .led(led)
);
  initial
  begin
    reset = 1'd0;
    clk =   1'd0;
     
#1  reset = 1'd1;

    for(i=0; i < 10; i = i + 1)
    begin
     #1 clk = 1;
     #1 clk = 0;
    end
  end
endmodule 

