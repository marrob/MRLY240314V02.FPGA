`timescale 10ps/1ps

/*
 * Ez a header: 
 * Ez a bit sorrend beíráskor (mosi) az I7 van a legmagasabb helyértéken és kell elsőnek küldeni. (MSB first)
 * 
 *  I7                          I0    A15                                 A7                          A0
 *  0   1   2   3   4   5   6   7   |  8   9   10  11  12  13  14  15  |  16  17  18  19  20  21  22  23
 *
 *  SI: MSB first 
 *  0x020001 -> Inst 2 és address:1
 *  
 *  SO: MSB first pl:
 *  0x020001 -> 0x01 -> Inst 2 és address:1
 * 
 *  23  22  21  20  19  18  17  16  |  15  14  13  12  11  10  9   8   |  7   6   5   4   3   2   1   0
 *   
 *     
 *  Instructions:
 *  0x03 - Read byte  - 0x030000
 *  0x02 - Write byte - 0x020000
 *
 *
 */
module mem2spi_slave
  #(parameter WIDTH = 16)(
  input wire clk, //ez az órajel a master spi eszköz órajele 
  input wire reset,
  input wire cs_n,
  input wire mosi,
  output wire miso,
  input [WIDTH - 1:0] memory
);

  localparam S_RX_HEADER = 2'd1;
  localparam S_TX_DATA   = 2'd2;
  
  reg [7:0] output_data;  //a cim alapjan a memorybol ide kerul az adat es ebben shifteljuk ki
  
  reg [1:0] states;
  reg [4:0] bit_index;
  
  wire [15:0] addr;
  wire [7:0]  inst;
  
  reg [23:0]  header;
  assign addr = {header[15:0]};
  assign inst = {header[23:16]};
  assign miso = output_data[7]; //msb first out
  
  //akkor kellene hogy reszteljen amikor cs alacsonyba megy
  always @ (posedge clk or posedge reset or posedge cs_n) begin
    if (reset || cs_n) begin
      states <= S_RX_HEADER;
      header <= 24'd0;
      bit_index <= 5'd0;
      output_data <= 8'bZ;
    end else if(!cs_n) begin
      case (states)
        S_RX_HEADER: begin
          header <= { header[22:0], mosi }; // MSB fogadása balra, így a végére az MSB kerül legfelülre
          bit_index <= bit_index + 1'd1;
          if (bit_index == 24) begin
            bit_index <= 5'd0;
            $display("%m header done: 0x%h, inst: 0x%h, bit_index: %d", header, inst, bit_index);
            if (inst == 8'h03) begin // Read instruction
              $display("%m read instruction, addr:0x%h, data:0x%h", addr, memory[addr * 8 +: 8]);
              output_data <= memory[addr * 8 +: 8];
              states <= S_TX_DATA;
            end else begin
              header <= 24'd0;
              bit_index <= 5'd0;
              output_data <= 8'bZ;
            end
           end
          end

        S_TX_DATA: begin
          if (bit_index < 7) begin
            output_data <= output_data << 1; // MSB first
            bit_index <= bit_index + 1'd1;
          end else begin
            states <= S_RX_HEADER;
            header <= 24'd0;
            bit_index <= 5'd0;
            output_data <= 8'hZ;
          end
        end
        default: begin
          states <= S_RX_HEADER;
          header <= 24'd0;
          bit_index <= 5'd0;
          output_data <= 8'hZ;
        end
      endcase
    end
  end
endmodule

//--- Unit Tests --------------------------------------------------------------
module spi_slave__master_receive_tb();
  localparam WIDTH = 16;
  
  reg clk,
      reset,
      cs_n,
      mosi;
  wire miso;
  
  reg [ WIDTH-1:0 ] memory;
  reg [31:0]rx_spi_data;
  
  integer i,
          bit_index;

  wire [23:0] spi_header;
  
  assign spi_header = 24'h030001; //Inst: 0x03, address: 0x0001
  
  mem2spi_slave #(.WIDTH(WIDTH)) uut(
    .clk(clk),
    .reset(reset),
    .cs_n(cs_n),
    .mosi(mosi),
    .miso(miso),
    .memory(memory)
  );
  
  initial begin
     clk = 0;
     reset = 0;
     cs_n = 1;
     memory = 16'h0300; //Az address 0.-án 0 éréték van és az address 1-en 3-as érték van;
  #1 reset = 1;
  
//- akkor volt problema, ha több orajelet küld mint kellene, akkor a következő chip select már nem reszteli a bit countert
//  ezt úgy lehet megoldani, hogy a cs_n posedge-re reszetel mindent is.

//- 3 bájtos header és 1 bájt-os adat fogadása (összesen 32 bit)
  #1 reset = 0;
     cs_n = 0;
     mosi = 0;
     bit_index = 24;
    for(i = 0; i != 32; i = i + 1) begin
      if(bit_index != 0)begin
      
        mosi = spi_header[bit_index - 1];
        bit_index = bit_index - 1;
      end else begin
        mosi = 0;
      end
      
      #1 clk = 1;
      #1 clk = 0;
      
      rx_spi_data = { rx_spi_data[31:0], miso};
    end
   #1 cs_n = 1;
   if(rx_spi_data[7:0] == 8'h03)
      $display("%m: memory data and read data PASSED");
   else
      $display("%m: memory data and read data FAILED");
      
      
  #1 memory = 16'h8000; //Az address 0.-án 0 éréték van és az address 1-en 3-as érték van;
     rx_spi_data = 32'hZZ;
     cs_n = 0;
     bit_index = 24;
 
    for(i = 0; i != 32; i = i + 1) begin
      if(bit_index != 0)begin
        mosi = spi_header[bit_index - 1];
        bit_index = bit_index - 1;
      end else begin
        mosi = 0;
      end
      #1 clk = 1;
      #1 clk = 0;
      rx_spi_data = { rx_spi_data[31:0], miso};
    end
    
  #1 cs_n = 1;
   if(rx_spi_data[7:0] == 8'h80)
    $display("%m: memory data and read data PASSED");
   else
    $display("%m: memory data and read data FAILED");
  end
endmodule