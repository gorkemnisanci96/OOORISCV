`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// PROGRAM ROM 


module PROGRAM_MEM
#( parameter MEMSIZE = 10 )
(
   input  logic                   clk, 
   input  logic                   rstn, 
   input  logic [(MEMSIZE-1):0]   i_addr,
   output logic [31:0]            o_inst 
    );
    
    
logic [31:0] ROM [(2**MEMSIZE-1):0];


always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      o_inst <= 32'h13; // NOP INSTRUCTION 
   end else begin
      o_inst <= ROM[i_addr];
   end 
end 


    
    
    
endmodule
