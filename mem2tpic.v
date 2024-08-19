`timescale 10ps/1ps
module mem2tpic
  #(parameter WIDTH = 16)(
  input clk,             //felfutó élre lépteti az állapotgéet
  input reset,           //minden kimenet stabil állapotba állítja
  input [WIDTH-1:0]data, //a kiküldendő párhuzamos adtok, a szélessége a paraméterben adható meg
  output reg sclk,       //tpic felé menő órajel...
  output reg g_n,        //tpic kimenetet kapuzza, nullara aktiv a kimenet
  output reg rck,        //miután kiment az összes bit (WIDTH), azután jön egy "clk" preiodussal egy rck impulzus ami egy "clk" hosszú a TPIC-ben a shiftregiszterek tartalmát átírja a kimentre
  output sout            //sout: a soros kiment
);
  reg [31:0]bit_index = 0; // 0..WIDTH-1
  reg [WIDTH-1:0]shift_reg = 'h00;
  reg [1:0]state = 0;
  
  localparam S_START =  2'h0;
  localparam S_TX    =  2'h1;
  localparam S_CLK   =  2'h2;
  localparam S_WR    =  2'h3;
  
  assign sout = shift_reg[WIDTH-1]; //MSB First Out
  
  integer i;
  
  always @ (posedge clk or posedge reset) begin
  if(reset) begin
    sclk <= 1'b0;
    g_n <= 1'h1;
    rck <= 1'b0;
    bit_index <= 32'd0;
    shift_reg = 'd0;
    state <= S_START;
  end else begin
    case(state)
      S_START: begin
        sclk <= 1'b1;
        g_n <= 1'b0;
        rck <= 1'b0;
        state <= S_TX;
        shift_reg <= data;
        
        /*
        shift_reg[0] = 1'b1; //a debug panelen az elso 3 LED
        shift_reg[1] = 1'b1;
        shift_reg[2] = 1'b1;
        
        shift_reg[WIDTH-1] = 1'b1; // a debug panelen az utolso 4db LED
        shift_reg[WIDTH-2] = 1'b1;
        shift_reg[WIDTH-3] = 1'b1;
        shift_reg[WIDTH-4] = 1'b1;
        */
        
      end
      S_TX: begin
        sclk <= 1'b0;
        shift_reg <= shift_reg << 1; //{ 1'b0, shift_reg[WIDTH-1:1]};
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

//--- Unit Tests --------------------------------------------------------------
module mem2tpic__basic_tb();

  localparam WIDTH = 32;
  reg clk,
      reset;
      
  reg [WIDTH-1:0]data;
  
  wire sclk,
       rck,
       sdata;
 
  integer i;

  mem2tpic #(.WIDTH(WIDTH)) uut (
    .reset(reset),
    .clk(clk),
    .data(data),
    .sclk(sclk),
    .rck(rck),
    .sout(sdata)
);
  
  initial begin
    #1 clk = 0;
       reset = 1;
       
    #1 reset = 0;
       data = 32'h80AAAA;
    
    for(i = 0; i < 132; i=i+1) begin
      #1 clk = 0;
      #1 clk = 1;
    end
  end
endmodule