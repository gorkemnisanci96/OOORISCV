`timescale 1ns / 1ps
// The Test Bench Stimulus 
// 1 - Fill the Instruction Queue with Instructions 





module CORE
#(parameter DATAWITHBIT = 32,
  parameter FIFOSIZE    = 8,
  parameter ROBSIZE     = 8,
  parameter RSSIZE      = 16,
  parameter LSQSIZE     = 16)
(
  input logic                      start,
  input logic                      clk,
  input logic                      rstn
);


//================================
// Local Signals    
//================================
localparam [31:0] PC_BOOT    = 32'h0; 
localparam PROGMEMSIZE       = 10; 
localparam BRANCHTABLEPCSIZE = 10;
localparam PHISTORYSIZE      = 3;
localparam GHISTORYSIZE      = 3;
//
logic [31:0]               pc;
logic [31:0]               pc_reg;
logic [31:0]               btb_pc_target;
logic                      btb_pc_target_valid;
logic                      bht_taken;
logic [31:0]               progmem_out;
logic                      pc_stall;
logic                      branch_taken_decision;
// TARGET PC CALCULATION 
logic [31:0]               b_type_imm;
logic [31:0]               j_type_imm;
logic [31:0]               branch_target;
logic [31:0]               jal_target;
logic [31:0]               pc_target;
logic                      taken_prediction;
logic                      bht_update_en;

//
logic                      flush      ,flush_reg;
logic [31:0]               flush_pc;
logic                      flush_taken,flush_taken_reg;  
//
logic                      iq_rd_en;
logic [(DATAWITHBIT-1):0]  inst;
logic [31:0]               inst_pc;
logic                      iq_full;
logic                      iq_empty;
logic                      iq_wrt_en;
logic  [31:0]              iq_wrt_inst; 
//
logic                      rob_full; 
// 
logic [6:0]   opcode;
logic [4:0]   rs1;
logic [4:0]   rs2;
logic [4:0]   rd;
logic [2:0]   funct3;
logic [6:0]   funct7;
//
logic [2:0]                 imm_type; 
logic [31:0]                imm;
logic                       illegal_inst;
//
logic [31:0]                rs1_rf_value;
logic [31:0]                rs2_rf_value;
logic                       rf_we;  
logic [4:0]                 rf_rd;  
logic [31:0]                rf_rd_value;  
//
logic                       rat_issue_we;
logic                       rat_update;
logic                       rat_issue_rob_or_rf;
//
logic [$clog2(ROBSIZE):0]   rat_rs1_rob_addr;
logic [$clog2(ROBSIZE):0]   rat_rs2_rob_addr;
logic                       rat_rs1_rob_or_rf;
logic                       rat_rs2_rob_or_rf; 
//
logic                       rob_we;
logic [4:0]                 rob_rd;
logic [$clog2(ROBSIZE):0]   rob_issue_ptr;
//
logic                       rob_exedone_flag; // It tells that one of the instructions finished execution  so we need to update ROB
logic [$clog2(ROBSIZE)-1:0] rob_exedone_tag;  // When the i_exedone_flag is high, it tells which ROB entry finished execution
logic [31:0]                rob_exe_val;      // The instruction that finished the execution generated this value         
// 
logic [31:0]                rob_rs1_value;
logic [31:0]                rob_rs2_value;
logic                       rob_rs1_valid;
logic                       rob_rs2_valid;
//
logic                       rob_commit_ready;
logic [$clog2(ROBSIZE):0]   rob_commit_rob_addr;
logic [31:0]                rob_commit_inst_pc;
logic [31:0]                rob_commit_value;
logic [4:0]                 rob_commit_rd;
logic                       rob_commit_exception;
logic                       rob_commit_rd_inst;
logic [1:0]                 rob_commit_load_store;
logic [2:0]                 rob_commit_cont_tra_inst;
logic                       commit_en;
logic [$clog2(ROBSIZE):0]   commit_rob_addr;
logic [31:0]                commit_inst_pc;
logic [31:0]                commit_value;
logic [4:0]                 commit_rd;
logic                       commit_exception;
logic                       commit_rd_inst;
logic [2:0]                 commit_cont_tra_inst;
logic [1:0]                 commit_load_store;
// 
logic [31:0]                rs_rs1_value;
logic [31:0]                rs_rs2_value;
//
logic                       rs1_issue_we;
logic                       rs2_issue_we;
logic [4:0]                 alu_opcode;
logic                       rs_rs1_valid; 
logic                       rs_rs2_valid; 
  // Dispatch Signals 
logic                       alu1_busy;
logic [4:0]                 alu1_opcode;
logic [31:0]                alu1_rs1_value;
logic [31:0]                alu1_rs2_value;   
logic [$clog2(ROBSIZE):0]   alu1_rob_addr;
logic                       alu1_ex_en;
//
logic                       alu2_busy;
logic [4:0]                 alu2_opcode;
logic [31:0]                alu2_rs1_value;
logic [31:0]                alu2_rs2_value;   
logic [$clog2(ROBSIZE):0]   alu2_rob_addr;
logic                       alu2_ex_en;
// BROADCAST SIGNALS 
logic                       alu1_broadcast_en;
logic                       alu1_broadcast_ready; 
logic [31:0]                alu1_broadcast_data;
logic [$clog2(ROBSIZE):0]   alu1_broadcast_rob_addr;
logic                       alu1_broadcast_addr_cal;
logic                       alu1_broadcast_con_branch_comp;
// 
logic                       alu2_broadcast_en;
logic                       alu2_broadcast_ready; 
logic [31:0]                alu2_broadcast_data;
logic [$clog2(ROBSIZE):0]   alu2_broadcast_rob_addr;
logic                       alu2_broadcast_addr_cal;
logic                       alu2_broadcast_con_branch_comp;
// TARGET ADDRESS CACLULATION ADDER & ReservationStation SIGNALS - ADDER1
logic                       adder1rs_issue_we;
logic [31:0]                adder1rs_rs1_value;
logic [31:0]                adder1rs_rs2_value;
logic                       adder1_busy;
logic [4:0]                 adder1_opcode;
logic [31:0]                adder1_rs1_value; 
logic [31:0]                adder1_rs2_value;
logic [$clog2(ROBSIZE):0]   adder1_rob_addr;
logic                       adder1_ex_en;
logic                       adder1rs_full;
logic                       adder1_broadcast_en;
logic                       adder1_broadcast_ready;
logic  [31:0]               adder1_broadcast_data;    
logic                       adder1_broadcast_rob_addr;
// BROADCAST SIGNALS 
logic                       broadcast_en;
logic [$clog2(ROBSIZE):0]   broadcast_rob_addr;
logic [31:0]                broadcast_data;
logic                       broadcast_addr_cal;
logic                       broadcast_con_branch_comp;
// Reservation Station FULL Flag 
logic                       rs1_full; 
logic                       rs2_full; 
// DECODER SIGNALS 
logic                       rd_inst; 
logic                       imm_inst;
logic [2:0]                 cont_tra_inst;
logic                       m_inst;
logic [1:0]                 load_store;
logic                       load_unsigned;
logic [1:0]                 load_size;
// LOAD/STORE QUEUE SIGNALS 
logic                       lsq_new_inst_we;
logic [31:0]                lsq_rs2_data;
logic [$clog2(ROBSIZE):0]   lsq_rs2_rob_addr;
logic                       lsq_rs2_data_valid;
logic                       lsq_load_or_store;   
logic                       lsq_full;
logic                       lsq_empty;
// LSQ COMMIT SIGNALS 
logic                       lsq_commit_en;
logic                       lsq_commit_ready;
logic                       lsq_commit_load_store;
logic [31:0]                lsq_commit_data;  
logic [$clog2(ROBSIZE):0]   lsq_commit_rob_addr;
// DATA MEMORY SIGNALS 
logic                       data_mem_busy;
logic [31:0]                data_mem_addr;
logic                       data_mem_cs;
logic [$clog2(ROBSIZE):0]   data_mem_rob_addr;
logic                       data_mem_load_store;
logic [31:0]                data_mem_store_data;
logic [1:0]                 data_mem_size;
logic                       data_mem_signed_unsigned;
//
logic                       mem_broadcast_en;       // Broadcast Enable 
logic                       mem_broadcast_ready;    // Broadcast Data Ready 
logic [$clog2(ROBSIZE):0]   mem_broadcast_rob_addr; // Broadcast ROB Addr 
logic [31:0]                mem_broadcast_load_data;// Broadcast Data 
//   


//================================
// Simulation Only Initializations     
//================================



//=========================================================================
//=========================================================================
// STAGE-1 || FRONT-END || PC MUX   
//=========================================================================
//=========================================================================



always_comb
begin
   branch_taken_decision = (flush_reg & flush_taken_reg) ? 1'b1 : bht_taken;
   //
   if(!rstn)
   begin
      pc = PC_BOOT;
   end else begin
      if(pc_stall)
      begin
         pc = pc_reg;
      end else if(flush)
      begin
        pc = flush_pc;
      end else begin
            if(branch_taken_decision) begin
               pc = pc_target;
            end else begin
               pc = pc_reg + 4;
            end 
      end 
      //   
   end 

end 


//=========================================================================
//=========================================================================
// STAGE-2 || FRONT-END || REGISTERS-BHT-BTB-PROGRAM MEM-    
//=========================================================================
//=========================================================================
logic                      flush      ,flush_reg;
logic [31:0]               flush_pc;
logic                      flush_taken,flush_taken_reg;  

//===============================
//  STAGE1-STAGE2 Registers 
//===============================
always_ff @(posedge clk or negedge rstn)
begin
   //
   if(!rstn)
   begin
      pc_reg           <= PC_BOOT;
      flush_reg        <= 1'b0;
      flush_taken_reg  <= 1'b0;
   end else begin
      pc_reg           <= pc;
      flush_reg        <= flush;
      flush_taken_reg  <= flush_taken;
   end
   // 
end 




//===============================
//  BRANCH HISTORY TABLE 
//===============================
// Update the BHT when there is a FLUSH or COMMIT caused by a Conditional Branch.
assign bht_update_en = (flush | commit_en) & commit_cont_tra_inst[0];


`ifdef BHT_1BIT
	BHT_1bit
	#( .PCSIZE (BRANCHTABLEPCSIZE))
	uBHT_1bit
	(
	   .clk              (clk), 
	   .rstn             (rstn),
	   // UPDATE 
	   .i_update_en      (bht_update_en),
	   .i_update_pc      (commit_inst_pc[(BRANCHTABLEPCSIZE+1):2]), 
	   .i_update_taken   (commit_value[0]), 
	   // READ 
	   .i_read_pc        (pc[(BRANCHTABLEPCSIZE+1):2]),
	   .o_read_taken     (bht_taken)
    );
