`timescale 10ps/1ps

module mem2spi_slave
  #(parameter WIDTH = 16)(
  input wire reset,
  input wire spi_clk,
  input wire cs_n,
  input wire mosi,
  output wire miso,
  input wire[WIDTH - 1:0] memory
);

  reg [WIDTH-1:0]data_shift;
  assign miso = data_shift[WIDTH-1];
  
  always @(negedge spi_clk or posedge cs_n or posedge reset)
  if (reset)
    data_shift <= { WIDTH{1'b0}};
  else
  if(cs_n)
     data_shift <= memory;
  else
    data_shift <= data_shift << 1;
    

endmodule


module mem2spi_slave__basics_tb();
  reg clk,
      cs_n;
  wire mosi,
       miso;
       
  reg [7:0] data;
  reg [47:0] memory;
  
  integer i,j, k;
  
  localparam WIDTH = 48;
  
  mem2spi_slave #(.WIDTH(WIDTH)) uut (
    .spi_clk(clk),
    .cs_n(cs_n),
    .mosi(mosi),
    .miso(miso),
    .memory(memory)
  );

  initial begin

   #1 memory[7:0] =   8'h43;
      memory[15:8] =  8'h0F;
      memory[23:16] = 8'h00;
      memory[31:24] = 8'h55;
      memory[39:32] = 8'hAA;
      memory[47:40] = 8'h01;
      clk = 0;
      cs_n = 1;
      data = 8'hx;

   #1 cs_n = 0;
    
    for(j = 0; j < 6 ;  j = j + 1) //bytes
    begin
      for(i = 0; i < 8; i = i + 1) //bits
      begin
        #1 clk = 1;
        data = {data[6:0], miso};
        #1 clk = 0;
      end
      $display("%m byte index: %d, value: %2h", j, data );
    end
    
    #1 cs_n = 1;
  end
endmodule
