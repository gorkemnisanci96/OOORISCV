`timescale 1ns / 1ps
`include "headers.vh"

module ID(
input  wire [31:0] inst_i,
input  wire [6:0]  opcode_i,
input  wire [2:0]  funct3_i,
input  wire [6:0]  funct7_i,
input  wire        stall_flag_i,
output wire        invalid_inst_o,
output wire [9:0]  alu_op_sel_o,
output wire [2:0]  load_mux_sel_o,
output wire [3:0]  data_mem_op_sel,
output wire [3:0]  alu_in_sel_o,
output wire [5:0]  imm_sel_o,
output wire [2:0]  jump_sel_o,
output wire        branch_inst_o,
output wire        load_inst_o,
output wire        rs2_is_imm_o,
output wire        csr_inst_o,
output wire        ebreak_inst_o,
output wire        ecall_inst_o,
output wire        mret_inst_o 
    );
    
// BASE Instructions     
wire LUI    = (opcode_i[6:2] == `OPCODE_LUI)   ;
wire AUIPC  = (opcode_i[6:2] == `OPCODE_AUIPC) ;
wire JAL    = (opcode_i[6:2] == `OPCODE_JAL )  ;    
wire JALR   = (funct3_i == `FUNCT3_JALR) && (opcode_i[6:2] == `OPCODE_JALR);
wire BEQ    = (funct3_i == `FUNCT3_BEQ)  && (opcode_i[6:2] == `OPCODE_BRANCH);
wire BNE    = (funct3_i == `FUNCT3_BNE)  && (opcode_i[6:2] == `OPCODE_BRANCH);
wire BLT    = (funct3_i == `FUNCT3_BLT)  && (opcode_i[6:2] == `OPCODE_BRANCH);
wire BGE    = (funct3_i == `FUNCT3_BGE)  && (opcode_i[6:2] == `OPCODE_BRANCH);
wire BLTU   = (funct3_i == `FUNCT3_BLTU) && (opcode_i[6:2] == `OPCODE_BRANCH);
wire BGEU   = (funct3_i == `FUNCT3_BGEU) && (opcode_i[6:2] == `OPCODE_BRANCH);
wire LB     = (funct3_i == `FUNCT3_LB)   && (opcode_i[6:2] == `OPCODE_LOAD);
wire LH     = (funct3_i == `FUNCT3_LH)   && (opcode_i[6:2] == `OPCODE_LOAD);
wire LW     = (funct3_i == `FUNCT3_LW)   && (opcode_i[6:2] == `OPCODE_LOAD);
wire LBU    = (funct3_i == `FUNCT3_LBU)  && (opcode_i[6:2] == `OPCODE_LOAD);
wire LHU    = (funct3_i == `FUNCT3_LHU)  && (opcode_i[6:2] == `OPCODE_LOAD);
wire SB     = (funct3_i == `FUNCT3_SB)   && (opcode_i[6:2] == `OPCODE_STORE);
wire SH     = (funct3_i == `FUNCT3_SH)   && (opcode_i[6:2] == `OPCODE_STORE);
wire SW     = (funct3_i == `FUNCT3_SW)   && (opcode_i[6:2] == `OPCODE_STORE);
wire ADDI   = (funct3_i == `FUNCT3_ADDI) && (opcode_i[6:2] == `OPCODE_INT_IMM);
wire SLTI   = (funct3_i == `FUNCT3_SLTI) && (opcode_i[6:2] == `OPCODE_INT_IMM);
wire SLTIU  = (funct3_i == `FUNCT3_SLTIU)&& (opcode_i[6:2] == `OPCODE_INT_IMM);
wire XORI   = (funct3_i == `FUNCT3_XORI) && (opcode_i[6:2] == `OPCODE_INT_IMM);
wire ORI    = (funct3_i == `FUNCT3_ORI)  && (opcode_i[6:2] == `OPCODE_INT_IMM);
wire ANDI   = (funct3_i == `FUNCT3_ANDI) && (opcode_i[6:2] == `OPCODE_INT_IMM);
wire SLLI   = (funct7_i == `FUNCT7_SLLI) && (funct3_i == `FUNCT3_SLLI) && (opcode_i[6:2] == `OPCODE_INT_IMM);
wire SRLI   = (funct7_i == `FUNCT7_SRLI) && (funct3_i == `FUNCT3_SRLI) && (opcode_i[6:2] == `OPCODE_INT_IMM);
wire SRAI   = (funct7_i == `FUNCT7_SRAI) && (funct3_i == `FUNCT3_SRAI) && (opcode_i[6:2] == `OPCODE_INT_IMM);
wire ADD    = (funct7_i == `FUNCT7_ADD)  && (funct3_i == `FUNCT3_ADD)  && (opcode_i[6:2] == `OPCODE_INT);
wire SUB    = (funct7_i == `FUNCT7_SUB)  && (funct3_i == `FUNCT3_SUB)  && (opcode_i[6:2] == `OPCODE_INT);
wire SLL    = (funct7_i == `FUNCT7_SLL)  && (funct3_i == `FUNCT3_SLL)  && (opcode_i[6:2] == `OPCODE_INT);
wire SLT    = (funct7_i == `FUNCT7_SLT)  && (funct3_i == `FUNCT3_SLT)  && (opcode_i[6:2] == `OPCODE_INT);
wire SLTU   = (funct7_i == `FUNCT7_SLTU) && (funct3_i == `FUNCT3_SLTU) && (opcode_i[6:2] == `OPCODE_INT);
wire XOR    = (funct7_i == `FUNCT7_XOR)  && (funct3_i == `FUNCT3_XOR)  && (opcode_i[6:2] == `OPCODE_INT);
wire SRL    = (funct7_i == `FUNCT7_SRL)  && (funct3_i == `FUNCT3_SRL)  && (opcode_i[6:2] == `OPCODE_INT);
wire SRA    = (funct7_i == `FUNCT7_SRA)  && (funct3_i == `FUNCT3_SRA)  && (opcode_i[6:2] == `OPCODE_INT);
wire OR     = (funct7_i == `FUNCT7_OR)   && (funct3_i == `FUNCT3_OR)   && (opcode_i[6:2] == `OPCODE_INT);
wire AND    = (funct7_i == `FUNCT7_AND)  && (funct3_i == `FUNCT3_AND)  && (opcode_i[6:2] == `OPCODE_INT);
wire FENCE  = (funct3_i == `FUNCT3_FENCE)&& (opcode_i == `OPCODE_FENCE);     
wire ECALL  = (inst_i   == `INST_ECALL);
wire EBREAK = (inst_i   == `INST_EBREAK);
wire MRET   = (inst_i   == `INST_MRET);
// CSR Instructions 
wire CSRRW  = (funct3_i == `FUNCT3_CSRRW)  && (opcode_i[6:2] == `OPCODE_CSR);
wire CSRRS  = (funct3_i == `FUNCT3_CSRRS)  && (opcode_i[6:2] == `OPCODE_CSR);
wire CSRRC  = (funct3_i == `FUNCT3_CSRRC)  && (opcode_i[6:2] == `OPCODE_CSR); 
wire CSRRWI = (funct3_i == `FUNCT3_CSRRWI) && (opcode_i[6:2] == `OPCODE_CSR);
wire CSRRSI = (funct3_i == `FUNCT3_CSRRSI) && (opcode_i[6:2] == `OPCODE_CSR);
wire CSRRCI = (funct3_i == `FUNCT3_CSRRCI) && (opcode_i[6:2] == `OPCODE_CSR);
// 
wire VALID_INSTRUCTION =(LUI | JALR | BEQ | BNE   | BLT  | 
                        AUIPC| BGE  | BLTU | BGEU | LB   |
                        JAL  | LH   | LW   | LBU  | LHU  | 
                        SB   | SH   | SW   | ADDI | 
                        SLTI | SLTIU| XORI | ORI  | 
                        ANDI | SLLI | SRLI | SRAI | 
                        ADD  | SUB  | SLL  | SLT  | 
                        SLTU | XOR  | SRL  | SRA  | 
                        OR   | AND  | FENCE| ECALL| MRET |
                        EBREAK |CSRRW | CSRRS | CSRRC | 
                        CSRRWI | CSRRSI | CSRRCI) && (opcode_i[1] & opcode_i[0]) ;
                        
 wire LOAD_INSTS   =  (LB  | LH  | LW  | LBU  | LHU)  ;                    
 wire STORE_INSTS  =  (SB  | SH  | SW) ;
 wire BRANCH_INSTS =  (BEQ | BNE |BLT  | BGE  | BLTU | BGEU)  ;
 wire CSR_INSTS    =  (CSRRW | CSRRS | CSRRC | CSRRWI | CSRRSI | CSRRCI) ;
 
     

 
 // OUTPUTS 
assign invalid_inst_o =  ~VALID_INSTRUCTION;                    

// ALU operation selection signals 
assign alu_op_sel_o [0] = BRANCH_INSTS | SUB | SLTI | SLTIU | SLT | SLTU  ; // Subtraction Enable
assign alu_op_sel_o [1] = SLTI | SLTIU | SLT   | SLTU ;                             // Comparison Enable 
assign alu_op_sel_o [2] = BLTU | BGEU  | SLTIU | SLTU ;                             // Unsigned Enable 
assign alu_op_sel_o [3] = SRLI | SRAI  | SRL   | SRL  | SRA ;                       // Right shift enable
assign alu_op_sel_o [4] = SRAI | SRA ;                                              // Arithmetic shift 
assign alu_op_sel_o [5] = SLL  | SLLI  | SRLI  | SRAI | SRL   | SRL | SRA;          // Shift Operation
assign alu_op_sel_o [6] = ADD  | ADDI  | SUB   | SLTI | SLTIU | SLT | SLTIU | LUI | AUIPC | JAL | JALR;  // Arithmetic out
assign alu_op_sel_o [7] = AND  | ANDI; 
assign alu_op_sel_o [8] = OR   | ORI ; 
assign alu_op_sel_o [9] = XOR  | XORI; 


// Immediate Control Signals 
assign imm_sel_o[0] = JALR | LOAD_INSTS | SLLI | SRLI  | SRAI |ADDI | SLTI | SLTIU | XORI | ORI | ANDI; // I type immediate Flag                  
assign imm_sel_o[1] = STORE_INSTS ;  // S type immediate Flag   
assign imm_sel_o[2] = BRANCH_INSTS;  // B type immediate Flag  
assign imm_sel_o[3] = LUI | AUIPC;   // U type immediate Flag  
assign imm_sel_o[4] = JAL;           // J type immediate Flag  
assign imm_sel_o[5] = CSR_INSTS;     // CSR immediate Flag  
// Data Memory Control Signals
assign data_mem_op_sel[0] = LOAD_INSTS;
assign data_mem_op_sel[1] = STORE_INSTS;  
assign data_mem_op_sel[2] = SH;     
assign data_mem_op_sel[3] = SW;    
// Load Multiplexer Control Signals    
assign load_mux_sel_o[0] = LH | LHU;
assign load_mux_sel_o[1] = LW;
assign load_mux_sel_o[2] = LB  | LH ;   
// 
assign alu_in_sel_o[0] = JAL  | JALR ;
assign alu_in_sel_o[1] = SLLI | SRLI  | SRAI |ADDI | SLTI | SLTIU | XORI | ORI | ANDI;
assign alu_in_sel_o[2] = AUIPC;
assign alu_in_sel_o[3] = LUI;
//
assign jump_sel_o[0] = JAL            & ~stall_flag_i;
assign jump_sel_o[1] = JALR           & ~stall_flag_i;
assign jump_sel_o[2] = BRANCH_INSTS   & ~stall_flag_i;
//
assign branch_inst_o = BRANCH_INSTS & ~stall_flag_i;
assign load_inst_o   = LOAD_INSTS   & ~stall_flag_i;
assign rs2_is_imm_o  = imm_sel_o[0] | imm_sel_o[3] | imm_sel_o[4];
//
assign csr_inst_o    = CSR_INSTS;
//
assign ebreak_inst_o = ECALL;
assign ecall_inst_o  = ECALL;
assign mret_inst_o   = MRET;  


endmodule