`elsif BHT_2BIT
	BHT_2bit
	#( .PCSIZE (BRANCHTABLEPCSIZE))
	uBHT_2bit
	(
	   .clk              (clk), 
	   .rstn             (rstn),
	   // UPDATE 
	   .i_update_en      (bht_update_en),
	   .i_update_pc      (commit_inst_pc[(BRANCHTABLEPCSIZE+1):2]), 
	   .i_update_taken   (commit_value[0]), 
	   // READ 
	   .i_read_pc        (pc[(BRANCHTABLEPCSIZE+1):2]),
	   .o_bht_2bit       (bht_taken)
    );
`elsif BHT_1BITHIS_2BITCNT 
	BHT_1bithis_2bitcnt
	#( .PCSIZE (BRANCHTABLEPCSIZE))
	uBHT_1bithis_2bitcnt
	(
	   .clk              (clk), 
	   .rstn             (rstn),
	   // UPDATE 
	   .i_update_en      (bht_update_en),
	   .i_update_pc      (commit_inst_pc[(BRANCHTABLEPCSIZE+1):2]), 
	   .i_update_taken   (commit_value[0]), 
	   // READ 
	   .i_read_pc               (pc[(BRANCHTABLEPCSIZE+1):2]),
	   .o_bht_1bithis_2bitcnt   (bht_taken)
    );
`elsif BHT_PSHARED 
	BHT_pshared
	#( .PCSIZE (BRANCHTABLEPCSIZE),
	   .HISTORYSIZE (PHISTORYSIZE))
	uBHT_pshared
	(
	   .clk              (clk), 
	   .rstn             (rstn),
	   // UPDATE 
	   .i_update_en      (bht_update_en),
	   .i_update_pc      (commit_inst_pc[(BRANCHTABLEPCSIZE+1):2]), 
	   .i_update_taken   (commit_value[0]), 
	   // READ 
	   .i_read_pc        (pc[(BRANCHTABLEPCSIZE+1):2]),
	   .o_bht_pshared    (bht_taken)
    );
`elsif BHT_GSHARED 
	BHT_gshared
	#( .PCSIZE (BRANCHTABLEPCSIZE),
	   .HISTORYSIZE (GHISTORYSIZE))
	uBHT_gshared
	(
	   .clk              (clk), 
	   .rstn             (rstn),
	   // UPDATE 
	   .i_update_en      (bht_update_en),
	   .i_update_pc      (commit_inst_pc[(BRANCHTABLEPCSIZE+1):2]), 
	   .i_update_taken   (commit_value[0]), 
	   // READ 
	   .i_read_pc        (pc[(BRANCHTABLEPCSIZE+1):2]),
	   .o_bht_gshared    (bht_taken)
    );
