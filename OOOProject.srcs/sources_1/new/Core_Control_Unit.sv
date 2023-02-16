`timescale 1ns / 1ps

module Core_Control_Unit
#(parameter ROBSIZE = 8,
  parameter LSQSIZE = 16)
(
  input logic                          start,
  input logic                          clk, 
  input logic                          rstn,
  // DECODER SIGNALS 
  input  logic                         rd_inst, // 1: The instruction writes to rd
  input  logic                         i_illegal_inst,
  input  logic                         i_cont_tra_inst,
  input  logic [1:0]                   i_load_store,
  input  logic [4:0]                   i_alu_opcode,
  output logic                         o_pc_stall,          
  // INSTRUCTION QUEUE SIGNALS 
  input  logic                         i_iq_empty,
  input  logic                         i_iq_full,
  output logic                         o_iq_rd_en,
  output logic                         o_iq_wrt_en,
  // RESERVATION STATION SIGNALS 
  input  logic                         i_rs1_full,
  input  logic                         i_rs2_full, 
  output logic                         o_rs1_we, 
  output logic                         o_rs2_we, 
  output logic                         o_adder1rs_we,
  // ROB SIGNALS 
  input  logic                         i_rob_full, 
  output logic                         o_rob_we, 
  // RAT SIGNALS 
  output logic                         o_rat_issue_we, 
  // ALU_CONTROL1 SIGNALS
  input  logic                         i_alu1_broadcast_ready,
  input  logic [31:0]                  i_alu1_broadcast_data,
  input  logic [$clog2(ROBSIZE):0]     i_alu1_broadcast_rob_addr,
  input  logic                         i_alu1_broadcast_addr_cal,
  input  logic                         i_alu1_broadcast_con_branch_comp, 
  output logic                         o_alu1_broadcast_en,
  // ALU_CONTROL2 SIGNALS
  input  logic                         i_alu2_broadcast_ready,
  input  logic [31:0]                  i_alu2_broadcast_data,
  input  logic [$clog2(ROBSIZE):0]     i_alu2_broadcast_rob_addr,
  input  logic                         i_alu2_broadcast_addr_cal,
  input  logic                         i_alu2_broadcast_con_branch_comp, 
  output logic                         o_alu2_broadcast_en,
  // DATA MEMORY BROADCAST SIGNALS 
  output logic                         o_mem_broadcast_en,        // Broadcast Enable 
  input  logic                         i_mem_broadcast_ready,     // Broadcast Data Ready 
  input  logic [$clog2(ROBSIZE):0]     i_mem_broadcast_rob_addr,  // Broadcast ROB Addr 
  input  logic [31:0]                  i_mem_broadcast_load_data, // Broadcast Data 
  // BROADCAST BUS SIGNALS 
  output logic                         o_broadcast_en,
  output logic [31:0]                  o_broadcast_data,  
  output logic [$clog2(ROBSIZE):0]     o_broadcast_rob_addr,
  output logic                         o_broadcast_addr_cal,
  output logic                         o_broadcast_con_branch_comp, 
  // COMMIT INPUT SIGNALS 
  input   logic                        i_commit_ready,
  input   logic [$clog2(ROBSIZE):0]    i_commit_rob_addr,
  input   logic [31:0]                 i_commit_inst_pc,
  input   logic [31:0]                 i_commit_value,
  input   logic [4:0]                  i_commit_rd,
  input   logic                        i_commit_exception,
  input   logic                        i_commit_rd_inst, 
  input   logic [2:0]                  i_commit_cont_tra_inst,
  input   logic [1:0]                  i_commit_load_store,
  // COMMIT OUTPUT SIGNALS 
  output  logic                        o_commit,
  output  logic [$clog2(ROBSIZE):0]    o_commit_rob_addr,
  output  logic [31:0]                 o_commit_inst_pc,
  output  logic [31:0]                 o_commit_value,
  output  logic [4:0]                  o_commit_rd,
  output  logic                        o_commit_exception,
  output  logic                        o_commit_rd_inst, 
  output  logic [2:0]                  o_commit_cont_tra_inst,  
  output  logic [1:0]                  o_commit_load_store,
  // FLUSH 
  output  logic                        o_flush,       
  output  logic [31:0]                 o_flush_pc,
  output  logic                        o_flush_taken,                    
  // LSQ COMMIT SIGNALS 
  output logic                         o_lsq_commit_en,
  input  logic                         i_lsq_commit_ready,
  input  logic                         i_lsq_commit_load_store,
  input  logic [31:0]                  i_lsq_commit_data,  
  input  logic [$clog2(ROBSIZE):0]     i_lsq_commit_rob_addr,
  input  logic                         i_mem_busy,
  // REGISTER FILE WRITE SIGNALS 
  output logic                         o_rf_we,
  output logic [4:0]                   o_rf_wrd,
  output logic [31:0]                  o_rf_rd_wvalue,
  // LOAD/STORE QUEUE SIGNALS 
  input logic                          i_lsq_full,     
  output logic                         o_lsq_new_inst_we
    );


//================
//  Local Signals 
//================
logic wrt_r11_or_r12;
logic rs_issue_we;
logic broadcast_alu_sel, broadcast_alu_sel_reg ;
    
//============================= 
//  PC STALL SIGNAL GENERATION  
//=============================
assign o_pc_stall = i_iq_full;    
   
//============================= 
//  INSTRUCTION QUEUE WRITE ENABLE SIGNAL
//=============================   
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      o_iq_wrt_en <= 1'b0;
   end else begin
      o_iq_wrt_en <= ~o_pc_stall;
   end 
end    
   
  
//===============================   
// Instruction Queue Read Enable Signal Generation    
//===============================         
assign o_iq_rd_en = ~i_rs1_full & ~i_rs2_full &  ~i_rob_full & ~i_iq_empty & ~i_lsq_full & start;  
    
//================================
// RESERVATION STATION WRITE-ENABLE SIGNAL 
//================================  

//============
// Choose the Reservation Station to write the Instruction 
//============

// RS write enable Generation
// We fetched an instruction that writes to rd OR Store Instruction for Address Calculation OR branch instructions. 
assign rs_issue_we       = o_iq_rd_en & (rd_inst | i_load_store[0] | i_alu_opcode[4]) & ~i_illegal_inst;
assign o_lsq_new_inst_we = o_iq_rd_en & |i_load_store & ~i_illegal_inst;
 
 
// Switch the Reservation Station on every Instruction Read. 
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      wrt_r11_or_r12 <= '0;
   end else begin
      if(o_iq_rd_en)
      begin
         wrt_r11_or_r12 <= ~wrt_r11_or_r12;
      end 
   end 
end 

assign o_rs1_we =  wrt_r11_or_r12  & rs_issue_we ;
assign o_rs2_we = ~wrt_r11_or_r12  & rs_issue_we ;
assign o_adder1rs_we = o_iq_rd_en & i_cont_tra_inst & ~i_illegal_inst;

//================================
// Instruction QUEUE WRITE ENABLE SIGNAL GENERATION  
//================================  
// Generate a ROB enable signal everytime we fetch an instruction from iq 
assign o_rob_we = o_iq_rd_en & ~i_illegal_inst;

//================================
// RAT Issue Write-Enable Signal 
//================================  
assign o_rat_issue_we = o_iq_rd_en & rd_inst & ~i_illegal_inst;

//================================
// BROADCAST BUS SIGNAL DRIVE 
//================================ 
// 1: Select ALU1 0: Select ALU2 //Always Select ALU 1 for now 

localparam REQSIZE = 3;
logic [(REQSIZE-1):0] req;
logic [(REQSIZE-1):0] grant;
assign req[0] = i_alu1_broadcast_ready;
assign req[1] = i_alu2_broadcast_ready;
assign req[2] = i_mem_broadcast_ready;
//
assign o_alu1_broadcast_en = grant[0];
assign o_alu2_broadcast_en = grant[1];
assign o_mem_broadcast_en  = grant[2];
//
always_comb
begin
   case(grant)
    'b001: begin
        o_alu1_broadcast_en  = 1'b1;
        o_broadcast_en       = 1'b1;  
        o_broadcast_data     = i_alu1_broadcast_data; 
        o_broadcast_rob_addr = i_alu1_broadcast_rob_addr; 
        o_broadcast_addr_cal = i_alu1_broadcast_addr_cal;  
        o_broadcast_con_branch_comp = i_alu1_broadcast_con_branch_comp;   
           end 
    'b010: begin
        o_alu2_broadcast_en  = 1'b1;
        o_broadcast_en       = 1'b1;  
        o_broadcast_data     = i_alu2_broadcast_data; 
        o_broadcast_rob_addr = i_alu2_broadcast_rob_addr; 
        o_broadcast_addr_cal = i_alu2_broadcast_addr_cal;   
        o_broadcast_con_branch_comp = i_alu2_broadcast_con_branch_comp;  
           end 
    'b100: begin
        o_mem_broadcast_en   = 1'b1;
        o_broadcast_en       = 1'b1; 
        o_broadcast_data     = i_mem_broadcast_load_data;
        o_broadcast_rob_addr = i_mem_broadcast_rob_addr;
        o_broadcast_addr_cal = 1'b0;   
        o_broadcast_con_branch_comp = 1'b0;                 
           end
     default: begin 
        o_alu1_broadcast_en  = '0;
        o_alu2_broadcast_en  = '0;
        o_mem_broadcast_en   = '0;
        o_broadcast_en       = '0;
        o_broadcast_data     = '0;
        o_broadcast_rob_addr = '0;
        o_broadcast_addr_cal = '0;  
        o_broadcast_con_branch_comp = '0;    
              end                        
   endcase 
end 



LSGF_ARBITER
#( .REQSIZE (3)) 
uLSGF_ARBITER
  (
    .clk     (clk), 
    .rstn    (rstn), 
    .i_req   (req),
    .o_grant (grant)
);




//================================
// COMMIT SIGNAL GENERATION & EXCEPTION HANDLING 
//================================
always_comb
begin
           o_commit            = '0; 
           o_rf_we             = '0;
           o_lsq_commit_en     = '0;  
           o_flush             = '0;
           //    
           o_commit_rob_addr      = i_commit_rob_addr;  
           o_commit_inst_pc       = i_commit_inst_pc;
           o_commit_value         = i_commit_value;
           o_commit_rd            = i_commit_rd;
           o_commit_exception     = i_commit_exception;
           o_commit_rd_inst       = i_commit_rd_inst; 
           o_commit_cont_tra_inst = i_commit_cont_tra_inst;
           o_commit_load_store    = i_commit_load_store;           
           o_rf_wrd               = i_commit_rd;
           o_rf_rd_wvalue         = '0; 
           //                           
   //====================
   // EXCEPTION HANDLING          
   //====================       
   if(i_commit_exception) begin  
      //====================
      // EXCEPTION HANDLING FOR CONDITIONAL BRANCH INSTRUCTIONS        
      //====================   
      if(i_commit_cont_tra_inst[0])
      begin      
         o_flush       = 1'b1;              // Generate Flush Flag 
         o_flush_pc    = i_commit_inst_pc;  // Set the PC to the PC of the COMMIT BRANCH
         o_flush_taken = i_commit_value[0]; // Take the Calculated Taken-NotTaken Value and Force the PC logic decision.             
      end 
           
   end else begin
   //====================
   // COMMIT SIGNAL GENERATION          
   //====================            
       case(i_commit_load_store)
         2'b00: // NO LOAD|STORE INSTRUCTION
           begin
              o_commit               = i_commit_ready & (~i_commit_exception);  

              //================================
              // Register File Write Signal Generation 
              //================================   
              o_rf_we             = o_commit & i_commit_rd_inst;  
              o_rf_rd_wvalue      = i_commit_value;       
           end 
         2'b01: // STORE INSTRUCTION
           begin 
              if(i_lsq_commit_ready) // Wait for the Instruction to be ready at LSQ
              begin
                 if(~i_mem_busy) // Wait Memory to be Available 
                 begin
                    o_lsq_commit_en = 1'b1;  // LSQ COMMIT ENABLE 
                    //
                    o_commit        = 1'b1;  // ROB/RAT COMMIT ENABLE                
                 end 
              end 
           end 
         2'b10:// LOAD INSTRUCTION  
           begin
              if(i_lsq_commit_ready)
              begin
                 o_lsq_commit_en     = 1'b1;  // LSQ COMMIT ENABLE 
                 //
                 o_commit            = 1'b1;  
                 //================================
                 // Register File Write Signal Generation 
                 //================================   
                 o_rf_we             = 1'b1;
                 o_rf_rd_wvalue      = i_lsq_commit_data;              
              end       
           end 
         2'b11: begin $display("[CONTROL UNIT]-LOAD|STORE ERROR"); end 
       endcase   
   end 
end 




     



 

  
   
endmodule :Core_Control_Unit



//========================
// CORE CONTROL UNIT TEST BENCH 
//========================
module Core_Control_Unit_tb();

parameter ROBSIZE = 8;

logic start;
logic clk; 
logic rstn;
// CONTROL SIGNALS 
logic rd_inst;
// INSTRUCTION QUEUE SIGNALS 
logic i_iq_empty;
logic o_iq_rd_en;
// RESERVATION STATION SIGNALS 
logic i_rs1_full;
logic i_rs2_full; 
logic o_rs1_we; 
logic o_rs2_we; 
// ROB SIGNALS 
logic i_rob_full; 
logic o_rob_we;
// RAT SIGNALS 
logic o_rat_issue_we; 
logic o_rat_update;
// ALU_CONTROL1 SIGNALS
logic                       i_alu1_broadcast_ready;
logic [31:0]                i_alu1_broadcast_data;
logic                       o_alu1_broadcast_en;
logic [$clog2(ROBSIZE):0]   i_alu1_broadcast_rob_addr;
// ALU_CONTROL2 SIGNALS
logic                       i_alu2_broadcast_ready;
logic [31:0]                i_alu2_broadcast_data; 
logic                       o_alu2_broadcast_en;
logic [$clog2(ROBSIZE):0]   i_alu2_broadcast_rob_addr;
// BROADCAST BUS SIGNALS 
logic                       o_broadcast_en;
logic [31:0]                o_broadcast_data; 
logic [$clog2(ROBSIZE):0]   o_broadcast_rob_addr;
// COMMIT SIGNALS 
logic                        i_commit_ready;
logic [31:0]                 i_commit_value;
logic [4:0]                  i_commit_rd;
logic                        i_commit_exception;
logic                        i_commit_rd_inst;  
logic                        o_commit;
// LSQ COMMIT SIGNALS 
// COMMIT SIGNALS 
logic                        o_lsq_commit_en;
logic                        i_lsq_commit_ready;
logic                        i_lsq_commit_load_store;
logic [31:0]                 i_lsq_commit_data;  
logic [$clog2(ROBSIZE):0]    i_lsq_commit_rob_addr;
logic                        i_mem_busy;
// REGISTER FILE WRITE SIGNALS 
logic                        o_rf_we;
logic [4:0]                  o_rf_wrd;
logic [31:0]                 o_rf_rd_wvalue;



//========================
// CLOCK GENERATION 
//========================
initial begin
   clk = 1'b0;
   forever #10 clk = ~clk;
end 

//========================
// RESET TASK: Generates an asyncrhonous, active low reset   
//========================
task RESET();
begin
  start                   = 1'b1;
  i_commit_ready          = '0;
  i_commit_value          = '0;
  i_commit_rd             = '0;
  i_commit_exception      = '0;
  i_commit_rd_inst        = '0;  
  i_iq_empty              = 1'b1; // IQ is empty initially
  i_rs1_full              = '0;
  i_rs2_full              = '0;
  i_rob_full              = '0;
  rd_inst                 = '0;
  i_alu1_broadcast_ready  = '0;
  i_alu2_broadcast_ready  = '0;
  i_lsq_commit_ready      = '0;
  i_lsq_commit_load_store = '0;
  i_lsq_commit_data       = '0;  
  i_lsq_commit_rob_addr   = '0;
  i_mem_busy              = '0;
  // 
  rstn = 1'b1;
  repeat(2) @(posedge clk); #2;
  rstn = 1'b0;
  repeat(2) @(posedge clk); #2;
  rstn = 1'b1;
  repeat(2) @(posedge clk); #3;
end 
endtask

//========================
// ALU CONTROL READY TO BROADCAST SIGNAL 
//========================
task ALU_BROADCAST(input logic         ALU1 = 1'b0,
                   input logic         ALU2 = 1'b0,
                   input logic [31:0]  ALU1_DATA = '0,
                   input logic [31:0]  ALU2_DATA = '0
                   );
begin
    @(posedge clk);
      i_alu1_broadcast_ready = ALU1;
      i_alu1_broadcast_data  = ALU1_DATA;
      i_alu2_broadcast_ready = ALU2;
      i_alu2_broadcast_data  = ALU2_DATA;    
    @(posedge clk);
      i_alu1_broadcast_ready = '0;
      i_alu1_broadcast_data  = '0;       
      i_alu2_broadcast_ready = '0;
      i_alu2_broadcast_data  = '0; 
end 
endtask

//========================
// KEEP THE IQ_EMPTY SIGNAL LOW FOR ready_cc CC to allow fetch signals 
//========================
task IQ_FETCH_READY (input int ready_cc,
                     input logic rd_inst_flg = 1'b1);
begin
     @(posedge clk);
       i_iq_empty <= 1'b0;
       rd_inst    <= rd_inst_flg;
     repeat(ready_cc) @(posedge clk);
       i_iq_empty <= 1'b1;            
end 
endtask


//========================
// CREATE delay_cc CC delay. 
//========================
task DELAY (input int delay_cc);
begin
     repeat(delay_cc) @(posedge clk);
end 
endtask



//================================
// MAIN STIMULUS 
//================================
initial begin
  RESET();
  //
  IQ_FETCH_READY ( .ready_cc (5));
  //
  DELAY(5);
  //
  ALU_BROADCAST( .ALU1 (1'b1), .ALU2 (1'b0), .ALU1_DATA  (32'hDEAD), .ALU2_DATA (32'hBEEF) );
  DELAY(5);
  //
  ALU_BROADCAST( .ALU1 (1'b0), .ALU2 (1'b1), .ALU1_DATA  (32'hDEAD), .ALU2_DATA (32'hBEEF) );
  DELAY(5);
  //
  ALU_BROADCAST( .ALU1 (1'b1), .ALU2 (1'b1), .ALU1_DATA  (32'hDEAD), .ALU2_DATA (32'hBEEF) );
  DELAY(5);
  //
  ALU_BROADCAST( .ALU1 (1'b1), .ALU2 (1'b1), .ALU1_DATA  (32'hDEAD), .ALU2_DATA (32'hBEEF) );
  DELAY(5);
  //
  repeat(10) @(posedge clk);
  $finish;
end 

//================================
// Module Instantiation 
//================================
Core_Control_Unit #(.ROBSIZE (ROBSIZE)) uCore_Control_Unit (.*);




endmodule :Core_Control_Unit_tb 




