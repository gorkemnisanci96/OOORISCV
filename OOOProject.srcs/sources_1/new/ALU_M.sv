`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// RV32M Standard Extension
// funct7  rs2 rs1 funct3  rd  opcode
// 0000001 rs2 rs1  000    rd 0110011 MUL
// 0000001 rs2 rs1  001    rd 0110011 MULH
// 0000001 rs2 rs1  010    rd 0110011 MULHSU
// 0000001 rs2 rs1  011    rd 0110011 MULHU
// 0000001 rs2 rs1  100    rd 0110011 DIV
// 0000001 rs2 rs1  101    rd 0110011 DIVU
// 0000001 rs2 rs1  110    rd 0110011 REM
// 0000001 rs2 rs1  111    rd 0110011 REMU
//////////////////////////////////////////////////////////////////////////////////
// Instruction Functionality 
// MUL: 
// MUL performs an XLEN-bit×XLEN-bit multiplication of rs1 by rs2 and places the lower XLEN bits
// in the destination register.
// MULH:
// Returns the upper 32-bit for signed×signed Multiplication. 
// MULHU: 
// Returns the upper 32-bit for unsigned×unsigned Multiplication. 
// MULHSU: 
// Returns the upper 32-bit for signed rs1×unsigned rs2 Multiplication. 
// DIV:
// It performs a 32 bits by 32 bits signed integer division of rs1 by
// rs2, rounding towards zero. 
// DIVU:
// It performs a 32 bits by 32 bits unsigned integer division of rs1 by
// rs2, rounding towards zero. 
// REM:
// REM provides the remainder of the DIV division operation.
// REMU:
// REMU provides the remainder of the DIV division operation.


module ALU_M(
 input  logic [31:0] i_num1,
 input  logic [31:0] i_num2, 
 input  logic [2:0]  i_opsel, 
 output logic [31:0] o_result
    );
 
// Local Signals     
logic [31:0] mul_result;    
logic [31:0] mulh_result;    
logic [31:0] mulhsu_result;    
logic [31:0] mulhu_result;
logic [31:0] div_result;
logic [31:0] divu_result;
logic [31:0] rem_result;
logic [31:0] remu_result;
    
     
    
    
    
    
    
    
////////////
// Output Selection MUX 
////////////
always_comb
begin
   case(i_opsel)
     3'b000: o_result = mul_result;
     3'b001: o_result = mulh_result;
     3'b010: o_result = mulhsu_result;
     3'b011: o_result = mulhu_result;
     3'b100: o_result = div_result;
     3'b101: o_result = divu_result;
     3'b110: o_result = rem_result;
     3'b111: o_result = remu_result;
   endcase 
end 


        
endmodule :ALU_M



//=======================
// ALU TEST BENCH 
//=======================
module ALU_M_tb();
// funct7  rs2 rs1 funct3  rd  opcode
// 0000001 rs2 rs1  000    rd 0110011 MUL
// 0000001 rs2 rs1  001    rd 0110011 MULH
// 0000001 rs2 rs1  010    rd 0110011 MULHSU
// 0000001 rs2 rs1  011    rd 0110011 MULHU
// 0000001 rs2 rs1  100    rd 0110011 DIV
// 0000001 rs2 rs1  101    rd 0110011 DIVU
// 0000001 rs2 rs1  110    rd 0110011 REM
// 0000001 rs2 rs1  111    rd 0110011 REMU

logic clk;
initial begin
   clk = 1'b0;
   forever #10 clk = ~clk; 
end 


logic [31:0] i_num1;
logic [31:0] i_num2; 
logic [2:0]  i_opsel; 
logic [31:0] o_result;

//====================
// MUL Instruction 
//====================
task MUL(
  input logic [31:0] rs1,
  input logic [31:0] rs2
);
begin
   @(posedge clk);
     i_opsel <= 3'b000;
     i_num1  <= rs1;
     i_num2  <= rs2;
   @(posedge clk);
     $display("MUL %h %h == %h",rs1,rs2,o_result);
end 
endtask

//====================
// MULH Instruction 
//====================
task MULH(
  input logic [31:0] rs1,
  input logic [31:0] rs2
);
begin
   @(posedge clk);
     i_opsel <= 3'b001;
     i_num1 <= rs1;
     i_num2 <= rs2;
   @(posedge clk);
     $display("MULH %h %h == %h",rs1,rs2,o_result);
end 
endtask

//====================
// MULH Instruction 
//====================
task MULHSU(
  input logic [31:0] rs1,
  input logic [31:0] rs2
);
begin
   @(posedge clk);
     i_opsel <= 3'b010;
     i_num1 <= rs1;
     i_num2 <= rs2;
   @(posedge clk);
     $display("MULHSU %h %h == %h",rs1,rs2,o_result);
end 
endtask

//====================
// MULHU Instruction 
//====================
task MULHU(
  input logic [31:0] rs1,
  input logic [31:0] rs2
);
begin
   @(posedge clk);
     i_opsel <= 3'b011;
     i_num1 <= rs1;
     i_num2 <= rs2;
   @(posedge clk);
     $display("MULHU %h %h == %h",rs1,rs2,o_result);
end 
endtask

//====================
// DIV Instruction 
//====================
task DIV(
  input logic [31:0] rs1,
  input logic [31:0] rs2
);
begin
   @(posedge clk);
     i_opsel <= 3'b100;
     i_num1 <= rs1;
     i_num2 <= rs2;
   @(posedge clk);
     $display("DIV %h %h == %h",rs1,rs2,o_result);
end 
endtask

//====================
// DIVU Instruction 
//====================
task DIVU(
  input logic [31:0] rs1,
  input logic [31:0] rs2
);
begin
   @(posedge clk);
     i_opsel <= 3'b101;
     i_num1 <= rs1;
     i_num2 <= rs2;
   @(posedge clk);
     $display("DIVU %h %h == %h",rs1,rs2,o_result);
end 
endtask

//====================
// REM Instruction 
//====================
task REM(
  input logic [31:0] rs1,
  input logic [31:0] rs2
);
begin
   @(posedge clk);
     i_opsel <= 3'b110;
     i_num1 <= rs1;
     i_num2 <= rs2;
   @(posedge clk);
     $display("REM %h %h == %h",rs1,rs2,o_result);
end 
endtask

//====================
// REMU Instruction 
//====================
task REMU(
  input logic [31:0] rs1,
  input logic [31:0] rs2
);
begin
   @(posedge clk);
     i_opsel <= 3'b111;
     i_num1 <= rs1;
     i_num2 <= rs2;
   @(posedge clk);
     $display("REMU %h %h == %h",rs1,rs2,o_result);
end 
endtask


//=========================
// MAIN STIMULUS 
//=========================
initial begin


$finish;
end 





//======================
// MODULE Instantiation 
//======================
ALU_M uALU_M(.*);

endmodule 
