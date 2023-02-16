`timescale 1ns / 1ps


module CONTROL_MODULE(
    input logic clk,
    input logic rstn, 
    //
    input logic i_iq_empty,
    input logic i_rob_full, 
    input logic i_int_rs_full,
    input logic i_mul_rs_full,
    input logic i_ls_queue_full,
    //
    output logic o_iq_ren,
    output logic o_rob_we
    );
    
/////////////////////
// STAGE 1 OPERATIONS 
/////////////////////
// Instruction Queue Read Enable Signal Generation 
// If the RS,ROB,LS are full and IQ is not easy. 
assign o_iq_ren = ~i_iq_empty & ~i_rob_full & ~i_int_rs_full & ~i_mul_rs_full & ~i_ls_queue_full;
// ROB Write Enable Signal 
// We write all the instructions to the ROB so whenever we read IQ, we write to the ROB
assign o_rob_we = o_iq_ren;



/////////////////////
// STAGE 2 OPERATIONS 
/////////////////////




    
endmodule :CONTROL_MODULE 
