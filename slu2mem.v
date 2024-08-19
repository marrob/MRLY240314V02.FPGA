`timescale 10ps/1ps
module slu2mem
  #(parameter WIDTH = 16)(
  input reset,              //Reset actív when: High
  input rw_n,               //FPGA Read From bus When: Low
  input strobe,             //felfutóélre hajtódik végre
  input [7:0] address,
  inout [7:0] data_bus,
  output reg [WIDTH-1:0]memory
);
  
  reg [7:0]data_bus_out;
  assign data_bus = rw_n ? data_bus_out : 8'hZZ; //Hihg: ilyenkor az FPGA ir a buszra

  always @(posedge strobe or posedge reset ) begin
    //Reset
    if(reset)begin 
      data_bus_out = 0;
      memory = 0;
    end
    //FPGA Write To Data Bus
    else if(rw_n) begin
      case (address)
        8'h00: data_bus_out =  8'h43;                     //Card Type + 0h - Ez a Keysight E8782A Instruments Matrix Card
        8'h01: data_bus_out =  8'h0F;                     //Card Confiugration + 1h
        8'h02: data_bus_out =  memory[23:16];             //Status and Control + 2h
        default data_bus_out = memory[address * 8 +: 8];  //ezzel a fenmaradó területet lehet olvasni bájtos címzéssel
      endcase
    end
    //FPGA Read From Bus
    else begin 
      memory[address * 8 +: 8] <= data_bus;
    end
  end

endmodule


//--- Unit Tests --------------------------------------------------------------
module slu2mem__slu2mem_tb();
  reg reset, strobe, rw_n, drv_en;
  reg [7:0]addr;
  wire [7:0]data_bus;
  reg [7:0]data_bus_drv;
  wire [23:0]mem;
  
  assign data_bus = (drv_en) ? data_bus_drv : 8'hzz; //a drv_en-el lehet kapcsolni az olvasás és az írás között
  slu2mem uut(.reset(reset), .rw_n(rw_n), .strobe(strobe), .address(addr), .data_bus(data_bus), .memory(mem));
  initial begin
    //#0
     #1 reset = 0;
        reset = 1;
     #1 reset = 0;
     
    //#1
    reset = 0;
    strobe = 0;
    drv_en = 0;
    rw_n = 1; //FPGA will write to bus
    addr = 8'h01;
    #1 strobe = 1; #1 strobe = 0;
    $display("#1 data_bus:0x%0h", data_bus);
    //Check data_bus value (should be 0x38)

    //#2
    #1
       reset = 0;
       drv_en = 0;
       rw_n = 0;  //FPGA will be read
       addr = 8'h02; 
       drv_en = 1; // Bus drive enalbe Input to FPGA
       data_bus_drv = 8'h03; 
    #1 strobe = 1; #1 strobe = 0;
    #1 drv_en = 0;
    $display("#2 data_bus:0x%0h", data_bus);

    //#3
    #1 rw_n = 1; addr = 8'h00; //FPGA will write to bus
    #1 strobe = 1; #1 strobe = 0;
    $display("#3 data_bus:0x%0h", data_bus);
    #1 rw_n = 0;
    //itt a data_bus-nak 0xaa-nak kell lennie
    
    //#4
    #1 rw_n = 1; addr = 8'h02;//data_bus output az FPGA oldaláról nézve
    #1 strobe = 1; #1 strobe = 0;
    $display("#4 data_bus:0x%0h", data_bus);
    #1 rw_n = 0;
    //itt a data_bus-nak 0x03-nak kell lennie
    $display("Hello");
 end
endmodule