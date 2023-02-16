`timescale 1ns / 1ps

////////////////////////////////
// "1-bit" BRANCH HISTORY TABLE 
////////////////////////////////
module BHT_1bit
#( parameter PCSIZE = 10)
(
   input logic                clk, 
   input logic                rstn,
   // UPDATE 
   input logic                i_update_en,
   input logic [(PCSIZE-1):0] i_update_pc, 
   input logic                i_update_taken, 
   // READ 
   input logic [(PCSIZE-1):0] i_read_pc,
   output logic               o_read_taken 
    );
    
    
    
logic  [(2**PCSIZE-1):0]  PC_TAKEN;    
    

// UPDATE BLOCK     
always_ff @(posedge clk or negedge rstn)
begin
   
   if(!rstn)begin
      PC_TAKEN      <= '0;

   end else 
   begin
      //
      if(i_update_en) begin
         PC_TAKEN[i_update_pc] <= i_update_taken;
      end 
      //

   end 


end 


// READ BLOCK 
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      o_read_taken  <= '0;
   end else begin
      o_read_taken <= PC_TAKEN[i_read_pc];
   end 
end 

   
    
    
endmodule :BHT_1bit



////////////////////////////////
// "2-bit" BRANCH HISTORY TABLE 
////////////////////////////////
//|PC| 2-bit Counter |
//|  |SNT- NT-  T- ST| 
//|  | 00- 01- 10- 11|
module BHT_2bit
#( parameter PCSIZE = 10)
(
   input logic                clk, 
   input logic                rstn,
   // UPDATE 
   input logic                i_update_en,
   input logic [(PCSIZE-1):0] i_update_pc, 
   input logic                i_update_taken, 
   // READ 
   input logic [(PCSIZE-1):0] i_read_pc,
   output logic               o_bht_2bit
    );
    

    
    
localparam [1:0] INITIALCOUNTER = 2'b01;    
logic [1:0] T_COUNTER [(2**PCSIZE-1):0];    
    

// UPDATE BLOCK     
always_ff @(posedge clk or negedge rstn)
begin
   
   if(!rstn)begin
      for(int i=0;i<(2**PCSIZE);i++)
      begin
         T_COUNTER[i] <= INITIALCOUNTER;
      end 

   end else 
   begin
      //
      // UPDATE THE BHT 
      if(i_update_en) begin
      
         if(i_update_taken)
         begin
            // 
            if(T_COUNTER[i_update_pc] != 2'b11)
            begin
               T_COUNTER[i_update_pc] <= T_COUNTER[i_update_pc] + 2'b1;
            end
            // 
         end else begin
            //
            if(T_COUNTER[i_update_pc] != 2'b00)
            begin
               T_COUNTER[i_update_pc] <= T_COUNTER[i_update_pc] - 2'b1;
            end 
            //
         end 
      end 
      //
   end 


end      
 
 
// READ BLOCK  
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      o_bht_2bit  <= '0;
   end else begin
      o_bht_2bit  <= T_COUNTER[i_read_pc][1];
   end 
end  
 
 
 
    
    
endmodule :BHT_2bit



////////////////////////////////
// "1-bit History-2-bit Counter"  BRANCH HISTORY TABLE 
////////////////////////////////
//|PC|1-bit| 2-bit Counter 0| 2-bit Counter 1|
//|  |     |SNT- NT-  T- ST |SNT- NT-  T- ST | 
//|  |     | 00- 01- 10- 11 | 00- 01- 10- 11 |
module BHT_1bithis_2bitcnt
#( parameter PCSIZE = 10)
(
   input logic                clk, 
   input logic                rstn,
   // UPDATE 
   input logic                i_update_en,
   input logic [(PCSIZE-1):0] i_update_pc, 
   input logic                i_update_taken, 
   // READ 
   input logic [(PCSIZE-1):0] i_read_pc,
   output logic               o_bht_1bithis_2bitcnt
    );
    
localparam [1:0] INITIALCOUNTER = 2'b01;  
logic [(2**PCSIZE-1):0] T_HISTORY;   
logic [1:0]             T_COUNTER0 [(2**PCSIZE-1):0];    
logic [1:0]             T_COUNTER1 [(2**PCSIZE-1):0];    
    
    
    
//==============================
// The Update FF Block     
//==============================        
always_ff @(posedge clk or negedge rstn)
begin
   
   if(!rstn)begin
      for(int i=0;i<(2**PCSIZE);i++)
      begin
         T_HISTORY[i]  <= 1'b0; 
         T_COUNTER0[i] <= INITIALCOUNTER;
         T_COUNTER1[i] <= INITIALCOUNTER;
      end 
   end else 
   begin
      //
      // UPDATE THE BHT 
      if(i_update_en) begin
          
         // If the previous History bit is 1, the prediction was made by the 
         // Counter-1 and vice-versa. So We need to update the counter that made the 
         // previous prediction.    
         if(T_HISTORY[i_update_pc])
         begin
             // If the Outcome of the Branch is taken, we will move the state towards
             // the Strongly-Taken side and vice-versa. 
 			 if(i_update_taken)
			 begin
				// If the Outcome is Taken and State is already Strongly-Taken(11),
				// Dont update it. 
				if(T_COUNTER1[i_update_pc] != 2'b11)
				begin
				   T_COUNTER1[i_update_pc] <= T_COUNTER1[i_update_pc] + 2'b1;
				end
				// 		 
			 end else begin
				// If the Outcome is Not-Taken, we will move the state of the Counter1 towards
				// the Strongly-Nottaken side unless state is already SN. 
				if(T_COUNTER1[i_update_pc] != 2'b00)
				begin
				   T_COUNTER1[i_update_pc] <= T_COUNTER1[i_update_pc] - 2'b1;
				end 
				//
			 end             
         end else begin
         
 			 if(i_update_taken)
			 begin
				// 
				if(T_COUNTER0[i_update_pc] != 2'b11)
				begin
				   T_COUNTER0[i_update_pc] <= T_COUNTER0[i_update_pc] + 2'b1;
				end
				// 		 
			 end else begin
				//
				if(T_COUNTER0[i_update_pc] != 2'b00)
				begin
				   T_COUNTER0[i_update_pc] <= T_COUNTER0[i_update_pc] - 2'b1;
				end 
				//
			 end   
         end 
         
         // Update History
         T_HISTORY[i_update_pc] <= i_update_taken; 
         //        
      end 
      //
      

   end 


end  


//==============================
// READ THE BHT     
//============================== 
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      o_bht_1bithis_2bitcnt <= 1'b0;
   end else begin
      // READ THE BHT 
      // If the History bit is 1, the Counter1 makes the new prediction and vice-versa. 
      if(T_HISTORY[i_read_pc])
      begin
         o_bht_1bithis_2bitcnt  <= T_COUNTER1[i_read_pc][1];
      end else begin
         o_bht_1bithis_2bitcnt  <= T_COUNTER0[i_read_pc][1];
      end 
      //
   end 
end 

    
     
    
endmodule :BHT_1bithis_2bitcnt






////////////////////////////////
// "History With Private-Shared Counters"  BRANCH HISTORY TABLE 
////////////////////////////////
// Pattern History Table 
//|PC*|N-bit History|    -----> //|N-bit History XOR PC *| 2-bit Counter  | 
//                                                       | SN- NT-  T- ST |
//                                                       | 00- 01- 10- 11 |
module BHT_pshared
#( parameter PCSIZE      = 10,
   parameter HISTORYSIZE = 2)
(
   input logic                clk, 
   input logic                rstn,
   // UPDATE 
   input logic                i_update_en,
   input logic [(PCSIZE-1):0] i_update_pc, 
   input logic                i_update_taken, 
   // READ 
   input logic [(PCSIZE-1):0] i_read_pc,
   output logic               o_bht_pshared 
    );
    

localparam [1:0] INITIALCOUNTER = 2'b01;  
logic [(HISTORYSIZE-1):0] T_PHT      [(2**PCSIZE-1):0];
logic [1:0]               T_COUNTER  [(2**PCSIZE-1):0];    
logic [(PCSIZE-1):0]      updateaddr;  
logic [(PCSIZE-1):0]      readaddr;       
      
    
    

// UPDATE ADDRESS GENERATION
//   We XOR the Private History of the UPDATE-PC with the UPDATE-PC to generate a
//   pointer to update the shared COUNTER table. 
assign updateaddr = T_PHT[i_update_pc] ^ i_update_pc;
// READ ADDRESS GENERATION 
//   We XOR the Private History of the READ-PC with the READ-PC to generate a
//   pointer to read the shared COUNTER table. 
assign readaddr   = T_PHT[i_read_pc] ^ i_read_pc;


// UPDATE 
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      for(int i=0; i<(2**PCSIZE);i++)
      begin
         T_PHT[i]     <= '0;    
         T_COUNTER[i] <= INITIALCOUNTER;
      end 
   end else begin
      // UPDATE THE BHT 
      if(i_update_en) begin
             // UPDATE PRAVITE HISTORY
             T_PHT[i_update_pc] <= {T_PHT[i_update_pc][(HISTORYSIZE-2):0],i_update_taken};
             
             // UPDATE SHARED COUNTER 
             if(i_update_taken)
			 begin
				// 
				if(T_COUNTER[updateaddr] != 2'b11)
				begin
				   T_COUNTER[updateaddr] <= T_COUNTER[updateaddr] + 2'b1;
				end
				// 		 
			 end else begin
				//
				if(T_COUNTER[updateaddr] != 2'b00)
				begin
				   T_COUNTER[updateaddr] <= T_COUNTER[updateaddr] - 2'b1;
				end 
				//
			 end  
			 // 

			 
      end 
      //
   end 
end 









//==============================
// READ THE BHT     
//============================== 
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      o_bht_pshared  <= 1'b0;
   end else begin
      // READ THE BHT 
      // If the History bit is 1, the Counter1 makes the new prediction and vice-versa. 
      o_bht_pshared <= T_COUNTER[readaddr][1];
      //
   end 
end     
    
    
    
    
endmodule :BHT_pshared


////////////////////////////////
// "History With Global-Shared Counters"  BRANCH HISTORY TABLE 
////////////////////////////////
// Global Pattern History Table 
//|N-bit History|           -----> //|N-bit History XOR PC *| 2-bit Counter  | 
//                                                          |SNT- NT-  T- ST |
//                                                          | 00- 01- 10- 11 |


module BHT_gshared
#( parameter PCSIZE      = 10,
   parameter HISTORYSIZE = 10)
(
   input logic                clk, 
   input logic                rstn,
   // UPDATE 
   input logic                i_update_en,
   input logic [(PCSIZE-1):0] i_update_pc, 
   input logic                i_update_taken, 
   // READ 
   input logic [(PCSIZE-1):0] i_read_pc,
   output logic               o_bht_gshared 
    );
    
localparam [1:0] INITIALCOUNTER = 2'b01;  
logic [(HISTORYSIZE-1):0] T_HISTORY;
logic [1:0]               T_COUNTER  [(2**PCSIZE-1):0];    
logic [(PCSIZE-1):0]      updateaddr;  
   
      
    
    

// UPDATE ADDRESS GENERATION
//   We XOR the Private History of the UPDATE-PC with the UPDATE-PC to generate a
//   pointer to update the shared COUNTER table. 
assign updateaddr = T_HISTORY ^ i_update_pc;
// READ ADDRESS GENERATION 
//   We XOR the Global History to generate a
//   pointer to read the shared COUNTER table. 
assign readaddr   = T_HISTORY ^ i_read_pc;


// UPDATE 
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      T_HISTORY       <= '0;   
      for(int i=0; i<(2**PCSIZE);i++)
      begin
         T_COUNTER[i] <= INITIALCOUNTER;
      end 
   end else begin
      // UPDATE THE BHT 
      if(i_update_en) begin
             // UPDATE THE GLOBAL HISTORY
             T_HISTORY <= {T_HISTORY[(HISTORYSIZE-2):0],i_update_taken};
             
             // UPDATE SHARED COUNTER 
             if(i_update_taken)
			 begin
				// 
				if(T_COUNTER[updateaddr] != 2'b11)
				begin
				   T_COUNTER[updateaddr] <= T_COUNTER[updateaddr] + 2'b1;
				end
				// 		 
			 end else begin
				//
				if(T_COUNTER[updateaddr] != 2'b00)
				begin
				   T_COUNTER[updateaddr] <= T_COUNTER[updateaddr] - 2'b1;
				end 
				//
			 end  
			 //  
      end 
      //
   end 
end 


//==============================
// READ THE BHT     
//============================== 
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      o_bht_gshared  <= 1'b0;
   end else begin
      // READ THE BHT 
      // If the History bit is 1, the Counter1 makes the new prediction and vice-versa. 
      o_bht_gshared <= T_COUNTER[readaddr][1];
      //
   end 
end     

  
endmodule :BHT_gshared




////////////////////////////////
// BRANCH HISTORY TABLE TEST BENCH 
////////////////////////////////
module BHT_tb();

parameter PCSIZE = 5;
parameter PHISTORYSIZE = 3;
parameter GHISTORYSIZE = 3;

logic                clk;
logic                rstn;
//
logic                i_update_en;
logic [(PCSIZE-1):0] i_update_pc; 
logic                i_update_taken; 
// READ 
logic [(PCSIZE-1):0] i_read_pc;
logic                o_read_taken; 
logic                o_bht_2bit;
logic                o_bht_1bithis_2bitcnt;
logic                o_bht_pshared;
logic                o_bht_gshared;
   
//=================================
// CLOCK GENERATION 
//=================================   
initial begin
   clk = 1'b0;
   forever #10 clk = ~clk;
end 


//=================================
// RESET TASK
//=================================
task RESET();
begin
   i_update_en    = '0;
   i_update_pc    = '0;
   i_update_taken = '0;
   i_read_pc      = '0;
   //
   rstn = 1'b1;
   @(posedge clk);
   rstn = 1'b0;
   repeat(2)@(posedge clk);
   rstn = 1'b1;
end 
endtask 



//=================================
// UPDATE THE BHT TASK 
//=================================
task UPDATE(
  input logic [(PCSIZE-1):0] update_pc,
  input logic                update_taken 
);
begin
   @(posedge clk);
      i_update_en    <= 1'b1;
      i_update_pc    <= update_pc;
      i_update_taken <= update_taken;
   @(posedge clk);
      i_update_en    <= '0;
      i_update_pc    <= '0;
      i_update_taken <= '0;  
end 
endtask

//=================================
// READ 
//=================================
task READ(input logic [(PCSIZE-1):0] read_pc);
begin
   @(posedge clk);
      i_update_en    <= '0;
      i_update_pc    <= '0;
      i_update_taken <= '0;  
      i_read_pc      <= read_pc;
   @(posedge clk);
      i_read_pc      <= '0;
end 
endtask



initial begin
   RESET(); 
   UPDATE( .update_pc (0), .update_taken (1'b1));
   UPDATE( .update_pc (1), .update_taken (1'b1));
   UPDATE( .update_pc (2), .update_taken (1'b1));
   UPDATE( .update_pc (3), .update_taken (1'b1));
   UPDATE( .update_pc (4), .update_taken (1'b1));
   UPDATE( .update_pc (5), .update_taken (1'b1));
   //
   UPDATE( .update_pc (0), .update_taken (1'b1));
   UPDATE( .update_pc (1), .update_taken (1'b0));
   UPDATE( .update_pc (2), .update_taken (1'b1));
   UPDATE( .update_pc (3), .update_taken (1'b0));
   UPDATE( .update_pc (4), .update_taken (1'b1));
   UPDATE( .update_pc (5), .update_taken (1'b0));
   //
   READ(.read_pc (1));
   READ(.read_pc (2));
   READ(.read_pc (3));
   READ(.read_pc (4));
   READ(.read_pc (5));
   
   

   $finish;
end 



BHT_1bit            #( .PCSIZE (PCSIZE)) uBHT_1bit (.*);
BHT_2bit            #( .PCSIZE (PCSIZE)) uBHT_2bit (.*);
BHT_1bithis_2bitcnt #( .PCSIZE (PCSIZE)) uBHT_1bithis_2bitcnt (.*);
BHT_pshared         #( .PCSIZE (PCSIZE),.HISTORYSIZE (PHISTORYSIZE)) uBHT_pshared (.*);
BHT_gshared         #( .PCSIZE (PCSIZE),.HISTORYSIZE (GHISTORYSIZE)) uBHT_gshared (.*);



endmodule 


