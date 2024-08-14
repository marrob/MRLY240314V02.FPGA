/* reset: minden kimenet stabil állapotba állítja
 * clk: felfutó élre léptet
 * data: a kiküldendő párhuzamos adtok szélessége a paraméterben adható meg
 * sclk: tpic felé menő órajel... nem kell órajel reset és rck adásakor a tpic-nek részletesen az adatlappban
 * clr_n: reset-ben az első órajelig alacsony
 * rck: miután kiment az összes bit, azután jön egy rck impulzus ami a TPIC-ben a shiftregiszterek tartalmát átírja a kimentre
 * sout: a soros kiment
 */
module mem2tpic
  #(parameter WIDTH = 16)(
  input clk,
  input reset,
  input [WIDTH-1:0]data,
  output reg sclk,
  output reg en_n,
  output reg rck,
  output sout
);
  
  reg [31:0]bit_index = 0; // 0..WIDTH-1
  reg [WIDTH-1:0]shift_reg = 8'h00;
  reg [1:0]state = 0;
  
  localparam S_START =  2'h0;
  localparam S_TX    =  2'h1;
  localparam S_CLK   =  2'h2;
  localparam S_WR    =  2'h3;
  assign sout = shift_reg[0];
  
  always @ (posedge clk or posedge reset) begin
  if(reset) begin
    sclk <= 1'b0;
    en_n <= 1'h1;
    rck <= 1'b0;
    bit_index <= 32'd0;
    shift_reg = 32'h5555; //{WIDTH{1'b0}};
    state <= S_START;
  end else begin
    case(state)
      S_START: begin
        sclk <= 1'b1;
        en_n <= 1'b0;
        rck <= 1'b0;
        shift_reg <= data;
        state <= S_TX;
      end
      S_TX: begin
        sclk <= 1'b0;
        shift_reg <= { 1'b0, shift_reg[WIDTH-1:1]};
        bit_index <= bit_index + 1'd1;
        state <= S_CLK;
       end
       S_CLK: begin
         if(bit_index == WIDTH) begin
            bit_index <= 0;
            rck <= 1'b1;
            state <= S_WR;
          end else begin
            sclk <= 1'b1;
            state <= S_TX;
          end
       end
        S_WR: begin
          rck <= 1'b0;
          state <= S_START;
        end
     endcase
    end
  end
endmodule

`timescale 10ps/1ps
module mem2tpic_tb();
  localparam WIDTH = 300;
  reg clk, rst, en_n;
  reg [WIDTH-1:0]data;
  wire sclk, rck, sdata;
  integer i;
  mem2tpic #(.WIDTH(WIDTH)) uut (.reset(rst), .clk(clk), .data(data), .sclk(sclk), .en_n(en_n), .rck(rck), .sout(sdata));
  initial begin
    #1 clk = 0; en_n = 0;
    #1 rst = 1; #1 rst = 0;
    #1 data = 16'hAAAA;
    for(i = 0; i < 3000; i=i+1)
      #1 clk = ~clk;
  end
endmodule