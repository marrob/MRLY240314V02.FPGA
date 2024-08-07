module MRLY240314V02(
  input wire clk,               //50MHz

  output wire live_led,

  //output wire slu_busy,       //ToDo
  //output wire slu_slot_n,     //ToDo High: nincs kiválaszva a kártya

  input wire slu_reset,         //slu_reset 
  input wire slu_strobe,
  input wire slu_rw_n,          //Hihg: ilyenkor az FPGA ir a buszra
  input wire [7:0]slu_address,
  inout wire [7:0]slu_data_bus,

  //FPGA és TPIC relémeghajtók kacspolata, ahol az FPGA a master
  output wire tpic_mosi, //FPGA.MOSI -> TPIC.SI
  output wire tpic_clk,
  output wire tpic_rck,
  input wire tpic_miso,  //FPGA.MISO <- TPIC.SO
  output wire tpig_g_n,

  //uC és az FPGA között SPI kapcsolat, ami közvetlenül vezérelhet a TPIC relémeghajtókat
  input wire diag_g_n,
  input wire diag_rck,
  input wire diag_byps, //High: ilyenkor az TPIC SPI és a uC SPI busza össze van kapcsolva.
  input wire diag_clk,
  output wire diag_miso, //FPGA.MISO -> uC.MISO
  input wire diag_mosi   //FPGA.MOSI <- uC.MOSI
);


  parameter WIDTH = 300; //a flat memória szélessége pl 2bájt szélessége 2*8(bit)
  wire [WIDTH-1:0]memory;
 
  wire mem2tpic_mosi;
  wire mem2tpic_clk;
  wire mem2tpic_rck;
  wire mem2tpic_g_n;

  assign tpic_mosi = diag_byps ? diag_mosi : mem2tpic_mosi;
  assign tpic_clk = diag_byps ? diag_clk : mem2tpic_clk;
  assign tpic_rck = diag_byps ? diag_rck : mem2tpic_rck;
  assign diag_miso = diag_byps ? tpic_miso : 1'bZ;
  
  live_led live_inst(
    .clk(clk),
    .led(live_led)
);
    
    
  slu2mem #(.WIDTH(WIDTH)) slu2mem_ubst(
    .reset(slu_reset),
    .rw_n(slu_rw_n), //Hihg: ilyenkor az FPGA ir a buszra
    .strobe(slu_strobe),
    .address(slu_address),
    .data_bus(slu_data_bus),
    .memory(memory)
);
  
  mem2tpic #(.WIDTH(WIDTH)) mem2tpic_inst (
    .reset(slu_reset),
    .clk(clk),
    .data(memory),
    .sclk(mem2tpic_clk), //output, tpic shiftregiszetereit vezérli
    .clr_n(mem2tpic_g_n),
    .rck(mem2tpic_rck), 
    .sout(mem2tpic_mosi)
);


endmodule