`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// BRANCH TARGET BUFFER 


module BTB
#(parameter PCSIZE = 10)
(
  input  logic clk, 
  input  logic rstn,
  // FLUSH FLAG
  input logic                 i_flush, 
  // PC NEW READ OP 
  input  logic [(PCSIZE-1):0] i_pc,
  output logic [31:0]         o_pc_target,
  output logic                o_pc_target_valid, 
  // PC NEW WRITE OP 
  input logic                 i_wen,
  input logic [(PCSIZE-1):0]  i_write_pc_addr,  
  input logic [31:0]          i_write_pc_target,
  // INVALIDATE 
  input logic                 i_invalid, 
  input logic [(PCSIZE-1):0]  i_invalid_pc_addr
    );
    
    
    
logic [31:0]              PC_TARGET [(2**PCSIZE -1 ):0];
logic [(2**PCSIZE -1 ):0] VALID;   
    
    
    
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      for(int i=0;i<(2**PCSIZE);i++)
      begin
         VALID[i] <= '0;
      end 
   end else if (i_flush)
   begin
      for(int i=0;i<(2**PCSIZE);i++)
      begin
         VALID[i] <= '0;
      end    
   end else begin
       // WRITE LOGIC 
       if(i_wen)
       begin
          PC_TARGET[i_write_pc_addr] <= i_write_pc_addr;
          VALID[i_write_pc_addr]     <= 1'b1;
       end 
       // INVALIDATE LOGIC 
       if(i_invalid)
       begin
          PC_TARGET[i_invalid_pc_addr] <= '0;
          VALID[i_invalid_pc_addr]     <= 1'b0;
       end 
       //
   end 


end      
   
   
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      o_pc_target       <= '0;
      o_pc_target_valid <= '0;
   end else begin
      o_pc_target       <= PC_TARGET[i_pc];
      o_pc_target_valid <= VALID[i_pc];
   end 
end    
   
    
    
    
    
endmodule




module BTB_tb();

parameter PCSIZE = 10;

logic                 clk;
logic                 rstn;
// FLUSH FLAG
logic                 i_flush; 
// PC NEW READ OP 
logic [(PCSIZE-1):0]  i_pc;
logic [31:0]          o_pc_target;
logic                 o_pc_target_valid; 
// PC NEW WRITE OP 
logic                 i_wen;
logic [(PCSIZE-1):0]  i_write_pc_addr;  
logic [31:0]          i_write_pc_target;
// INVALIDATE 
logic                 i_invalid; 
logic [(PCSIZE-1):0]  i_invalid_pc_addr;


initial begin
   clk = 1'b0;
   forever #10 clk = ~clk;
end 

task RESET();
begin
   i_flush = 1'b0;
   i_pc    = '0;
   i_wen   = '0;
   i_write_pc_addr   ='0;
   i_write_pc_target ='0;
   i_invalid         ='0;
   i_invalid_pc_addr ='0;
   //
   rstn = 1'b1;
   @(posedge clk);
   rstn = 1'b0;
   repeat(2)@(posedge clk);
   rstn = 1'b1;
end 
endtask 

//============================
// WRITE NEW PC TARGET TASK 
//============================

//============================
// INVALIDATE A PC TARGET TASK 
//============================


initial begin
   RESET();

   
   $finish;
end 

BTB
#(.PCSIZE (PCSIZE))
uBTB
(.*);

endmodule 
