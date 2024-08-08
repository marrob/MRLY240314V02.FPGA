
//ha clk_in: 50000000Hz és DIVISOR: 50000000 akkor clk_out: 1Hz
//DIVISOR = clk_in/clk_out, DIVISOR = 25000000/10000000

//forrás: https://www.fpga4student.com/2017/08/verilog-code-for-clock-divider-on-fpga.html
module fdiv_v2 
  #(parameter DIVISOR = 28'd50000000)(
  input wire reset,
  input wire clk_in,
  output reg clk_out
);
  reg [27:0] cnt = 28'd0;

  always @(posedge clk_in)
    if(reset) begin
      cnt <= 0;
      clk_out <=0;
   end else begin
      cnt <= cnt + 28'd1;

      if(cnt >= (DIVISOR-1))
        cnt <= 28'd0;
        
      if(cnt < DIVISOR/2) 
        clk_out <=1'b1;
      else
        clk_out <=1'b0;
   end
endmodule