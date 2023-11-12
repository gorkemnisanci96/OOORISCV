The files in this dicectory explains the details of the Micro-Architecture of the Core. 

## Instruction Fetch Stage 






## Instruction Queue Read / Decode / Renaming Stage 

Step1: Instruction Fetch Stage  (All instructions)  
   
Step2: If Instruction queue is not empty Core_Control_Unit checks if any one of reservation stations, 
ROB, BTC, JEU, BRT is full. If none of the modues are full, it reads the instruction queue package. 

Step3: Instruction Queue package contains the following (All instructions);      
   - 32-bit instruction
   - 32-bit instruction address
   - 32-bit instruction target
   - 1-bit instruction taken prediction
   
Step4: Instruction Decode (All instructions);     
   - Decode opcode, rd, funct3, rs1, rs2, funct7
   - Check if instruction is M-extension, I-extension, control transfer, legal instruction, generate operation and immidiate type select signals.
   - Decode load store size and if the operation is signed or unsigned.
Step5: Immidiate Generation Unit generates the 32-bit immediate value if the instruction is immediate instruction.
   
Step6: Source Register Value Read (All instructions);   
    - Read the rs1 and rs2 values from the Register File   
    - Read RAT table to learn if core will take the rs1 and rs2 values from the Register File or ROB.    
    - Read ROB addresses that will provide the rs1 and rs2 values. If rs1 and rs2 values are in register file, these ROB adresses will be discarded.    
    - Read the Data and Valid values from the ROB using the ROB addresses provided by the RAT table.    
    - If the rs1 and rs2 values are in register file, the values are read from the register file and they are ready to be used.    
    - If the values are in ROB, check if the values are ready or not. If ROB values are ready, read the values from ROB. If values are not ready, the values will be brodcasted with the 
    ROB addresses on the Core Data Bus. 

Step7: Write Instruction to the ROB (All instructions)
    - Every instruction is written to the ROB and assigned to a ROB address. The ROB address plays an ID number role for the instruction during its life-cycle.

Step8: Write instruction to the Reservation Station (For ALU instruction)
    - The Reservation station stores ALU opcode, rs1, rs2 values, their valid signals and rob address for the instruction and rs1, rs2 values.    
    - If rs1 or rs2 values of the instruction are not ready, reservation station wait for the value(s) to be brodcasted. So everytime there is a broadcast on the data bus, it compares the ROB
    address of the brodcasted value with the ROB address of the rs1 and rs2 values stored. If there is a match, it stores the value and sets the valid bit of the matchin rs1 or rs2.    
    - If the rs1 and rs2 values of the instruction are ready and the ALU control unit is not busy, the instruction is sent to the ALY control unit, which will perform the execution. This step is called DISPATCH. 
    - If there are multiple instructions ready to be dispatched, the reservation station chooses the instruction with the lowest index on the table.    
   
Step9: Execution and Broadcast for ALU instructions; 
    - The executution unit takes N-CC to execute the instruction. 
    - When the result is ready, it sets the broadcast_ready signal and wait for its turn to broadcast the result. 
    - Since there can be multiple execution units that wants to broadcast at the same time and the boardcast bus is shared among multiple execution units, core_control_unit uses Least Recently Granted First (LRGF) Arbiter to choose the next excution unit to brodcast its value.
    - The Value is broadcasted to all the all the reservation stations, load_store queue and the ROB. The broadcast contains the data, ROB address of the instruction and if the data is a memory address, which will be captured by the load_store queue. 

Step10: Execution and broadcast for LOAD/STORE instructions; 
   - After Decoding, the LOAD and STORE instructions are written to Load/Store queue.
   - The Load Instruction reads an memory address and write the value to a destination register.
   - Store instruction reads value of a register and writes it to a memory location.
   - Load/Store Queue keeps track of the broadcasted data. The data may be register value for store to be stored to the memory or memory address for store or load.
   - Load Store queue sends the load/store instructions to the memory IN-ORDER.
   - There is NO DATA FORWARDING between load and store instructions.   
   - The queue works as a FIFO.
   - When the read pointer points to a LOAD instruction, memory is not busy, and address of the load is ready, the load instruction is sent to memory unit for memory read operation immediately.
   -  When the read pointer points to a store instruction, memory is not busy, store address and data are ready, the load store queue waits ROB commit pointer to point the store instruction. Only in commit, store instruction is sent to memory for memory write operation.
   -  When memory read operation is complete, Data Memory Management unit (DMMU) sets its broadcast signal and waits grant from the core control unit to get the access to the Core Data Bus for broadcast operation.

STEP11: Execution for Conditional Branch Instructions: 



    




    
