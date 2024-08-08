module MRLY240314V02(
  input wire clk,               //50MHz

  output wire live_led,

  //output wire slu_busy,       //ToDo
  //output wire slu_slot_n,     //ToDo High: nincs kiválaszva a kártya

  input wire slu_reset,         //slu_reset 
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
  input wire diag_clk,
  output wire diag_miso,      //FPGA.MISO -> uC.MISO
  input wire diag_mosi        //FPGA.MOSI <- uC.MOSI
);


  parameter WIDTH = 300; //a flat memória szélessége pl 2bájt szélessége 2*8(bit)
  wire [WIDTH-1:0]memory;
 
  wire tpic_clk_div;
 
  wire mem2tpic_mosi;
  wire mem2tpic_clk;
  wire mem2tpic_rck;
  wire mem2tpic_en_n;
  
  assign tpic_mosi = diag_byps ? diag_mosi : mem2tpic_mosi;
  assign tpic_clk = diag_byps ? diag_clk : mem2tpic_clk;
  assign tpic_rck = diag_byps ? diag_rck : mem2tpic_rck;
  assign diag_miso = diag_byps ? tpic_miso : 1'bZ;
  assign tpic_en_n = diag_byps ? diag_en_n :mem2tpic_en_n;
  
  live_led live_inst(
    .reset(slu_reset),
    .clk(clk),
    .led(live_led)
);

  fdiv #(.DIVISOR(4)) fdiv_inst(
    .clk_in(clk),           //50MHz
    .reset(slu_reset),
    .clk_out(tpic_clk_div)  //25MHz
);

  slu2mem #(.WIDTH(WIDTH)) slu2mem_inst(
    .reset(slu_reset),
    .rw_n(slu_rw_n), //Hihg: ilyenkor az FPGA ir a buszra
    .strobe(slu_strobe),
    .address(slu_address),
    .data_bus(slu_data_bus),
    .memory(memory)
);
  
  mem2tpic #(.WIDTH(WIDTH)) mem2tpic_inst (
    .clk(tpic_clk_div),   //25MHz
    .reset(slu_reset),
    .data(memory),
    .sclk(mem2tpic_clk),  //12.5MHz output
    .en_n(mem2tpic_en_n),
    .rck(mem2tpic_rck), 
    .sout(mem2tpic_mosi)
);
endmodule

//Unit Tesztek ----------------------------------------------------------------
`timescale 10ps/1ps
/*
 * A mem2tpic mükdését ellenörzi.
 * 
 *
 *
 */
module MRLY240314V02_tpic_clk_tb();
  reg  slu_reset, clk, diag_byps;
  wire tpic_clk, tpic_rck, live_led, tpic_en_n;
  
  localparam WIDTH = 300;
  integer i;
  
  MRLY240314V02 uut(
   .clk(clk),
   
   .slu_reset(slu_reset),
   .live_led(live_led),
   
   .tpic_clk(tpic_clk),
   .tpic_rck(tpic_rck),
   .tpic_en_n(tpic_en_n),
   
   .diag_byps(diag_byps)
   
);
  initial begin
   //#0
   #1 clk = 0;
      slu_reset = 0;
      diag_byps = 0;
      slu_reset = 1;
   #1 slu_reset = 0;
   
   /*
    *ha 300 bit széles, akkor ehhez az órjael 8-al van osztva 300*
    * 1. 2-es osztó a for ciklus maga itt
    * 2. 4-es osztó a fdiv #(.DIVISOR(2)) fdiv_inst
    * 3. 2-es osztó a  mem2tpic #(.WIDTH(WIDTH)) mem2tpic_inst
    * ez igy összesen 16.
    * Ahhoz hogy egy teljes TPIC ciklus látszódjon, minimum WIDTH * 16-kell
    * + 11 az RCK impulzushoz kell
    */
   for(i = 0; i < WIDTH * 16 + 11; i = i+1)
    #1 clk = ~clk;
  //itt a data_bus-nak 0x03-nak kell lennie
  $display("Hello");
 end
endmodule

/*
 * Azt ellenörzi, hogy a, ha a diag_byps-t a uC High ba tesz, akkor a uC tudja-e vezérelni a TPIC-et
 * 
 * diag_en_n -> tpic_en_n
 * diag_clk -> tpic_clk
 * diag_rck -> tpic_rck
 * diag_mosi -> tpic_mosi
 * diag_miso <- tpic_miso
 */
module MRLY240314V02_uc2tpic_tb();
  reg  slu_reset, clk, diag_en_n, diag_byps, diag_clk, diag_rck, diag_mosi, tpic_miso;
  wire tpic_clk, tpic_rck, tpic_en_n, tpic_mosi, diag_miso;
  integer i;
  
  MRLY240314V02 uut(
   .clk(clk), 
   .slu_reset(slu_reset),
   
   .tpic_clk(tpic_clk),
   .tpic_rck(tpic_rck),
   .tpic_en_n(tpic_en_n),
   .tpic_mosi(tpic_mosi),
   .tpic_miso(tpic_miso),
   
   .diag_en_n(diag_en_n), //A TPIC kimeneteit engegdélyezi
   .diag_byps(diag_byps), //High: A TPIC - uC bypass funkicójának engedélyezése
   .diag_clk(diag_clk),
   .diag_rck(diag_rck),
   .diag_mosi(diag_mosi),
   .diag_miso(diag_miso)
);
  
  initial begin
   #1 clk = 0;
      slu_reset = 0;
      slu_reset = 1;
      
      diag_byps = 0;
      diag_en_n = 1;
      diag_clk = 0;
      diag_rck = 0;
      diag_mosi = 0;
      
      tpic_miso = 0;
      
   #1 slu_reset = 0;
   
   #1 diag_byps = 1; //inentől a tpic vonalakat a uC vezérli
   #1 diag_en_n = 0;
   #1 diag_mosi = 1;
   #1 tpic_miso = 1;

   for(i = 0; i< 10; i = i + 1)begin
      #1 diag_clk = ~diag_clk;
      if(i%2)
        diag_rck = ~diag_rck;
   end
  end
endmodule

/*
 * Az SLU olvassa a buszról a kártya ID type - ját
 */
module slu_read_card_type_tb();
  reg  slu_reset,
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
   .slu_reset(slu_reset),
   .slu_rw_n(slu_rw_n),
   .slu_strobe(slu_strobe),
   .slu_address(slu_address),
   .slu_data_bus(slu_data_bus),
   
   
   .diag_byps(diag_byps)   //High: A TPIC - uC bypass funkicójának engedélyezése
);

  assign slu_data_bus = data_bus_drv_en ? data_bus_out : 8'hZZ;
  
  initial begin
      clk = 0;
      diag_byps = 0;
      data_bus_drv_en = 0;
      slu_reset = 0;
      slu_strobe = 0;
      slu_rw_n = 0;
      slu_address = 8'h00;

   #1 slu_reset = 1;
   #1 slu_reset = 0;
      
   #1 slu_rw_n = 1;         //FPGA ír a buszra
      slu_address = 8'h00;  //0x00 Card Type olvasása
   #1 slu_strobe = 1;
   #1 slu_strobe = 0;

  end
  
endmodule


// UUT az SLU olvasásra és írásra
