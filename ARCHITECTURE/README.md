The files in this dicectory explains the details of the Micro-Architecture of the Core. 

## Instruction Fetch Stage 






## Instruction Queue Read / Decode / Renaming Stage 

Step1: Instruction Fetch Stage   
   
Step2: If Instruction queue is not empty Core_Control_Unit checks if any one of reservation stations, ROB, BTC, JEU, BRT is full. If all the modules are ready, it reads the instruction queue package.  \       
Step3: Instruction Queue package contains the following;      
   - 32-bit instruction
   - 32-bit instruction address
   - 32-bit instruction target
   - 1-bit instruction taken prediction
   
Step4: Instruction Decode;     
   - Decode opcode, rd, funct3, rs1, rs2, funct7
   - Check if instruction is M-extension, I-extension, control transfer, legal instruction, generate operation and immidiate type select signals.
   - Decode load store size and if the operation is signed or unsigned.
step5: Immidiate Generation Unit generates the 32-bit immediate value if the instruction is immediate instruction.
   
step6: Source Register Value Read;   
    - Read the rs1 and rs2 values from the Register File   
    - Read RAT table to learn if core will take the rs1 and rs2 values from the Register File or ROB.    
    - Read ROB addresses that will provide the rs1 and rs2 values. If rs1 and rs2 values are in register file, these ROB adresses will be discarded.    
    - Read the Data and Valid values from the ROB using the ROB addresses provided by the RAT table.    
    - If the rs1 and rs2 values are in register file, the values are read from the register file and they are ready to be used.    
    - If the values are in ROB, check if the values are ready or not. If ROB values are ready, read the values from ROB. If values are not ready, the values will be brodcasted with the 
    ROB addresses on the Core Data Bus. 

step7: Write Instruction to the ROB (All instructions)
    - Every instruction is written to the ROB and assigned to a ROB address. The ROB address plays an ID number role for the instruction during its life-cycle.

step8: Write instruction to the Reservation Station (For ALU instruction)
    - 
