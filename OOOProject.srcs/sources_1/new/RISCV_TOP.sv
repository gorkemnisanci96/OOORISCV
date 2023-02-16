`timescale 1ns / 1ps

module RISCV_TOP
(
input logic        clk, 
input logic        rstn
    );
 
parameter ROBSIZE = 8; 
 
    
///////////////////////////////////////
//// STAGE 2 Wires and Registers 
///////////////////////////////////////    
logic [6:0]  opcode;
logic [2:0]  funct3;
logic [6:0]  funct7;
logic [4:0]  rs1;
logic [4:0]  rs2;
logic [4:0]  rd;
//    
logic Flush =1'b0;
logic [$clog2(ROBSIZE):0] rs1_ROB_Addr;
logic [$clog2(ROBSIZE):0] rs2_ROB_Addr;
logic                     rs1_ROB_or_RF;
logic                     rs2_ROB_or_RF; 
//
logic [31:0]              RF_rs1_Value;
logic [31:0]              RF_rs2_Value;
logic [31:0]              ROB_rs1_Value;
logic [31:0]              ROB_rs2_Value;
logic [31:0]              rs1_Value;
logic [31:0]              rs2_Value;
//
logic                     Inst_Queue_Empty;
logic                     Inst_Queue_Full;
logic                     Inst_Queue_ReEn=1'b0;
logic                     Inst_Queue_WrEn=1'b0;
logic [31:0]              Inst_Queue_InstOut;
logic [31:0]              Inst_Queue_InstIn;
//
logic                     RF_WrEn=1'b0;
logic [4:0]               RF_WrAddr;
logic [31:0]              RF_WrValue;
// Stage 1 Signals 
logic rob_full;
logic int_rs_full; 
logic mul_rs_full;
logic ls_queue_full;
//
logic iq_ren;
logic rob_we;

///////////////////////////////////////
//// STAGE 1 
///////////////////////////////////////
INSTRUCTION_QUEUE
#( .DATAWITHBIT (32),
   .FIFOSIZE    (8))
uINSTRUCTION_QUEUE
(
    .clk           (clk),
    .rstn          (rstn),
    //
    .i_flush       (Flush),
    //
    .i_wrt_en      (Inst_Queue_WrEn),
    .i_wrt_data    (Inst_Queue_InstIn),
    //
    .i_rd_en       (Inst_Queue_ReEn),
    .o_rd_data     (Inst_Queue_InstOut),
    //
    .o_full        (Inst_Queue_Full),
    .o_empty       (Inst_Queue_Empty)
 );








///////////////////////////////////////
//// STAGE 2 
///////////////////////////////////////

    
//////////////////////////    
//    
//////////////////////////    
assign opcode   = Inst_Queue_InstOut[6:0];
assign funct3   = Inst_Queue_InstOut[14:12];
assign funct7   = Inst_Queue_InstOut[31:25];
assign rs1      = Inst_Queue_InstOut[19:15];
assign rs2      = Inst_Queue_InstOut[24:20];
assign rd       = Inst_Queue_InstOut[11:7];  
assign CSR_uimm = Inst_Queue_InstOut[19:15];
assign csr_addr = Inst_Queue_InstOut[31:20];    
    
//////////////////////////    
// CONTROL MODULE 
//////////////////////////       
CONTROL_MODULE uCONTROL_MODULE(
    .clk             (clk),
    .rstn            (rstn), 
    // STAGE 1 SIGNALS 
    .i_iq_empty      (Inst_Queue_Empty),
    .i_rob_full      (rob_full), 
    .i_int_rs_full   (int_rs_full),
    .i_mul_rs_full   (mul_rs_full),
    .i_ls_queue_full (ls_queue_full),
    //
    .o_iq_ren        (iq_ren),
    .o_rob_we        (rob_we)
    );    
    
  
//////////////////////////////////////  
//  INSTRUCTION DECODE MODULE 
//////////////////////////////////////  
ID  uID(
.inst_i           (Inst_Queue_InstOut),
.opcode_i         (opcode),
.funct3_i         (funct3),
.funct7_i         (funct7),
.stall_flag_i     (0),
.invalid_inst_o   ( ),
.alu_op_sel_o     ( ),
.load_mux_sel_o   ( ),
.data_mem_op_sel  ( ),
.alu_in_sel_o     ( ),
.imm_sel_o        ( ),
.jump_sel_o       ( ),
.branch_inst_o    ( ),
.load_inst_o      ( ),
.rs2_is_imm_o     ( ),
.csr_inst_o       ( ),
.ebreak_inst_o    ( ),
.ecall_inst_o     ( ),
.mret_inst_o      ( ) 
    );  
  
  
    
//////////////////////////    
// RAT MODULE INSTANTIATION 
//////////////////////////      
RAT
#(.ROBSIZE (ROBSIZE))
uRAT
(
    .clk               (clk),
    .rstn              (rstn),
    //
    .i_flush           (Flush),
    //
    .i_we              (0),
    .i_rd              (0),
    .i_ROB_Addr        (0),
    .i_ROB_or_RF       (0),
    //
    .i_rs1             (rs1),
    .i_rs2             (rs2),
    .o_rs1_ROB_Addr    (rs1_ROB_Addr),
    .o_rs2_ROB_Addr    (rs2_ROB_Addr),
    .o_rs1_ROB_or_RF   (rs1_ROB_or_RF),
    .o_rs2_ROB_or_RF   (rs2_ROB_or_RF)
    );    

//////////////////////////    
// REGISTER FILE INSTANTIATION 
//////////////////////////       
REGISTER_FILE uREGISTER_FILE(
  .clk             (clk),
  .i_rs1           (rs1),
  .i_rs2           (rs2),
  //
  .i_we            (RF_WrEn),
  .i_rd            (RF_WrAddr),
  .i_rd_Value      (RF_WrValue),
  //
  .o_rs1_RF_Value  (RF_rs1_Value),
  .o_rs2_RF_Value  (RF_rs2_Value)
    );    
// 
//////////////////////////    
// ROB INSTANTIATION 
//////////////////////////         
ROB
#(.ROBSIZE (ROBSIZE))
uROB
(
.clk              (clk),
.rstn             (rstn),
//
.i_issue_we       (0),
.i_issue_rd       (0),
//
.i_exedone_flag   (0), // It tells that one of the instructions finished execution  so we need to update ROB
.i_exedone_tag    (0),  // When the i_exedone_flag is high, it tells which ROB entry finished execution
.i_val            (0),          // The instruction that finished the execution generated this value         
// 
.i_rs1_ROB_Addr   (rs1_ROB_Addr),
.i_rs2_ROB_Addr   (rs2_ROB_Addr),
.o_ROB_rs1_Value  (ROB_rs1_Value),
.o_ROB_rs2_Value  (ROB_rs2_Value),
.o_ROB_rs1_Valid  (ROB_rs1_Valid),
.o_ROB_rs2_Valid  (ROB_rs2_Valid),
//
.o_commit_flag    ( ),
.o_commitval      ( ),
.o_commitrd       ( ),
.o_exception      ( ),
.o_robfull_flag   ( )
    );
    

//////////////////////////    
// MUX: Make Selection between Source Value from ROB or Register Bank  
//////////////////////////   
assign rs1_Value = rs1_ROB_or_RF ? ROB_rs1_Value : RF_rs1_Value ;
assign rs2_Value = rs2_ROB_or_RF ? ROB_rs2_Value : RF_rs2_Value ;


    
    
    
    
RESERVATION_STATION I_RESERVATION_STATION(
  .clk         (clk),
  .rstn        (rstn),
  //
  .i_we        (i_we),
  .i_rs1_value (rs1_value),
  .i_rs2_value (rs2_value),   
  
  .o_full      (int_rs_full),
  .o_empty     ()
    );    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
endmodule :RISCV_TOP




module RISCV_TOP_tb();

logic clk;
logic rstn;

/////////////////////
//  CLOCK GENERATION 
////////////////////
initial begin
clk = 1'b0;
 fork
   forever #10 clk = ~clk; 
 join
end 
/////////////////////
//  RESET TASK 
////////////////////
task RESET();
begin
   rstn = 1'b1;
   repeat(2)@(posedge clk);
   rstn = 1'b0;
   repeat(2)@(posedge clk);
   rstn = 1'b1;
end 
endtask 

/////////////////////
//  WRITE TO INSTRUCTION QUEUE  
////////////////////
task WriteToInstQueue( input logic [31:0] DataIn);
begin
     @(posedge clk); #1;
     uRISCV_TOP.Inst_Queue_WrEn = 1'b1;
     uRISCV_TOP.Inst_Queue_InstIn = DataIn;
     @(posedge clk); #1;
     uRISCV_TOP.Inst_Queue_WrEn = 1'b0;
end 
endtask 
/////////////////////
//  READ INSTRUCTION QUEUE 
////////////////////
task ReadInstQueue();
begin
    @(posedge clk);  #1;
    uRISCV_TOP.Inst_Queue_ReEn = 1'b1;
    @(posedge clk);  #1;  
    uRISCV_TOP.Inst_Queue_ReEn = 1'b0;
end 
endtask 



initial begin
RESET();
WriteToInstQueue(32'h12345678);
repeat(2) @(posedge clk);
ReadInstQueue();

repeat(30) @(posedge clk);
$finish; 
end 


////////////////////
//  RISC-V TOP MODULE INSTANTIATION 
////////////////////
RISCV_TOP uRISCV_TOP
(
.clk   (clk), 
.rstn  (rstn)
    );




endmodule :RISCV_TOP_tb

 
