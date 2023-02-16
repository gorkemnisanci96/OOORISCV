`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/24/2022 01:11:59 PM
// Design Name: 
// Module Name: DATA_MEM_CONTROL
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module DATA_MEM_CONTROL
#(parameter ROBSIZE=8)
(
   input logic                          clk,
   input logic                          rstn, 
   input logic                          i_cs,                 // CHIP SELECT
   input logic [31:0]                   i_addr,               // Memory Address 
   input logic [$clog2(ROBSIZE):0]      i_rob_addr,           // ROB Addr
   input logic                          i_load_store,         // LOAD OR STORE COMMAND 
   input logic [31:0]                   i_store_data,         // Store Data 
   input logic [1:0]                    i_size,               // Data Size-Byte|Half-Word|Word
   input logic                          i_signed_unsigned,    // Signed|Unsigned 
   // 
   input  logic                         i_broadcast_en,       // Broadcast Enable 
   output logic                         o_broadcast_ready,    // Broadcast Data Ready 
   output logic [$clog2(ROBSIZE):0]     o_broadcast_rob_addr, // Broadcast ROB Addr 
   output logic [31:0]                  o_broadcast_load_data,// Broadcast Data 
   //
   output logic                         o_mem_busy            //Memory Busy Flag 
);


logic [31:0] mem_read_data;  
//


logic [$clog2(ROBSIZE):0]      rob_addr,       rob_addr_next;
logic                          load_store,     load_store_next;
logic                          signed_unsigned,signed_unsigned_next;
logic [31:0]                   o_broadcast_load_data_next;
//

logic       mem_sel;
logic [2:0] mem_size;

typedef enum{
   IDLE,
   STATE1,
   STATE2,
   STATE3,   
   STATE4,
   STATE5,   
   STATE6,  
   STATE7,   
   STATE8,
   STATE9,   
   STATE10,
   BROADCAST 
} state_type;

state_type state, state_next; 



always_comb
begin
                                state_next        = state;
   mem_size             = '0;
   mem_sel              = '0;
   o_mem_busy           = '0;
   o_broadcast_ready    = '0;
   //
   rob_addr_next        = rob_addr;
   load_store_next      = load_store;
   signed_unsigned_next = signed_unsigned;
   //
   o_broadcast_rob_addr  = '0; // Broadcast ROB Addr 
   case(state)
      IDLE   : begin 
         if( i_cs)
         begin
                                state_next = STATE1;
           o_mem_busy           = 1'b1;
           mem_sel              = 1'b1;    
           mem_size = {i_signed_unsigned,i_size};          
           //    
           rob_addr_next        = i_rob_addr;
           load_store_next      = i_load_store;
           signed_unsigned_next = i_signed_unsigned;
         end 
               end 
      STATE1 : begin 
           o_mem_busy = 1'b1;       
                                  state_next = STATE2;
               end 
      STATE2 : begin 
           o_mem_busy = 1'b1;      
                                  state_next = STATE3;               
               end 
      STATE3 : begin 
           o_mem_busy = 1'b1;      
                                  state_next = STATE4;       
               end   
      STATE4 : begin 
           o_mem_busy = 1'b1;      
                                  state_next = STATE5;      
               end  
      STATE5 : begin 
           o_mem_busy = 1'b1;      
                                  state_next = STATE6;       
               end  
      STATE6 : begin 
           o_mem_busy = 1'b1;      
                                  state_next = STATE7;         
               end  
      STATE7 : begin 
           o_mem_busy = 1'b1;      
                                  state_next = STATE8;         
               end 
      STATE8 : begin 
           o_mem_busy = 1'b1;      
                                  state_next = STATE9;        
               end 
      STATE9 : begin 
           o_mem_busy = 1'b1;      
      o_broadcast_load_data_next = mem_read_data;
                                  state_next = STATE10;         
               end     
      STATE10 :begin
           o_mem_busy = 1'b1;       
                                  state_next = BROADCAST;         
               end                                                                                            
      BROADCAST :begin
           o_mem_busy = 1'b1;  
           o_broadcast_rob_addr  = rob_addr; // Broadcast ROB Addr 
           
               
           if(load_store)
           begin
                                 state_next = IDLE;
           end else begin
              
              if(i_broadcast_en)
              begin
                o_broadcast_ready = 1'b0;
                                 state_next = IDLE;              
              end else begin
                o_broadcast_ready = 1'b1;
              end  
           
           end 
      
                  end  
   endcase 



end 





//=====================
// STATE REGISTER 
//=====================
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      state <= IDLE;
   end else begin
      state <= state_next;
   end 
end 


//=====================
// REGISTERS 
//=====================
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      rob_addr               <= '0;
      load_store             <= '0;
      signed_unsigned        <= '0;
      o_broadcast_load_data  <= '0;
   end else begin
      rob_addr               <= rob_addr_next;
      load_store             <= load_store_next;
      signed_unsigned        <= signed_unsigned_next;
      o_broadcast_load_data  <= o_broadcast_load_data_next;
   end 
end 




AHB_TO_MEM 
#(.MEMWIDTH (32))	
uAHB_TO_MEM
  (
  //==== ==== Slave Select 
  .HSEL_i       (mem_sel),
  //==== ==== Clock and Reset Signals 
  .HCLK_i       (clk),  // Positive-edge triggered clock
  .HRESETn_i    (rstn),  // active-Low Reset 
  //==== ==== 
  .HREADY       ('0),
  .HADDR        (i_addr),
  .HTRANS       ('0),
  .HWRITE       (i_load_store),
  .HSIZE        (mem_size),
  .HWDATA       (i_store_data),
  //==== ==== Outputs 
  .HREADYOUT    (  ),
  .HRDATA       (mem_read_data)
);









endmodule 

//=============================
// TEST BENCH
//=============================
module DATA_MEM_CONTROL_tb();

parameter ROBSIZE = 8;

logic                         clk;
logic                         rstn; 
logic                         i_cs;
logic [31:0]                  i_addr;
logic [$clog2(ROBSIZE):0]     i_rob_addr;
logic                         i_load_store;
logic [31:0]                  i_store_data;
logic [1:0]                   i_size;
logic                         i_signed_unsigned;

logic                         i_broadcast_en;
logic                         o_broadcast_ready;
logic [$clog2(ROBSIZE):0]     o_broadcast_rob_addr;
logic [31:0]                  o_broadcast_load_data;

logic                         o_mem_busy; 

//=====================
// CLOCK GENERATION
//=====================
initial begin
   clk = 1'b0;
   forever #10 clk = ~clk;
end 

//=====================
// RESET GENERATION
//=====================
task RESET();
begin
   i_cs         = '0;
   i_addr       = '0;
   i_rob_addr   = '0;
   i_load_store = '0;
   i_store_data = '0;
   i_size       = '0;
   i_signed_unsigned = '0;
   i_broadcast_en    = '0;
   //
   rstn = 1'b1;
   @(posedge clk);
   rstn = 1'b0;
   repeat(2)@(posedge clk);
   rstn = 1'b1;
end 
endtask 


//==============================
// STORE TASK 
//==============================
task STORE(
   input logic [31:0]                addr,
   input logic [$clog2(ROBSIZE):0]   rob_addr,
   input logic [31:0]                store_data,
   input logic [1:0]                 size,
   input logic                       signed_unsigned
);
begin
        wait(~o_mem_busy)
        @(posedge clk);
          i_cs              <= 1'b1;
          i_addr            <= addr;
          i_rob_addr        <= rob_addr;
          i_load_store      <= 1'b1;
          i_store_data      <= store_data;
          i_size            <= size;
          i_signed_unsigned <= signed_unsigned;  
        @(posedge clk);          
          i_cs              <= '0;
          i_addr            <= '0;
          i_rob_addr        <= '0;
          i_load_store      <= '0;
          i_store_data      <= '0;
          i_size            <= '0;
          i_signed_unsigned <= '0; 
end 
endtask




//==============================
// LOAD TASK 
//==============================
task LOAD(
   input logic [31:0]                addr,
   input logic [$clog2(ROBSIZE):0]   rob_addr,
   input logic [1:0]                 size,
   input logic                       signed_unsigned
);
begin 
        wait(~o_mem_busy)
        @(posedge clk);
          i_cs              <= 1'b1;
          i_addr            <= addr;
          i_rob_addr        <= rob_addr;
          i_load_store      <= 1'b0;
          i_store_data      <= '0;
          i_size            <= size;
          i_signed_unsigned <= signed_unsigned; 
        @(posedge clk);          
          i_cs              <= '0;
          i_addr            <= '0;
          i_rob_addr        <= '0;
          i_load_store      <= '0;
          i_store_data      <= '0;
          i_size            <= '0;
          i_signed_unsigned <= '0; 
        @(posedge clk);  
        wait(o_broadcast_ready)@(posedge clk); 
          
end 
endtask

//==============================
// BROADCAST TASK
//==============================
task BROADCAST();
begin
        wait(o_broadcast_ready)
        @(posedge clk);
           $display("LOAD DATA:%h",o_broadcast_load_data);
           i_broadcast_en = 1'b1;
        @(posedge clk);          
           i_broadcast_en = 1'b0;
end 
endtask


initial begin
   RESET();
   //
   STORE( .addr (32'h0),  .rob_addr (5), .store_data (32'ha0), .size (2'b10), .signed_unsigned (1'b0));
   STORE( .addr (32'h4),  .rob_addr (6), .store_data (32'ha1), .size (2'b10), .signed_unsigned (1'b0));
   STORE( .addr (32'h8),  .rob_addr (7), .store_data (32'ha2), .size (2'b10), .signed_unsigned (1'b0));
   STORE( .addr (32'hC),  .rob_addr (8), .store_data (32'ha3), .size (2'b10), .signed_unsigned (1'b0));
   STORE( .addr (32'h10), .rob_addr (9), .store_data (32'ha4), .size (2'b10), .signed_unsigned (1'b0));
   //
   LOAD ( .addr (32'h0),  .rob_addr (5), .size (2'b10),.signed_unsigned (1'b0));
   BROADCAST();
   LOAD ( .addr (32'h4),  .rob_addr (6), .size (2'b10),.signed_unsigned (1'b0));
   BROADCAST();
   LOAD ( .addr (32'h8),  .rob_addr (7), .size (2'b10),.signed_unsigned (1'b0));
   BROADCAST();
   LOAD ( .addr (32'hC),  .rob_addr (8), .size (2'b10),.signed_unsigned (1'b0));
   BROADCAST();
   LOAD ( .addr (32'h10), .rob_addr (9), .size (2'b10),.signed_unsigned (1'b0));
   BROADCAST();
   $finish;
end 



//============================
// DATA MEMORY CONTROL INSTANTIATION
//============================
DATA_MEM_CONTROL
#(.ROBSIZE (ROBSIZE))
uDATA_MEM_CONTROL
(.*);




endmodule 
