`timescale 10ps/1ps

module mem2spi_slave
  #(parameter WIDTH = 16)(
  input wire reset,
  input wire clk,
  input wire spi_clk,
  input wire cs_n,
  output reg miso,
  input wire[WIDTH - 1:0] memory
);

  localparam ST_IDLE       = 0;
  localparam ST_LOAD       = 1;
  localparam ST_WAIT_CLK_H = 2;
  localparam ST_WAIT_CLK_L = 3;

  reg spi_clk_sync_0, spi_clk_sync_1;
  reg [8:0] bit_index;
  reg [1:0] curr_state;
  reg [1:0] pre_state;
  
  always @(posedge clk or posedge reset)
  begin
      if (reset)
      begin
          spi_clk_sync_0 <= 1'b0;
          spi_clk_sync_1 <= 1'b0;
      end else begin
          spi_clk_sync_0 <= spi_clk;
          spi_clk_sync_1 <= spi_clk_sync_0; // Szinkronizált spi_clk
      end
  end
  wire spi_clk_rising_edge = (spi_clk_sync_1 && !spi_clk_sync_0);
  
  always @(posedge clk or posedge reset)
  begin
    if(reset)
    begin
      bit_index <= 0;
      curr_state <= ST_IDLE;
    end else
    begin
      case(curr_state)
        ST_IDLE:
          begin
            bit_index <= 0;
            if(!cs_n)
              curr_state <= ST_LOAD;
          end
        ST_LOAD:
          begin
            if(pre_state != curr_state)
            begin
               miso <= memory[0];
               bit_index <= 5'd1;
            end
            curr_state <= ST_WAIT_CLK_H;
            if(cs_n)
              curr_state <= ST_IDLE;
          end
        ST_WAIT_CLK_H:
          begin
            if(spi_clk_rising_edge)
            begin
              curr_state <= ST_WAIT_CLK_L; 
            end
            if(cs_n)
              curr_state <= ST_IDLE;
          end
        ST_WAIT_CLK_L:
          begin
            if(!spi_clk_sync_1)
            begin
              miso <= memory[bit_index];
              bit_index <= bit_index + 5'd1;
              curr_state <= ST_WAIT_CLK_H;
            end
            if(cs_n)
              curr_state <= ST_IDLE;
          end
         default: curr_state <= ST_IDLE;
      endcase
      pre_state <= curr_state;
    end
  end
endmodule


module mem2spi_slave__basics_tb();
  localparam WIDTH = 48;
  reg reset,
      clk,
      spi_clk,
      cs_n;
  wire miso;
  reg [7:0] data;
  reg [WIDTH-1: 0] memory;
  
  integer i,j;
  
  
  mem2spi_slave #(.WIDTH(WIDTH)) uut (
    .reset(reset),
    .clk(clk),
    .spi_clk(spi_clk),
    .cs_n(cs_n),
    .miso(miso),
    .memory(memory)
  );

  initial begin
    memory[7:0] =   8'h43;
    memory[15:8] =  8'h0F;
    memory[23:16] = 8'h00;
    memory[31:24] = 8'h55;
    memory[39:32] = 8'hAA;
    memory[47:40] = 8'h01;
    
    spi_clk = 0;
    clk = 0;
    cs_n = 1;
    data = 8'h0;
    
    #1 reset = 1;
    #1 reset = 0;
    
    //"volt a load"
    #1 clk = 1;
    #1 clk = 0;
      
     #1 cs_n = 0;
     #1 clk = 1;
     #1 clk = 0;
     #1 clk = 1;
     #1 clk = 0;
    
    for(j = 0; j < WIDTH/8 ;  j = j + 1) //bytes
    begin
      for(i = 0; i < 8; i = i + 1) //bits
      begin
         data = {data[6:0], miso};
        #1 spi_clk = 1;
          #1 clk = 1;
          #1 clk = 0;
          
        #1 spi_clk = 0;
          #1 clk = 1;
          #1 clk = 0;
        
        
      end
      $display("%m byte index: %d, value: %2h", j, data );
    end
    
     #1 cs_n = 1;
     #1 clk = 1;
     #1 clk = 0;
     #1 clk = 1;
     #1 clk = 0;
     
    $display("repeat");
    
    #1 cs_n = 0;
     #1 clk = 1;
     #1 clk = 0;
     #1 clk = 1;
     #1 clk = 0;
    
     for(j = 0; j < WIDTH/8 ;  j = j + 1) //bytes
      begin
        for(i = 0; i < 8; i = i + 1) //bits
        begin
          #1 spi_clk = 1;
            #1 clk = 1;
            #1 clk = 0;

          #1 spi_clk = 0;
            #1 clk = 1;
            #1 clk = 0;
          
          data = {data[6:0], miso};
        end
        $display("%m byte index: %d, value: %2h", j, data );
      end
      
     #1 cs_n = 1;
       #1 clk = 1;
       #1 clk = 0;
       #1 clk = 1;
       #1 clk = 0;
  end
endmodule
