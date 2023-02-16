`timescale 1ns / 1ps

module EXPERIMENT(
   input logic [3:0] num1,
   input logic [3:0] num2
);


logic signed [3:0] num1_signed;
logic signed  [3:0] num2_signed;

assign num1_signed = num1;
assign num2_signed = num2;


logic result1;

logic result2;

assign result1 = (num1<num2);
assign result2 = (num1_signed<num2_signed);

always_comb
begin
   $display("result1 %b ", (num1<num2));
   $display("result2 %b ", (num1_signed<num2_signed));
end 


logic [2:0] twod [31:0];

assign twod[5][1] = 1'b1;
assign twod[6][2] = 1'b1;




endmodule

module tb();


logic [3:0] num1;
logic [3:0] num2;
logic result;

initial begin
   num1 = 4'b1111;
   num2 = 4'b0001;
   #10;
   $finish;
end 


EXPERIMENT uEXPERIMENT(.*);

endmodule 
