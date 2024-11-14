`timescale 10ps/1ps
module slu2mem
  #(parameter WIDTH = 48)(
  input reset,              //Reset actív when: High
  input rw_n,               //FPGA Read From bus When: Low
  input strobe,             //felfutóélre hajtódik végre
  input [7:0] address,
  inout [7:0] data_bus,
  output reg [WIDTH-1:0] memory
);
  reg [7:0] data_bus_out;
  reg [7:0] abus_ctrl;
  assign data_bus = rw_n ? data_bus_out : 8'hZZ; //Hihg: ilyenkor az FPGA ir a buszra
  
  always @(posedge strobe or posedge reset)
  begin
    if(reset)
    begin 
      data_bus_out = 8'h00;
      memory = {WIDTH{1'b0}};
      memory[7:0] =   8'h43; //0x00 Card Type 0x00 - Ez a Keysight E8782A Instruments Matrix Card
      memory[15:8] =  8'h0F; //0x01 Card Confiugration
      memory[23:16] = 8'h80; //0x02 Status and Control
      memory[31:24] = 8'h55; //0x03 Not used 0x03
      
      memory[39:32] = 8'hF0; //0x04 Abus control and protection bypass relay (Dissconnect Relék, default bekapcsoltak)
      abus_ctrl = 8'hF0;
      
      memory[47:40] = 8'hAA; //0x05 Not Used
    end else if(rw_n)
      data_bus_out = memory[address * 8 +: 8];
    else
    begin
      if(address == 8'h00)
      ;//0x00 regiszter csak olvasható itt van az eszköz címe
      else
      if(address == 8'h02)
      begin
        
        memory[19:17] <= data_bus[3:1]; //DAC2Rly, DAC1Rly, GndRly
        
        if(data_bus & 8'h40)
        begin
          memory[23:16] <= memory[23:16] | 8'h40; // csak beállítani lehet
        end //if(data_bus & 8'h40)
        
        if((data_bus & 8'h20) || (data_bus & 8'h01))//OAR (Open All Relays) vagy a Reseteli a relé láncot
        begin
          memory[23:16] <= 8'h80;
          memory[39:32] <= 8'hF0;
          memory[WIDTH-1:48] <= 0;
        end //if(data_bus & 8'h20)
      end //if(address == 8'h02)
      else
      if(address == 8'h04)
      begin
       abus_ctrl = data_bus;
       if(memory[23:16] & 8'h40) //DCE - Disconnect Control Enable
          memory[39:32] = abus_ctrl;//Enabled
        else
          memory[39:32] = abus_ctrl | 8'hF0; //Disabled
      end //if(address == 8'h04)
      else 
      begin
        if(memory[23:16] & 8'h40) //DCE Upadate
          memory[39:32] = abus_ctrl;
        else
          memory[39:32] = abus_ctrl | 8'hF0;
          memory[address * 8 +: 8] <= data_bus; //FPGA Read From Bus - SLU Write
      end
    end
  end

endmodule

//--- Unit Tests --------------------------------------------------------------
module slu2mem__basics_tb();
  reg reset,
      strobe,
      rw_n,
      drv_en;
  
  reg [7:0]addr;
  reg [7:0]data_bus_drv;

  wire [7:0]data_bus;
  wire [23:0]mem;
  
  assign data_bus = (drv_en) ? data_bus_drv : 8'hzz; //a drv_en-el lehet kapcsolni az olvasás és az írás között
  slu2mem uut(
    .reset(reset),
    .rw_n(rw_n),
    .strobe(strobe),
    .address(addr),
    .data_bus(data_bus),
    .memory(mem)
);
  initial begin
    #1 reset = 0;
       reset = 1;
       strobe = 0;
       drv_en = 0;
 
    // --- Read Card Type ---
    #1 reset = 0;
       rw_n = 1;      //FPGA Write - SLU Read
       addr = 8'h00;  //Read Address
       
    #1 strobe = 1;
    #1 strobe = 0;
    
    if(data_bus == 8'h43)
      $display("%m Card Type is PASSED");
    else
      $display("%m Card Type is FAILED");

    // --- SLU Write a byte and SLU read a byte ---
    #1 drv_en = 1;      //Bus drive enalbe Input to FPGA
       rw_n = 0;        //FPGA Read - SLU Wirte
       addr = 8'h05;    //Write address
       data_bus_drv = 8'h83;
       
    #1 strobe = 1;
    #1 strobe = 0;
    
    
    #1 drv_en = 0;
       rw_n = 1;        //FPGA Write - SLU Read
       addr = 8'h05;    //Read address
    
    #1 strobe = 1;
    #1 strobe = 0;
    
    if(data_bus_drv == data_bus)
      $display("%m: write to memory and read from memory are equal -> PASSED");
    else
      $display("%m:write to memory and read from memory are NOT equal -> FAILED");
 
    // --- Fixed Value Test ---    
    #1 rw_n = 1;        //FPGA Write - SLU Read 
       addr = 8'h03;
    #1 strobe = 1;
    #1 strobe = 0;
    
    if(data_bus == 8'h55)
      $display("%m: Fixed value test -> PASSED");
    else
      $display("%m: Fixed value test -> FAILED");
      
    #1 rw_n = 0;
 end
endmodule