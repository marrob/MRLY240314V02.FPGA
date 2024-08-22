`timescale 10ps/1ps

module MRLY240314V02
  #(parameter WIDTH = 472)(
  input wire clk,               //50MHz

  output wire live_led,

  //output wire slu_busy,       //ToDo
  //output wire slu_slot_n,     //ToDo High: nincs kiválaszva a kártya

  input wire reset,             //slu_reset 
  input wire slu_strobe,
  input wire slu_rw_n,          //High: ilyenkor az FPGA ir a buszra
  input wire [7:0]slu_address,
  inout wire [7:0]slu_data_bus,

  //FPGA és TPIC relémeghajtók kacspolata, ahol az FPGA a master
  output wire tpic_mosi,       //FPGA.MOSI -> TPIC.SI
  output wire tpic_clk,        //12.5MHz a TPIC shiftregiszetereit lépteti
  output wire tpic_rck,
  input wire tpic_miso,        //FPGA.MISO <- TPIC.SO
  output wire tpic_en_n, 

  //uC és az FPGA között SPI kapcsolat, ami közvetlenül vezérelhet a TPIC relémeghajtókat
  input wire diag_en_n,       //High: a TPIC-ek kimenetei tiltottak/lebegnek
  input wire diag_rck,
  input wire diag_byps,       //High: ilyenkor az TPIC SPI és a uC SPI busza össze van kapcsolva.
  input wire diag_clk,        //Az SPI master eszköz órajele 
  output wire diag_miso,      //FPGA.MISO -> uC.MISO
  input wire diag_mosi,       //FPGA.MOSI <- uC.MOSI
  input wire diag_cs_n        //Csak akkor alacsony amikor memóriát olvas
  
);

 // parameter WIDTH = 432; //a flat memória szélessége pl 2bájt szélessége 2*8(bit)
  
  wire [WIDTH-1:0]memory;
 
  wire tpic_clk_div;
 
  wire mem2tpic_mosi;
  wire mem2tpic_clk;
  wire mem2tpic_rck;
  wire mem2tpic_en_n;
  wire spi_miso;
  
  //ha a diag_byps alacsony, akkor tpic-ek az fpga memoriajabol  frisssulnek
  assign tpic_mosi = diag_byps ? diag_mosi : mem2tpic_mosi;
  assign tpic_clk = diag_byps ? diag_clk : mem2tpic_clk;
  assign tpic_rck = diag_byps ? diag_rck : mem2tpic_rck;
  assign diag_miso = diag_byps ? tpic_miso : spi_miso;
  assign tpic_en_n = diag_byps ? diag_en_n :mem2tpic_en_n;
  
  live_led live_inst(
    .reset(reset),
    .clk(clk),
    .led(live_led)
);

  fdiv #(.DIVISOR(4)) fdiv_inst(
    .clk_in(clk),             //50MHz
    .reset(reset),
    .clk_out(tpic_clk_div)    //12.5MHz
);

  slu2mem #(.WIDTH(WIDTH)) slu2mem_inst(
    .reset(reset),
    .rw_n(slu_rw_n),          //Hihg: ilyenkor az FPGA ir a buszra
    .strobe(slu_strobe),
    .address(slu_address),
    .data_bus(slu_data_bus),
    .memory(memory)
);
  
  mem2tpic #(.WIDTH(WIDTH)) mem2tpic_inst (
    .clk(tpic_clk_div),       //12.5MHz
    .reset(reset),
    .data({memory[471:40]}),  //54 byte
    .sclk(mem2tpic_clk),      //6.25MHz clk for TPIC
    .g_n(mem2tpic_en_n),
    .rck(mem2tpic_rck), 
    .sout(mem2tpic_mosi)
);

  mem2spi_slave #(.WIDTH(WIDTH)) spi_slave_inst  (
    .reset(reset),
    .spi_clk(diag_clk),
    .cs_n(diag_cs_n),
    .mosi(diag_mosi),
    .miso(spi_miso),
    .memory(memory)
);


endmodule

//--- Unit Tests --------------------------------------------------------------

/*
 * Ha diag_bypss:High, akkor a uC közvetlenül vezérli a TPIC-ket
 * 
 * diag_en_n -> tpic_en_n
 * diag_clk -> tpic_clk
 * diag_rck -> tpic_rck
 * diag_mosi -> tpic_mosi
 * diag_miso <- tpic_miso
 */
module MRLY240314V02_uc2tpic_tb();
  reg  reset,
       clk,
       diag_en_n,
       diag_byps,
       diag_clk,
       diag_rck,
       diag_mosi,
       tpic_miso;

  wire tpic_clk,
       tpic_rck,
       tpic_en_n,
       tpic_mosi,
       diag_miso;

  integer i;
  
  MRLY240314V02 uut(
   .clk(clk), 
   .reset(reset),
   
   .tpic_clk(tpic_clk),
   .tpic_rck(tpic_rck),
   .tpic_en_n(tpic_en_n),
   .tpic_mosi(tpic_mosi),
   .tpic_miso(tpic_miso),
   
   .diag_en_n(diag_en_n), //A TPIC kimeneteit engegdélyezi
   .diag_byps(diag_byps), //High: Az FPGA összeköti a uC és TPIC vonalakat
   .diag_clk(diag_clk),
   .diag_rck(diag_rck),
   .diag_mosi(diag_mosi),
   .diag_miso(diag_miso)
);
  
  initial begin
   #1 clk = 0;
      reset = 0;
      diag_byps = 0;
      diag_en_n = 1;
      diag_clk = 0;
      diag_rck = 0;
      diag_mosi = 0;
      tpic_miso = 0;
      
   #1 reset = 0;
      diag_byps = 1; //inentől a tpic vonalakat a uC vezérli
   
   #1 diag_clk  = 1;
      diag_rck  = 1;
      diag_en_n = 1;
      diag_mosi = 1;
      tpic_miso = 1;
   #1
    if(diag_mosi == tpic_mosi) $display("%m: SPI MOSI PASSED"); else $display("%m: SPI MOSI FAILED");
    if(tpic_miso == diag_miso) $display("%m: SPI MISO PASSED"); else $display("%m: SPI MISO FAILED");
    if(diag_clk == tpic_clk) $display("%m: SPI CLK PASSED"); else $display("%m: SPI CLK FAILED");
    if(diag_rck == tpic_rck) $display("%m: SPI RCK PASSED"); else $display("%m: SPI RCK FAILED");
    if(diag_en_n == tpic_en_n) $display("%m: SPI EN PASSED"); else $display("%m: SPI EN FAILED");
   
   #1 diag_clk  = 0;
      diag_rck  = 0;
      diag_en_n = 0;
      diag_mosi = 0;
      tpic_miso = 0;
   #1
    if(diag_mosi == tpic_mosi) $display("%m: SPI MOSI PASSED"); else $display("%m: SPI MOSI FAILED");
    if(tpic_miso == diag_miso) $display("%m: SPI MISO PASSED"); else $display("%m: SPI MISO FAILED");
    if(diag_clk == tpic_clk) $display("%m: SPI CLK PASSED"); else $display("%m: SPI CLK FAILED");
    if(diag_rck == tpic_rck) $display("%m: SPI RCK PASSED"); else $display("%m: SPI RCK FAILED");
    if(diag_en_n == tpic_en_n) $display("%m: SPI EN PASSED"); else $display("%m: SPI EN FAILED");
  end
endmodule

// Az SLU olvassa a buszról a kártya ID type - ját
module MRLY240314V02__read_card_type_tb();
  reg  reset,
       clk,
       slu_rw_n,
       slu_strobe,
       diag_byps,
       data_bus_drv_en;
  reg  [7:0]data_bus_out;
  reg  [7:0]slu_address;
  
  wire [7:0] slu_data_bus;
  
  MRLY240314V02 uut(
   .clk(clk), 
   .reset(reset),
   
   .slu_rw_n(slu_rw_n),
   .slu_strobe(slu_strobe),
   .slu_address(slu_address),
   .slu_data_bus(slu_data_bus),
   .diag_byps(diag_byps)
);

  assign slu_data_bus = data_bus_drv_en ? data_bus_out : 8'hZZ;
  
  initial begin
      clk = 0;
      diag_byps = 0;
      data_bus_drv_en = 0;
      reset = 0;
      slu_strobe = 0;
      slu_rw_n = 0;
      slu_address = 8'h00;

   #1 reset = 1;
   #1 reset = 0;
      
   #1 slu_rw_n = 1;         //FPGA ír a buszra
      slu_address = 8'h00;  //0x00 Card Type olvasása
   #1 slu_strobe = 1;
   #1 slu_strobe = 0;
   
   if(slu_data_bus == 8'h43)
    $display("%m: PASSED, card type is OK");
   else
    $display("%m: FAILED");

  end
endmodule


// Az SLU parhuzamos interfeszen beirok egy bajtot madj ugyan ezen a cimen visszaolvasom
module MRLY240314V02__write_a_byte_tb();

  reg  reset,
       clk,
       slu_rw_n,
       slu_strobe,
       diag_byps,
       data_bus_drv_en;
  reg  [7:0]data_bus_out;
  reg  [7:0]slu_address;
  
  wire [7:0] slu_data_bus;
  
    MRLY240314V02 uut(
   .clk(clk), 
   .reset(reset),
   
   .slu_rw_n(slu_rw_n),
   .slu_strobe(slu_strobe),
   .slu_address(slu_address),
   .slu_data_bus(slu_data_bus),
   .diag_byps(diag_byps)
);

  assign slu_data_bus = data_bus_drv_en ? data_bus_out : 8'hZZ;
  
  initial begin
      clk = 0;
      diag_byps = 0;
      data_bus_drv_en = 0;
      reset = 0;
      slu_strobe = 0;
      slu_rw_n = 0;
      slu_address = 8'h00;

   #1 reset = 1;

   //beírás az FPGA "memory" változójába
   #1 reset = 0;
      slu_rw_n = 0;         //FPGA olvas a buszról
      slu_address = 8'h03;  //
      data_bus_drv_en = 1;  //engedélyezi a buszra írást
      data_bus_out = 8'h55; //0x55 adok a 0x03-as címre ezt az értéket fogja az FPGA beolvasni
      
   #1 slu_strobe = 1;
   #1 slu_strobe = 0;
      data_bus_drv_en = 0;
      slu_address = 8'h00;
   
   //a beírt változót kiolvasom
   #1 slu_rw_n = 1;         //FPGA ír memory-ból kiválaszott bájt értékét írja a buszra
      slu_address = 8'h03;
   #1 slu_strobe = 1;
   #1 slu_strobe = 0;
   
   if(slu_data_bus == 8'h55)
    $display("%m: PASSED; The wrote value is equal with the read value.");
   else
    $display("%m: FAILED;");
  end

endmodule

//Az SLU párhuzamos buszán beírok az FPGA memóriájába az SPI-on pedig visszaolvasom
module MRLY240314V02__slu_write_spi_read();

  reg  reset,
       clk,
       slu_rw_n,
       slu_strobe,
       diag_byps,
       data_bus_drv_en,
       spi_clk,
       spi_cs_n,
       spi_mosi;
       
  wire spi_miso;
 

  reg  [7:0]data_bus_out;          //fizikailag ez a regiszter küldi az adatot a buszra amikor data_bus_drv_en:H
  reg  [7:0]slu_address;           //a berinado adat cime
  reg  [23:0]spi_header;           //3-bajtos spi header
  reg  [31:0]rx_spi_data;          //a fejlec kuldesa alatt fogadunk is, igy az also 1 bajt lesz az ertekes
  
  wire [7:0] slu_data_bus;         //tri state adatbus
  
  integer bit_index = 0,
          i = 0;
   
  MRLY240314V02 uut(
   .clk(clk),
   .reset(reset),
   
   .slu_rw_n(slu_rw_n),
   .slu_strobe(slu_strobe),
   .slu_address(slu_address),
   .slu_data_bus(slu_data_bus),

   .diag_byps(diag_byps),
   
   //az FPGA a SPI slave
   .diag_clk(spi_clk),
   .diag_cs_n(spi_cs_n),
   .diag_miso(spi_miso),
   .diag_mosi(spi_mosi)
);

 
  assign slu_data_bus = data_bus_drv_en ? data_bus_out : 8'hZZ;

  initial begin
   #1 reset = 1;
      diag_byps = 0;
      clk = 0; //ez a rendszer orajel
      slu_rw_n = 1;
      slu_strobe = 0;
      data_bus_drv_en = 0;
      slu_address = 8'hFF;
      spi_cs_n = 1;
      spi_clk = 0;
      spi_mosi = 0;

      //beírás az FPGA "memory" változójába
   #1 reset = 0;
      slu_rw_n = 0;         //FPGA olvas a buszról
      slu_address = 8'h07;  //erre a címre irok
      data_bus_drv_en = 1;  //engedélyezi a buszra írást
      data_bus_out = 8'h55; //ezt irom a cimre ezt az értéket fogja az FPGA beolvasni
   #1 slu_strobe = 1;
   
   #1 slu_strobe  = 0;
      data_bus_drv_en = 0;
      slu_address = 8'hFF;
    
   #1 spi_cs_n = 0;
      spi_header = 24'h030007; //Instr: 3(Read), Address:0x07
   
    bit_index = 24;
    for(i = 0; i != 32; i = i + 1) begin
      if(bit_index != 0)begin
        spi_mosi = spi_header[bit_index - 1];
        bit_index = bit_index - 1;
      end else begin
        spi_mosi = 0;
      end
      #1 spi_clk = 1;
      #1 spi_clk = 0;
      
      rx_spi_data = { rx_spi_data[31:0], spi_miso};
    end
    
   #1 spi_cs_n = 1;
   
   if(rx_spi_data[7:0] == data_bus_out)
    $display("%m: write to memory and read from memory are equal -> PASSED");
   else
    $display("%m:write to memory and read from memory are NOT equal -> FAILED");
   
  end
endmodule


module MRLY240314V02__read_card_type_over_spi();

  reg  reset,
       diag_byps,
       spi_clk,
       spi_cs_n,
       spi_mosi;
       
  wire spi_miso;
  reg [7:0] vector = 8'h0;

  parameter WIDTH = 472;
  
  reg  [WIDTH - 1:0]result_memory;
    
  integer  i = 0,
           bit_idx = 0;
   
  MRLY240314V02 uut(
   .reset(reset),
   
   .diag_byps(diag_byps),
   
   //az FPGA a SPI slave
   .diag_clk(spi_clk),
   .diag_cs_n(spi_cs_n),
   .diag_miso(spi_miso),
   .diag_mosi(spi_mosi)
);

  initial begin
     $monitor("reserved vector %02h", vector);
     
   #1 reset = 1;
      diag_byps = 0;
      spi_cs_n = 1;
      spi_clk = 0;
      spi_mosi = 0;

      result_memory = {WIDTH-1{1'b0}};
    
   #1 reset = 0;
   #1 reset = 1;
   #1 reset = 0;
   
   #1 spi_cs_n = 0;
   #1 spi_cs_n = 1;


   #1 spi_cs_n = 0;
      for(bit_idx = 0; bit_idx < WIDTH; bit_idx = bit_idx + 1)
      begin
       #1 spi_clk = 1;
          result_memory[bit_idx] = spi_miso;
       #1 spi_clk = 0;
      end
   #1 spi_cs_n = 1;

     for(i = 0; i < 59; i = i + 1)
      $display("%02h", result_memory[i * 8 +: 8]);
     
      vector = result_memory[WIDTH - 1 : WIDTH - 8]; //471...464 az utolsó bájt fordított sorrendben

    if(vector == 8'hC2)
      $display ("%m Read Card Type is %08h PASSED", vector);
    else
      $display ("%m Read Card Type is %08h FAILED", vector);

  end
endmodule