`endif 





// CONTROL TRANSFET INSTRUCTION TAKEN-NOTTAKEN PREDICTION 
assign taken_prediction = bht_taken | jal_inst;

//===============================
//  PROGRAM MEMORY 
//===============================
PROGRAM_MEM
#( .MEMSIZE (PROGMEMSIZE) )
uPROGRAM_MEM
(
   .clk    (clk), 
   .rstn   (rstn), 
   .i_addr (pc[(PROGMEMSIZE+1):2]),
   .o_inst (progmem_out)
    );

assign iq_wrt_inst = progmem_out;

//===============================
//  PRE-DECODE & TARGET ADDRESS CALCULATION 
//===============================

assign branch_inst = progmem_out[6] & progmem_out[5] & ~progmem_out[4] & ~progmem_out[3] & ~progmem_out[2];
assign jal_inst    = progmem_out[6] & progmem_out[5] & ~progmem_out[4] & progmem_out[3] & progmem_out[2];


assign b_type_imm = { {19{progmem_out[31]}}, progmem_out[31], progmem_out[7]    , progmem_out[30:25], progmem_out[11:8] , 1'b0 };
assign j_type_imm = { {11{progmem_out[31]}}, progmem_out[31], progmem_out[19:12], progmem_out[20]   , progmem_out[30:21], 1'b0 };   

assign branch_target = b_type_imm + pc_reg;
assign jal_target    = j_type_imm + pc_reg; 

assign pc_target = branch_inst ? branch_target : jal_target;




//===============================
//  CORE CONTROL 
//===============================
Core_Control_Unit #(.ROBSIZE (ROBSIZE)) uCore_Control_Unit(
 .start                     (start),
 .clk                       (clk), 
 .rstn                      (rstn),
 // CONTROL SIGNALS 
 .rd_inst                   (rd_inst),
 .i_illegal_inst            (illegal_inst),
 .i_cont_tra_inst           (|cont_tra_inst),
 .i_load_store              (load_store),
 .i_alu_opcode              (alu_opcode),
 .o_pc_stall                (pc_stall),
 // INSTRUCTION QUEUE SIGNALS 
 .i_iq_empty                (iq_empty),
 .i_iq_full                 (iq_full),
 .o_iq_rd_en                (iq_rd_en), 
 .o_iq_wrt_en               (iq_wrt_en),
 // RESERVATION STATION SIGNALS 
 .i_rs1_full                (rs1_full),
 .i_rs2_full                (rs2_full), 
 .o_rs1_we                  (rs1_issue_we),
 .o_rs2_we                  (rs2_issue_we),
 .o_adder1rs_we             (adder1rs_issue_we),
 // ROB SIGNALS 
 .i_rob_full                (rob_full),
 .o_rob_we                  (rob_we),
 // RAT SIGNALS 
 .o_rat_issue_we            (rat_issue_we), 
 // ALU_CONTROL1 SIGNALS
 .i_alu1_broadcast_ready           (alu1_broadcast_ready),
 .i_alu1_broadcast_data            (alu1_broadcast_data),
 .i_alu1_broadcast_rob_addr        (alu1_broadcast_rob_addr),
 .i_alu1_broadcast_addr_cal        (alu1_broadcast_addr_cal),
 .i_alu1_broadcast_con_branch_comp (alu1_broadcast_con_branch_comp),
 .o_alu1_broadcast_en              (alu1_broadcast_en),
 // ALU_CONTROL2 SIGNALS
 .i_alu2_broadcast_ready           (alu2_broadcast_ready),
 .i_alu2_broadcast_data            (alu2_broadcast_data), 
 .i_alu2_broadcast_rob_addr        (alu2_broadcast_rob_addr),
 .i_alu2_broadcast_addr_cal        (alu2_broadcast_addr_cal),
 .i_alu2_broadcast_con_branch_comp (alu2_broadcast_con_branch_comp), 
 .o_alu2_broadcast_en              (alu2_broadcast_en),
 //DATA MEMORY BROADCAST SIGNALS 
 .o_mem_broadcast_en          (mem_broadcast_en),       // Broadcast Enable 
 .i_mem_broadcast_ready       (mem_broadcast_ready),    // Broadcast Data Ready 
 .i_mem_broadcast_rob_addr    (mem_broadcast_rob_addr),// Broadcast ROB Addr 
 .i_mem_broadcast_load_data   (mem_broadcast_load_data),// Broadcast Data 
 // BROADCAST BUS SIGNALS 
 .o_broadcast_en              (broadcast_en),
 .o_broadcast_data            (broadcast_data),
 .o_broadcast_rob_addr        (broadcast_rob_addr),
 .o_broadcast_addr_cal        (broadcast_addr_cal),
 .o_broadcast_con_branch_comp (broadcast_con_branch_comp),
   // COMMIT SIGNALS 
 .i_commit_ready            (rob_commit_ready),
 .i_commit_rob_addr         (rob_commit_rob_addr),
 .i_commit_inst_pc          (rob_commit_inst_pc),
 .i_commit_value            (rob_commit_value),
 .i_commit_rd               (rob_commit_rd),
 .i_commit_exception        (rob_commit_exception),
 .i_commit_load_store       (rob_commit_load_store),
 .i_commit_rd_inst          (rob_commit_rd_inst), 
 .i_commit_cont_tra_inst    (rob_commit_cont_tra_inst),
 .o_commit                  (commit_en),
 .o_commit_rob_addr         (commit_rob_addr),
 .o_commit_inst_pc          (commit_inst_pc),
 .o_commit_value            (commit_value),
 .o_commit_rd               (commit_rd),
 .o_commit_exception        (commit_exception),
 .o_commit_rd_inst          (commit_rd_inst),
 .o_commit_cont_tra_inst    (commit_cont_tra_inst),
 .o_commit_load_store       (commit_load_store),
 // FLUSH
 .o_flush                   (flush),
 .o_flush_pc                (flush_pc),
 .o_flush_taken             (flush_taken),  
   // COMMIT SIGNALS 
  .o_lsq_commit_en          (lsq_commit_en),
  .i_lsq_commit_ready       (lsq_commit_ready),
  .i_lsq_commit_load_store  (lsq_commit_load_store),
  .i_lsq_commit_data        (lsq_commit_data), 
  .i_lsq_commit_rob_addr    (lsq_commit_rob_addr),
  .i_mem_busy               (data_mem_busy),
 // REGISTER FILE WRITE SIGNALS 
 .o_rf_we                   (rf_we),
 .o_rf_wrd                  (rf_rd),
 .o_rf_rd_wvalue            (rf_rd_value),
 // LOAD/STORE QUEUE SIGNALS
 .i_lsq_full                (lsq_full),
 .o_lsq_new_inst_we         (lsq_new_inst_we)
    );

//===============================
//  INSTRUCTION QUEUE 
//===============================
 INSTRUCTION_QUEUE 
 #(.DATAWITHBIT (DATAWITHBIT), .FIFOSIZE (FIFOSIZE))
 uINSTRUCTION_QUEUE 
 ( 
   .clk           (clk), 
   .rstn          (rstn), 
   .i_flush       (flush), 
   .i_wrt_en      (iq_wrt_en), 
   .i_wrt_data    (iq_wrt_inst), 
   .i_wrt_inst_pc (pc_reg),
   .i_wrt_taken   (branch_taken_decision),   
   .i_rd_en       (iq_rd_en), 
   .o_rd_data     (inst), 
   .o_rd_inst_pc  (inst_pc),
   .o_rd_taken    (branch_inst_taken),
   .o_full        (iq_full), 
   .o_empty       (iq_empty) 
   );
   
//===============================   
//===============================
//  DECODE STAGE   
//===============================
//===============================

assign opcode = inst[6:0];
assign rd     = inst[11:7];
assign funct3 = inst[14:12];
assign rs1    = inst[19:15];
assign rs2    = inst[24:20];
assign funct7 = inst[31:25];

//===============================
//  DECODER 
//===============================
DECODER  uDECODER(
    .OPCODE               (opcode),
    .FUNCT7_5             (funct7[5]),
    .FUNCT7               (funct7),
    .FUNCT3               (funct3),
    .IADDER_OUT_1_TO_0    (1'b0),
    .TRAP_TAKEN           (1'b0),
     //
    .ALU_OPCODE           (alu_opcode),
    .M_INST               (m_inst),
    .MEM_WR_REQ           (  ),
    .LOAD_SIZE            (load_size),
    .LOAD_UNSIGNED        (load_unsigned),
    .LOAD_STORE           (load_store),
    .ALU_SRC              (  ),
    .IADDER_SRC           (  ),
    .CSR_WR_EN            (  ),
    .RD_INST              (rd_inst),
    .WB_MUX_SEL           (  ),
    .IMM_TYPE             (imm_type),
    .CSR_OP               (  ),
    .ILLEGAL_INSTR        (illegal_inst),
    .MISALIGNED_LOAD      (  ),
    .MISALIGNED_STORE     (  ),
    .CONT_TRA_INST        (cont_tra_inst)
    );

assign imm_inst = |imm_type; 

//===============================
//  IMMEDIATE GENERATION 
//===============================
IMM_GEN uIMM_GEN(
   .i_inst     (inst), 
   .i_imm_type (imm_type),
   .o_imm      (imm)
    );


//===============================
//  REGISTER FILE (RF)
//===============================
REGISTER_FILE uREGISTER_FILE(
  .clk             (clk),
  .i_we            (rf_we),
  .i_rd            (rf_rd),
  .i_rd_Value      (rf_rd_value),
  //
  .i_rs1           (rs1),
  .i_rs2           (rs2),
  .o_rs1_RF_Value  (rs1_rf_value),
  .o_rs2_RF_Value  (rs2_rf_value)
    );
    
    
//===============================
//  REGISTER ALLIASING TABLE (RAT) 
//===============================
RAT
#( .ROBSIZE (ROBSIZE))
uRAT
(
    .clk                (clk),
    .rstn               (rstn),
    .i_flush            (flush),
    // RAT ISSUE WRITE SIGNALS 
    .i_we               (rat_issue_we),
    .i_rd               (rd),
    .i_rob_addr         (rob_issue_ptr),
    .i_rob_or_rf        (1'b1),
    // RAT READ RS1 & RS2 values 
    .i_rs1              (rs1),
    .i_rs2              (rs2),
    .o_rs1_rob_addr     (rat_rs1_rob_addr),
    .o_rs2_rob_addr     (rat_rs2_rob_addr),
    .o_rs1_rob_or_rf    (rat_rs1_rob_or_rf),
    .o_rs2_rob_or_rf    (rat_rs2_rob_or_rf),
    // COMMIT SIGNALS 
    .i_commit_en        (commit_en),
    .i_commit_rd        (commit_rd),
    .i_commit_rob_addr  (commit_rob_addr) 
    );
       
//===============================
//  RE-ORDER BUFFER (ROB)
//===============================
ROB
#( .ROBSIZE (ROBSIZE))
uROB
(
     .clk                      (clk),
     .rstn                     (rstn),
     .i_flush                  (flush),
     // Write NEW OP to ROB
     .i_issue_we               (rob_we),
     .i_issue_inst_pc          (inst_pc),
     .i_issue_taken            (branch_inst_taken),
     .i_issue_rd               (rd),
     .i_issue_load_store       (load_store),
     .i_issue_rd_inst          (rd_inst),
     .i_issue_cont_tra_inst    (cont_tra_inst),     
     .o_issue_ptr              (rob_issue_ptr),
     // READ RS1 RS2 ROB VALUES 
     .i_rs1_ROB_Addr           (rat_rs1_rob_addr),
     .i_rs2_ROB_Addr           (rat_rs2_rob_addr),
     .o_ROB_rs1_Value          (rob_rs1_value),
     .o_ROB_rs2_Value          (rob_rs2_value),
     .o_ROB_rs1_Valid          (rob_rs1_valid),
     .o_ROB_rs2_Valid          (rob_rs2_valid),
     // BROADCAST SIGNALS 
     .i_broadcast              (broadcast_en),
     .i_broadcast_rob_addr     (broadcast_rob_addr),
     .i_broadcast_data         (broadcast_data),
     // COMMIT SIGNALS 
     .o_commit_ready           (rob_commit_ready),
     .o_commit_rob_addr        (rob_commit_rob_addr),
     .o_commit_inst_pc         (rob_commit_inst_pc),
     .o_commit_value           (rob_commit_value),
     .o_commit_rd              (rob_commit_rd),
     .o_commit_exception       (rob_commit_exception),
     .o_commit_load_store      (rob_commit_load_store),
     .o_commit_rd_inst         (rob_commit_rd_inst),
     .o_commit_cont_tra_inst   (rob_commit_cont_tra_inst),
     .i_commit                 (commit_en),
     // ROB FULL FLAG 
     .o_rob_full               (rob_full)
    );

//===============================
//  SELECT RS1 & RS2 VALUES 
//===============================
// Conditional Branch instructions have imm value but ALU compares RS1 and RS2 Values.  
assign rs_rs1_value = rat_rs1_rob_or_rf ? rob_rs1_value : rs1_rf_value; 
assign rs_rs2_value = (imm_inst & ~alu_opcode[4]) ? imm : (rat_rs2_rob_or_rf ? rob_rs2_value : rs2_rf_value); 

assign rs_rs1_valid = ~rat_rs1_rob_or_rf | (rat_rs1_rob_or_rf & rob_rs1_valid); 
assign rs_rs2_valid = (imm_inst & ~alu_opcode[4]) | (~rat_rs2_rob_or_rf | (rat_rs2_rob_or_rf & rob_rs2_valid)); 

//===============================
//  RESERVATION STATION 1
//===============================
RESERVATION_STATION
#( .RSSIZE (RSSIZE),.ROBSIZE (ROBSIZE))
uRESERVATION_STATION1
(
  .clk                  (clk),
  .rstn                 (rstn),
  .i_flush              (flush),
  //
  .i_issue_we           (rs1_issue_we),
  .i_rob_addr           (rob_issue_ptr),
  .i_alu_opcode         (alu_opcode),
  .i_rs1_value          (rs_rs1_value),
  .i_rs2_value          (rs_rs2_value),
  .i_rs1_valid          (rs_rs1_valid), 
  .i_rs2_valid          (rs_rs2_valid), 
  .i_rs1_rob_addr       (rat_rs1_rob_addr),
  .i_rs2_rob_addr       (rat_rs2_rob_addr),
  .i_addr_cal           (|load_store),
  .i_con_branch_comp    (cont_tra_inst[0]),
  //      
  .i_broadcast          (broadcast_en),
  .i_broadcast_rob_addr (broadcast_rob_addr),
  .i_broadcast_data     (broadcast_data),
  //
  .i_alu_busy           (alu1_busy),
  .o_alu_opcode         (alu1_opcode),
  .o_rs1_value          (alu1_rs1_value),
  .o_rs2_value          (alu1_rs2_value), 
  .o_rat_rs1_rob_addr   (alu1_rob_addr), 
  .o_alu_ex_en          (alu1_ex_en),
  .o_addr_cal           (alu1_addr_cal),
  .o_con_branch_comp    (alu1_con_branch_comp),
  //
  .o_rs_full            (rs1_full)
  );

//===============================
//  ALU CONTROL 1 
//===============================
ALU_I_CONTROL_UNIT 
#( .ROBSIZE (ROBSIZE))
uALU_I_CONTROL_UNIT1(
    .clk                  (clk), 
    .rstn                 (rstn),
    //
    .i_flush              (flush),
    //
    .o_busy               (alu1_busy),
    .i_rob_addr           (alu1_rob_addr),
    .i_con_branch_comp    (alu1_con_branch_comp),
    .i_addr_cal           (alu1_addr_cal),
    .i_rs1_value          (alu1_rs1_value),
    .i_rs2_value          (alu1_rs2_value),
    .i_alu_opcode         (alu1_opcode),
    .i_ex_en              (alu1_ex_en),   
    //
    .i_broadcast_en       (alu1_broadcast_en),
    .o_broadcast_ready    (alu1_broadcast_ready), 
    .o_broadcast_out      (alu1_broadcast_data),
    .o_broadcast_rob_addr (alu1_broadcast_rob_addr),
    .o_broadcast_addr_cal (alu1_broadcast_addr_cal),
    .o_broadcast_con_branch_comp (alu1_broadcast_con_branch_comp)
    );


//===============================
//  RESERVATION STATION 2
//===============================
RESERVATION_STATION
#( .RSSIZE (RSSIZE),.ROBSIZE (ROBSIZE))
uRESERVATION_STATION2
(
  .clk                  (clk),
  .rstn                 (rstn),
  .i_flush              (flush),
  //
  .i_issue_we           (rs2_issue_we),
  .i_rob_addr           (rob_issue_ptr),
  .i_alu_opcode         (alu_opcode),
  .i_rs1_value          (rs_rs1_value),
  .i_rs2_value          (rs_rs2_value),
  .i_rs1_valid          (rs_rs1_valid), 
  .i_rs2_valid          (rs_rs2_valid), 
  .i_rs1_rob_addr       (rat_rs1_rob_addr),
  .i_rs2_rob_addr       (rat_rs2_rob_addr),
  .i_addr_cal           (|load_store),
  .i_con_branch_comp    (cont_tra_inst[0]),
  //      
  .i_broadcast          (broadcast_en),
  .i_broadcast_rob_addr (broadcast_rob_addr),
  .i_broadcast_data     (broadcast_data),
  //
  .i_alu_busy           (alu2_busy),
  .o_alu_opcode         (alu2_opcode),
  .o_rs1_value          (alu2_rs1_value),
  .o_rs2_value          (alu2_rs2_value), 
  .o_rat_rs1_rob_addr   (alu2_rob_addr), 
  .o_alu_ex_en          (alu2_ex_en),
  .o_addr_cal           (alu2_addr_cal),
  .o_con_branch_comp    (alu2_con_branch_comp),
  //
  .o_rs_full            (rs2_full)
  );

//===============================
//  ALU CONTROL 2
//===============================
ALU_I_CONTROL_UNIT 
#( .ROBSIZE (ROBSIZE))
uALU_I_CONTROL_UNIT2(
    .clk                  (clk), 
    .rstn                 (rstn),
    .i_flush              (flush),
    .o_busy               (alu2_busy),
    .i_rob_addr           (alu2_rob_addr),
    .i_con_branch_comp    (alu2_con_branch_comp),
    .i_addr_cal           (alu2_addr_cal),
    .i_rs1_value          (alu2_rs1_value),
    .i_rs2_value          (alu2_rs2_value),
    .i_alu_opcode         (alu2_opcode),
    .i_ex_en              (alu2_ex_en),   
    //
    .i_broadcast_en             (alu2_broadcast_en),
    .o_broadcast_ready          (alu2_broadcast_ready), 
    .o_broadcast_out            (alu2_broadcast_data),
    .o_broadcast_rob_addr       (alu2_broadcast_rob_addr),
    .o_broadcast_addr_cal       (alu2_broadcast_addr_cal),
    .o_broadcast_con_branch_comp (alu2_broadcast_con_branch_comp)
    );

//======================================================
// JUMP ADDRESS CALCULATION 
//======================================================
/*
assign adder1rs_rs1_value = cont_tra_inst[1] ? rs_rs1_value : inst_pc;
assign adder1rs_rs1_valid = cont_tra_inst[1] ? rs_rs1_valid : 1'b1;
assign adder1rs_rs2_value = imm;


RESERVATION_STATION
#( .RSSIZE (RSSIZE),.ROBSIZE (ROBSIZE))
uADDER1_RS
(
  .clk                  (clk),
  .rstn                 (rstn),
  .i_flush              (flush),
  //
  .i_issue_we           (adder1rs_issue_we),
  .i_rob_addr           (rob_issue_ptr),
  .i_alu_opcode         ('0),   // Always Addition 
  .i_rs1_value          (adder1rs_rs1_value),
  .i_rs2_value          (adder1rs_rs2_value),
  .i_rs1_valid          (adder1rs_rs1_valid), 
  .i_rs2_valid          (1'b1), 
  .i_rs1_rob_addr       (rat_rs1_rob_addr),
  .i_rs2_rob_addr       ('0),
  .i_addr_cal           ('0), // Always PC address Calculation
  //      
  .i_broadcast          (broadcast_en),
  .i_broadcast_rob_addr (broadcast_rob_addr),
  .i_broadcast_data     (broadcast_data),
  //
  .i_alu_busy           (adder1_busy),
  .o_alu_opcode         (adder1_opcode), 
  .o_rs1_value          (adder1_rs1_value),
  .o_rs2_value          (adder1_rs2_value), 
  .o_rat_rs1_rob_addr   (adder1_rob_addr), 
  .o_alu_ex_en          (adder1_ex_en),
  .o_addr_cal           (alu1_addr_cal),
  //
  .o_rs_full            (adder1rs_full)
  );


ALU_I_CONTROL_UNIT 
#( .ROBSIZE (ROBSIZE))
uADDER1(
    .clk                  (clk), 
    .rstn                 (rstn),
    .i_flush              (flush),
    .o_busy               (adder1_busy),
    .i_rob_addr           (adder1_rob_addr),
    .i_addr_cal           (1'b0),
    .i_rs1_value          (adder1_rs1_value),
    .i_rs2_value          (adder1_rs2_value),
    .i_alu_opcode         (adder1_opcode),
    .i_ex_en              (adder1_ex_en),   
    //
    .i_broadcast_en       (adder1_broadcast_en),
    .o_broadcast_ready    (adder1_broadcast_ready), 
    .o_broadcast_out      (adder1_broadcast_data),
    .o_broadcast_rob_addr (adder1_broadcast_rob_addr),
    .o_broadcast_addr_cal (adder1_broadcast_addr_cal)
    );
*/





assign lsq_rs2_data       = rat_rs2_rob_or_rf ? rob_rs2_value : rs2_rf_value;
assign lsq_rs2_rob_addr   = rat_rs2_rob_addr;
assign lsq_rs2_data_valid = (~rat_rs2_rob_or_rf | (rat_rs2_rob_or_rf & rob_rs2_valid));
assign lsq_load_or_store  = load_store[0]; 



//===============================
//  LOAD STORE QUEUE 
//===============================
LOAD_STORE_QUEUE
#(.QUEUESIZE  (LSQSIZE), .ROBSIZE   (ROBSIZE))
uLOAD_STORE_QUEUE
(
    .clk                      (clk),
    .rstn                     (rstn),
    //
    .i_flush                  (flush),
    // NEW INSTRUCTION WRITE SIGNALS 
    .i_new_inst_we            (lsq_new_inst_we),
    .i_rob_addr               (rob_issue_ptr),
    .i_rs2_data               (lsq_rs2_data),
    .i_rs2_rob_addr           (lsq_rs2_rob_addr),
    .i_rs2_data_valid         (lsq_rs2_data_valid),
    .i_load_or_store          (lsq_load_or_store),
    .i_signed_unsigned        (load_unsigned),
    .i_size                   (load_size),
    // BROADCAST BUS CONNECTION
    .i_broadcast_en           (broadcast_en),
    .i_broadcast_data         (broadcast_data),
    .i_broadcast_rob_addr     (broadcast_rob_addr),
    .i_broadcast_addr_flag    (broadcast_addr_cal),
    // COMMIT SIGNALS 
    .i_commit_en              (lsq_commit_en),
    .o_commit_ready           (lsq_commit_ready),
    .o_commit_load_store      (lsq_commit_load_store),
    .o_commit_data            (lsq_commit_data),
    .o_commit_rob_addr        (lsq_commit_rob_addr),    
     //DATA MEMORY SIGNALS 
     //TO MEMORY
    .o_mem_cs                 (data_mem_cs),
    .o_mem_addr               (data_mem_addr),
    .o_mem_rob_addr           (data_mem_rob_addr),
    .o_mem_load_store         (data_mem_load_store),
    .o_mem_store_data         (data_mem_store_data),
    .o_mem_size               (data_mem_size),
    .o_mem_signed_unsigned    (data_mem_signed_unsigned),
    // FROM MEMORY
    .i_load_we                (1'b0),
    .i_mem_busy               (data_mem_busy),
    .i_load_rob_addr          (  ), 
    .i_load_data              (  ),
    // 
    .o_full                   (lsq_full),
    .o_empty                  (lsq_empty)   
    );

/*
DATA_MEM_CONTROL
#(.ROBSIZE (ROBSIZE))
uDATA_MEM_CONTROL
(
   .clk                    (clk),                     // Clock 
   .rstn                   (rstn),                    // Active-Low Reset  
   .i_cs                   (data_mem_cs),             // CHIP SELECT
   .i_addr                 (data_mem_addr),           // Memory Address 
   .i_rob_addr             (data_mem_rob_addr),       // ROB Addr
   .i_load_store           (data_mem_load_store),     // LOAD OR STORE COMMAND 
   .i_store_data           (data_mem_store_data),     // Store Data 
   .i_size                 (data_mem_size),           // Data Size-Byte|Half-Word|Word
   .i_signed_unsigned      (data_mem_signed_unsigned),// Signed|Unsigned 
   // 
   .i_broadcast_en         (mem_broadcast_en),       // Broadcast Enable 
   .o_broadcast_ready      (mem_broadcast_ready),    // Broadcast Data Ready 
   .o_broadcast_rob_addr   (mem_broadcast_rob_addr), // Broadcast ROB Addr 
   .o_broadcast_load_data  (mem_broadcast_load_data),// Broadcast Data 
   //
   .o_mem_busy             (data_mem_busy)//Memory Busy Flag 
);
*/


DCACHE_CONTROLLER_v2
#(.ROBSIZE       (ROBSIZE),  // Re-Order Buffer Size  
  .BLOCKSIZE     (64),       // Number of Blocks in External Memory  
  .BLOCKWORDSIZE (4),        // Number of Words(32-bit) in each MemoryBlock/CacheLine 
  .CACHESETSIZE  (4),        // Number of Sets in Cache  
  .CACHEWAYSIZE  (4))        // Number of Lines in Each Cache Set
DCACHE_CONTROLLER_v2
(
   .clk                    (clk),                     // Clock 
   .rstn                   (rstn),                    // Active-Low Reset  
   .i_cs                   (data_mem_cs),             // CHIP SELECT
   .i_addr                 (data_mem_addr),           // Memory Address 
   .i_rob_addr             (data_mem_rob_addr),       // ROB Addr
   .i_load_store           (data_mem_load_store),     // LOAD OR STORE COMMAND 
   .i_store_data           (data_mem_store_data),     // Store Data 
   .i_size                 (data_mem_size),           // Data Size-Byte|Half-Word|Word
   .i_signed_unsigned      (data_mem_signed_unsigned),// Signed|Unsigned 
   // 
   .i_broadcast_en         (mem_broadcast_en),       // Broadcast Enable 
   .o_broadcast_ready      (mem_broadcast_ready),    // Broadcast Data Ready 
   .o_broadcast_rob_addr   (mem_broadcast_rob_addr), // Broadcast ROB Addr 
   .o_broadcast_load_data  (mem_broadcast_load_data),// Broadcast Data 
   //
   .o_mem_busy             (data_mem_busy)//Memory Busy Flag 
    );




endmodule :CORE  





///////////////////////////////////
// CORE TEST BENCH 
///////////////////////////////////
module CORE_tb();

parameter DATAWITHBIT=32;
parameter FIFOSIZE=32;
parameter ROBSIZE=16;
parameter LSQSIZE = 16;
// INSTRUCTION QUEUE SIGNALS 
logic                      clk;
logic                      rstn;
logic [31:0]               ROM_ADDR;
logic start;
// TB SIGNALS 



////////////////
// Clock Generation 
///////////////
initial begin
   clk = 1'b0;
   forever #10 clk = ~clk; 
end 

////////////////
// RESET Task 
///////////////
task RESET();
begin
   start = '0;
   // Asyncronous Active Low Reset 
   rstn = 1'b1;
   repeat(2) @(posedge clk);
   rstn = 1'b0;
   repeat(2) @(posedge clk);
   rstn = 1'b1; 
   repeat(2) @(posedge clk);   
end 
endtask 

//==================
// Instruction Functions 
//==================

//==================
// ADD Instruction 
//==================
task ADD(
  input logic [4:0] rd,
  input logic [4:0] rs1, 
  input logic [4:0] rs2 
);
begin
  localparam [6:0] opcode = 7'b0110011;
  localparam [2:0] funct3 = 3'b000;
  localparam [6:0] funct7 = 7'b0000000;
  $display("ADD %d, %d, %d ",rd,rs1,rs2);
  WRITE({funct7,rs2,rs1,funct3,rd,opcode});
end   
endtask

//=========
// ADDI Instruction 
//=========
task ADDI(
  input logic [4:0]  rd,
  input logic [4:0]  rs1, 
  input logic [11:0] imm 
);
begin
  localparam [6:0] opcode = 7'b0010011;
  localparam [2:0] funct3 = 3'b000;
  $display("ADDI %d, %d, %d ",rd,rs1,imm);
  WRITE({imm,rs1,funct3,rd,opcode});
end   
endtask


//=========
// LOAD LB INSTRUCTION 
//=========
task LB(
  input logic [4:0]  rd,
  input logic [4:0]  rs1,
  input logic [11:0] imm 
);
begin
  localparam [6:0] opcode = 7'b0000011;
  localparam [2:0] funct3 = 3'b000;
  WRITE({imm,rs1,funct3,rd,opcode});
  $display("LB rd:%d, rs1:%d, imm:%d ",rd,rs1,imm);
end   
endtask


//=========
// LOAD LH INSTRUCTION 
//=========
task LH(
  input logic [4:0]  rd,
  input logic [4:0]  rs1,
  input logic [11:0] imm 
);
begin
  localparam [6:0] opcode = 7'b0000011;
  localparam [2:0] funct3 = 3'b001;
  WRITE({imm,rs1,funct3,rd,opcode});
  $display("LH rd:%d, rs1:%d, imm:%d ",rd,rs1,imm);
end   
endtask

//=========
// LOAD LW INSTRUCTION 
//=========
task LW(
  input logic [4:0]  rd,
  input logic [4:0]  rs1,
  input logic [11:0] imm 
);
begin
  localparam [6:0] opcode = 7'b0000011;
  localparam [2:0] funct3 = 3'b010;
  WRITE({imm,rs1,funct3,rd,opcode});
  $display("LW rd:%d, rs1:%d, imm:%d ",rd,rs1,imm);
end   
endtask

//=========
// LOAD LBU INSTRUCTION 
//=========
task LBU(
  input logic [4:0]  rd,
  input logic [4:0]  rs1,
  input logic [11:0] imm 
);
begin
  localparam [6:0] opcode = 7'b0000011;
  localparam [2:0] funct3 = 3'b100;
  WRITE({imm,rs1,funct3,rd,opcode});
  $display("LBU rd:%d, rs1:%d, imm:%d ",rd,rs1,imm);
end   
endtask

//=========
// LOAD LHU INSTRUCTION 
//=========
task LHU(
  input logic [4:0]  rd,
  input logic [4:0]  rs1,
  input logic [11:0] imm 
);
begin
  localparam [6:0] opcode = 7'b0000011;
  localparam [2:0] funct3 = 3'b101;
  WRITE({imm,rs1,funct3,rd,opcode});
  $display("LHU rd:%d, rs1:%d, imm:%d ",rd,rs1,imm);
end   
endtask

//=========
// LOAD SB INSTRUCTION 
//=========
// imm[11:5] rs2 rs1 000 imm[4:0] 0100011 SB
// imm[11:5] rs2 rs1 001 imm[4:0] 0100011 SH
// imm[11:5] rs2 rs1 010 imm[4:0] 0100011 SW
task SB(
  input logic [4:0]  rs1,
  input logic [4:0]  rs2,
  input logic [11:0] imm 
);
begin
  localparam [6:0] opcode = 7'b0100011;
  localparam [2:0] funct3 = 3'b000;
  WRITE ({imm[11:5],rs2,rs1,funct3,imm[4:0],opcode});
  $display("SB rs1:%d, rs2:%d, imm:%d ",rs1,rs2,imm);
end   
endtask

//=========
// LOAD SH INSTRUCTION 
//=========
// imm[11:5] rs2 rs1 000 imm[4:0] 0100011 SB
// imm[11:5] rs2 rs1 001 imm[4:0] 0100011 SH
// imm[11:5] rs2 rs1 010 imm[4:0] 0100011 SW
task SH(
  input logic [4:0]  rs1,
  input logic [4:0]  rs2,
  input logic [11:0] imm 
);
begin
  localparam [6:0] opcode = 7'b0100011;
  localparam [2:0] funct3 = 3'b001;
  WRITE ({imm[11:5],rs2,rs1,funct3,imm[4:0],opcode});
  $display("SH rs1:%d, rs2:%d, imm:%d ",rs1,rs2,imm);
end   
endtask

//=========
// LOAD SH INSTRUCTION 
//=========
// imm[11:5] rs2 rs1 000 imm[4:0] 0100011 SB
// imm[11:5] rs2 rs1 001 imm[4:0] 0100011 SH
// imm[11:5] rs2 rs1 010 imm[4:0] 0100011 SW
task SW(
  input logic [4:0]  rs1,
  input logic [4:0]  rs2,
  input logic [11:0] imm 
);
begin
  localparam [6:0] opcode = 7'b0100011;
  localparam [2:0] funct3 = 3'b010;
  WRITE ({imm[11:5],rs2,rs1,funct3,imm[4:0],opcode});
  $display("SW rs1:%d, rs2:%d, imm:%d ",rs1,rs2,imm);
end   
endtask


//=========
// BEQ INSTRUCTION 
//=========
task BEQ(
   input logic [4:0]  rs1, 
   input logic [4:0]  rs2,
   input logic [12:0] imm  
);
begin
  localparam [6:0] opcode = 7'b1100011;
  localparam [2:0] funct3 = 3'b000;
  WRITE ({imm[12],imm[10:5],rs2,rs1,funct3,imm[4:1],imm[11],opcode});
  $display("BEQ rs1:%d, rs2:%d, imm:%d",rs1,rs2,imm);   
end 
endtask 

//=========
// BNE INSTRUCTION 
//=========
task BNE(
   input logic [4:0]  rs1, 
   input logic [4:0]  rs2,
   input logic [12:0] imm  
);
begin
  localparam [6:0] opcode = 7'b1100011;
  localparam [2:0] funct3 = 3'b001;
  WRITE ({imm[12],imm[10:5],rs2,rs1,funct3,imm[4:1],imm[11],opcode});
  $display("BNE rs1:%d, rs2:%d, imm:%d",rs1,rs2,imm);   
end 
endtask 

//=========
// BLT INSTRUCTION 
//=========
task BLT(
   input logic [4:0]  rs1, 
   input logic [4:0]  rs2,
   input logic [12:0] imm  
);
begin
  localparam [6:0] opcode = 7'b1100011;
  localparam [2:0] funct3 = 3'b100;
  WRITE ({imm[12],imm[10:5],rs2,rs1,funct3,imm[4:1],imm[11],opcode});
  $display("BLT rs1:%d, rs2:%d, imm:%d",rs1,rs2,imm);   
end 
endtask 

//=========
// BLT INSTRUCTION 
//=========
task BGE(
   input logic [4:0]  rs1, 
   input logic [4:0]  rs2,
   input logic [12:0] imm  
);
begin
  localparam [6:0] opcode = 7'b1100011;
  localparam [2:0] funct3 = 3'b101;
  WRITE ({imm[12],imm[10:5],rs2,rs1,funct3,imm[4:1],imm[11],opcode});
  $display("BGE rs1:%d, rs2:%d, imm:%d",rs1,rs2,imm);   
end 
endtask 

//=========
// BLTU INSTRUCTION 
//=========
task BLTU(
   input logic [4:0]  rs1, 
   input logic [4:0]  rs2,
   input logic [12:0] imm  
);
begin
  localparam [6:0] opcode = 7'b1100011;
  localparam [2:0] funct3 = 3'b110;
  WRITE ({imm[12],imm[10:5],rs2,rs1,funct3,imm[4:1],imm[11],opcode});
  $display("BLTU rs1:%d, rs2:%d, imm:%d",rs1,rs2,imm);   
end 
endtask 

//=========
// BGEU INSTRUCTION 
//=========
task BGEU(
   input logic [4:0]  rs1, 
   input logic [4:0]  rs2,
   input logic [12:0] imm  
);
begin
  localparam [6:0] opcode = 7'b1100011;
  localparam [2:0] funct3 = 3'b111;
  WRITE ({imm[12],imm[10:5],rs2,rs1,funct3,imm[4:1],imm[11],opcode});
  $display("BGEU rs1:%d, rs2:%d, imm:%d",rs1,rs2,imm);   
end 
endtask 


//=======================
// INSTRUCTION QUEUE WRITE FUNCTION 
//=======================
task WRITE(
   input logic [(DATAWITHBIT-1):0] wrt_data
);
begin
    /* WRITE TO IQ 
    @(posedge clk);
     i_iq_wrt_en   <= 1'b1;
     i_iq_wrt_data <= wrt_data;
    @(posedge clk); 
     i_iq_wrt_en   = 1'b0;
     */
    
    // WRITE TO PROGRAM MEMORY  
    @(posedge clk);
       $display("WRITE TO ROM: ADDR:%h DATA:%h ",ROM_ADDR,wrt_data);
       uCORE.uPROGRAM_MEM.ROM[ROM_ADDR] <= wrt_data;
       ROM_ADDR                         <= ROM_ADDR + 1;
end 
endtask 

int error;



//=============================================
// TEST 1: SELF-CHECK  
//=============================================
task TEST1(input int start_data = '0);
begin
   error = 0;
   start = 1'b0;
   for(int i =0;i<32;i++)
   begin
      ADDI(i,0,(i+start_data));
   end 
   //
   RESET();  
   repeat(10) @(posedge clk);
   start = 1'b1;
   //
   repeat(3000) @(posedge clk);
   //
   // CHECK REGISTER VALUES AFTER THE INSTRUCTIONS ARE DONE. 
   if(uCORE.uREGISTER_FILE.reg_mem[0]!=0)
   begin
      error = error + 1;
      $display("TEST1 ERROR REG:0 Time:%t Actual:%d Expected:0",$time,uCORE.uREGISTER_FILE.reg_mem[0]);
      $display("Register 0 is ALWAYS 0.");
   end 
   
   for(int i =1;i<32;i++)
   begin
      if(uCORE.uREGISTER_FILE.reg_mem[i]!=(i+start_data))
      begin
         error = error + 1;
         $display("TEST1 ERROR REG:%d Time:%t Actual:%d Expected:%d",i,$time,uCORE.uREGISTER_FILE.reg_mem[i],(i+start_data));
      end 
   end  
   //
   if(error==0) $display("TEST 1 PASSED");
   else         $display("TEST 1 FAILED. %d ERRORS",error);
end 
endtask


//=============================================
// TEST 2: SELF CHECK
//=============================================
//BEQ
task TEST2();
begin
   error = '0;
   //
   ADDI(1,0,33);
   ADDI(2,0,33);
   BEQ( .rs1  (1), .rs2 (2),  .imm (16) );
   ADDI(3,0,33);
   ADDI(4,0,34);
   ADDI(5,0,35);
   ADDI(6,0,36);
   ADDI(7,0,37);
   ADDI(8,0,38);
   //
   //
   RESET();  
   repeat(10) @(posedge clk);
   start = 1'b1;
   repeat(1000) @(posedge clk);
   //
   if(uCORE.uREGISTER_FILE.reg_mem[0]!='d0)    error++;
   if(uCORE.uREGISTER_FILE.reg_mem[1]!='d33)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[2]!='d33)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[3]!='d0)    error++;
   if(uCORE.uREGISTER_FILE.reg_mem[4]!='d0)    error++;
   if(uCORE.uREGISTER_FILE.reg_mem[5]!='d0)    error++;
   if(uCORE.uREGISTER_FILE.reg_mem[6]!='d36)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[7]!='d37)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[8]!='d38)   error++;
   
   if(error==0) $display("TEST 2 PASSED");
   else         $display("TEST 2 FAILED. %d ERRORS",error);
end 
endtask 



//=============================================
// TEST 3: SELF CHECK
//=============================================
// STORE/LOAD WORD TEST 
task TEST3();
begin
   ADDI(1,0,8);
   ADDI(2,0,5);
   ADDI(3,0,10);
   ADDI(4,0,15);
   ADDI(5,0,20);
   ADDI(6,0,25);
   ADDI(7,0,30);
   ADDI(8,0,35);
   //
   SW( .rs1 (1), .rs2 (2), .imm (0) );
   SW( .rs1 (1), .rs2 (3), .imm (4) );
   SW( .rs1 (1), .rs2 (4), .imm (8) );
   SW( .rs1 (1), .rs2 (5), .imm (12) );
   SW( .rs1 (1), .rs2 (6), .imm (16) );
   SW( .rs1 (1), .rs2 (7), .imm (20) );
   SW( .rs1 (1), .rs2 (8), .imm (24) );
   //
   LW( .rd  (9),  .rs1 (1),  .imm (0) );
   LW( .rd  (10), .rs1 (1),  .imm (4) );
   LW( .rd  (11), .rs1 (1),  .imm (8) );
   LW( .rd  (12), .rs1 (1),  .imm (12) );
   LW( .rd  (13), .rs1 (1),  .imm (16) );
   LW( .rd  (14), .rs1 (1),  .imm (20) );
   LW( .rd  (15), .rs1 (1),  .imm (24) );
   //
   RESET();  
   repeat(10) @(posedge clk);
   start = 1'b1;
   repeat(2000) @(posedge clk);
   //
   if(uCORE.uREGISTER_FILE.reg_mem[0] !='d0)    error++;
   if(uCORE.uREGISTER_FILE.reg_mem[1] !='d8)    error++;
   if(uCORE.uREGISTER_FILE.reg_mem[2] !='d5)    error++;
   if(uCORE.uREGISTER_FILE.reg_mem[3] !='d10)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[4] !='d15)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[5] !='d20)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[6] !='d25)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[7] !='d30)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[8] !='d35)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[9] !='d5)    error++;
   if(uCORE.uREGISTER_FILE.reg_mem[10]!='d10)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[11]!='d15)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[12]!='d20)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[13]!='d25)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[14]!='d30)   error++;
   if(uCORE.uREGISTER_FILE.reg_mem[15]!='d35)   error++;
   //
      for(int i=16;i<32;i++)
      begin
         if(uCORE.uREGISTER_FILE.reg_mem[i]!='d0)   error++;
      end
   //
   if(error==0) $display("TEST 3 PASSED");
   else         $display("TEST 3 FAILED. %d ERRORS",error);
end 
endtask 




//==========================================
// MAIN STIMULUS 
//==========================================
initial begin
  ROM_ADDR = '0;
   
  //
  //TEST1(.start_data (5));
  //TEST2();
  TEST3();


  
 
   

   
 
   
   //ADDI(3,0,16);
   //ADDI(4,0,20);
   //ADDI(5,0,24);
   //ADDI(6,0,28);
   //SW( .rs1 (1), .rs2 (2),  .imm (12) );
   //SW( .rs1 (3), .rs2 (4),  .imm (110) );
   //SW( .rs1 (5), .rs2 (6),  .imm (120) );
   //LW( .rd  (6), .rs1 (1),  .imm (12) );
   ///LW( .rd  (7), .rs1 (2),  .imm (208) );
   //ADDI(7,0,33);
   //ADDI(7,0,34);
   //LW( .rd  (8), .rs1 (7),  .imm (12) );
   //BEQ( .rs1  (1), .rs2 (2),  .imm (12) );
   //BNE( .rs1  (1), .rs2 (2),  .imm (12) );
   //BLT( .rs1  (1), .rs2 (2),  .imm (12) );
   //BGE( .rs1  (1), .rs2 (2),  .imm (12) );
   //BLTU( .rs1  (1), .rs2 (2),  .imm (12) );
   //BGEU( .rs1  (1), .rs2 (2),  .imm (12) );
    


  repeat(10) @(posedge clk);
  $finish;
end 



//===============================
//  CORE Instantiation  
//===============================
CORE
#( .DATAWITHBIT (DATAWITHBIT), 
   .FIFOSIZE    (FIFOSIZE), 
   .ROBSIZE     (ROBSIZE),
   .LSQSIZE     (LSQSIZE))
uCORE
(
  .start         (start),
  .clk           (clk),
  .rstn          (rstn)
);

endmodule





