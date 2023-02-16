`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// DCACHE CONTROLLER 

module DCACHE_CONTROLLER
#(parameter ROBSIZE       = 8,  // Re-Order Buffer Size  
  parameter BLOCKSIZE     = 64, // Number of Blocks in External Memory  
  parameter BLOCKWORDSIZE = 4,  // Number of Words(32-bit) in each MemoryBlock/CacheLine 
  parameter CACHESETSIZE  = 4,  // Number of Sets in Cache  
  parameter CACHEWAYSIZE  = 4 ) // Number of Lines in Each Cache Set
(
   input logic                          clk,
   input logic                          rstn, 
   input logic                          i_cs,                 // CHIP SELECT
   input logic [31:0]                   i_addr,               // Memory Address 
   input logic [$clog2(ROBSIZE):0]      i_rob_addr,           // ROB Addr
   input logic                          i_load_store,         // LOAD OR STORE COMMAND 
   input logic [31:0]                   i_store_data,         // Store Data 
   input logic [1:0]                    i_size,               // Data Size-Byte|Half-Word|Word
   input logic                          i_signed_unsigned,    // Signed|Unsigned 
   // 
   input  logic                         i_broadcast_en,       // Broadcast Enable 
   output logic                         o_broadcast_ready,    // Broadcast Data Ready 
   output logic [$clog2(ROBSIZE):0]     o_broadcast_rob_addr, // Broadcast ROB Addr 
   output logic [31:0]                  o_broadcast_load_data,// Broadcast Data 
   //
   output logic                         o_mem_busy            // Memory Busy Flag 
    );


localparam CACHEOFFSETADDRSIZE =  $clog2(BLOCKWORDSIZE*4);
localparam CACHESETADDRSIZE    =  $clog2(CACHESETSIZE); 
localparam CACHETAGADDRSIZE    =  32-(CACHESETADDRSIZE+CACHEOFFSETADDRSIZE);

// CACHE INPUT REGISTERS     
logic        hit_check,    hit_check_next;    // Check Hit Enable 
logic [31:0] hit_addr,     hit_addr_next;     // Address to check the cache hit
// WRITE READ DATA 
logic        wrd_en,       wrd_en_next;       // Write Read Data Enable  
logic        wrd_wr,       wrd_wr_next;       // 1:Write 0:Read  
logic [($clog2(CACHEWAYSIZE)-1):0]  wrd_line_no,  wrd_line_no_next;  // Write Read Data Line Number 
logic [31:0] wrd_addr,     wrd_addr_next;     // Write Read Data Address 
logic [1:0]  wrd_size,     wrd_size_next;     // Write Read Data Size(Word/Half-Word/Byte) 
logic [31:0] wrd_wdata,    wrd_wdata_next;    // Write Read Data Write Data 
// Write Read Line          
logic        burst_start,  burst_start_next;  // Start the Burst 
logic        burst_wr,     burst_wr_next;     // 1: Write Burst 0: Read Burst 
logic [31:0] burst_addr,   burst_addr_next;   // Burst Start Address
logic [($clog2(CACHEWAYSIZE)-1):0]  burst_line_no,burst_line_no_next;// Line to Burst Read/Write  
logic [31:0] burst_wdata,  burst_wdata_next;  // 32-bit Value to Write 
logic        burst_wv,     burst_wv_next;     // burst_wdata valid
//
logic [$clog2(ROBSIZE):0]  rob_addr_reg, rob_addr_next;              // ROB ADDR 
logic [31:0]               addr_reg,addr_next;                       // Memory Address 
logic                      load_store_reg,load_store_next;           // LOAD OR STORE COMMAND 
logic [31:0]               store_data_reg,store_data_next;           // Store Data 
logic [1:0]                size_reg,size_next;                       // Data Size-Byte|Half-Word|Word
logic                      signed_unsigned_reg,signed_unsigned_next; // Signed|Unsigned  
// CACHE OUTPUT SIGNALS 
logic        hit;           // 1: Cache Hit 0:Cache Miss
logic [($clog2(CACHEWAYSIZE)-1):0]  hit_line_no,hit_line_no_reg,hit_line_no_next;   // o_hit==1: The line that hits, 
                            // o_hit==0: The line that we should write the block from memory.
logic        hit_line_v;    // 1: Hit line is Valid 0: Hit line is NOT Valid 
logic        hit_line_d;    // 1: Hit Line is Dirty 0: Hit line is NOT Dirty  
logic [31:0] write_back_addr,write_back_addr_reg,write_back_addr_next;  // Tag Number of the Line that will be written back 
logic [31:0] wrd_rdata;     // Write Read Data Read Data 
logic [31:0] burst_rdata;   // 32-bit Value to Read 
logic        burst_rv;      // burst_rdata valid   
logic        burst_done;    // Shows that Cache Completed the Burst operation  
logic        burst_wready;
// DCACHE CONTROLLER SIGNALS 
logic                      broadcast_ready_next;    // Broadcast Data Ready 
logic [$clog2(ROBSIZE):0]  broadcast_rob_addr_next; // Broadcast ROB Addr 
logic [31:0]               broadcast_load_data_next;// Broadcast Data 
//
// EXTERNAL MEMORY INPUTS 
logic        exmem_cs          ,exmem_cs_next;           // CHIP SELECT  
logic        exmem_write_read  ,exmem_write_read_next;   // 1:Write 0:Read 
logic [31:0] exmem_addr        ,exmem_addr_next;         // READ/WRITE ADDR 
logic [31:0] exmem_write_data  ,exmem_write_data_next;   // WRITE DATA WORD
logic        exmem_write_data_v,exmem_write_data_v_next; // WRITE DATA VALID
// EXTERNAL MEMORY OUTPUT 
logic [31:0] exmem_read_data;    // READ DATA WORD 
logic        exmem_read_data_v;  // READ DATA VALID 
logic        exmem_burst_done;   // BURST OPERATION IS DONE 
logic        exmem_write_ready;  // WRITE READY  
//

 typedef enum {
    IDLE,
    CACHE_HIT_CHECK,
    DATA_WRITE,
    DATA_READ_COMMAND_SEND,
    DATA_READ,
    WRITE_BACK_MEM_COMMAND,
    WRITE_BACK_MEM,
    LOAD_CACHE_COMMAND,
    LOAD_CACHE,
    BROADCAST
 } state_type;   
    

state_type state, state_next; 

//====================================
// STATE DIAGRAM 
//====================================
always_comb 
begin
                                       state_next = state; 
      // CACHE INPUT SIGNAL                                 
      hit_check_next     = hit_check;   
      hit_addr_next      = hit_addr;     
      wrd_en_next        = wrd_en;      
      wrd_wr_next        = wrd_wr;      
      wrd_line_no_next   = wrd_line_no; 
      wrd_addr_next      = wrd_addr;    
      wrd_size_next      = wrd_size;    
      wrd_wdata_next     = wrd_wdata;            
      burst_start_next   = burst_start; 
      burst_wr_next      = burst_wr;    
      burst_addr_next    = burst_addr;  
      burst_line_no_next = burst_line_no;
      burst_wdata_next   = burst_wdata; 
      burst_wv_next      = burst_wv;   
      // DCACHE CONTROLLER INPUT REGISTERS 
      addr_next            =   addr_reg;                     
      rob_addr_next        =   rob_addr_reg;  
      load_store_next      =   load_store_reg;
      store_data_next      =   store_data_reg;
      size_next            =   size_reg; 
      signed_unsigned_next =   signed_unsigned_reg;
      // BROADCAST SIGNALS 
      broadcast_ready_next     = o_broadcast_ready;     // Broadcast Data Ready 
      broadcast_rob_addr_next  = o_broadcast_rob_addr;  // Broadcast ROB Addr 
      broadcast_load_data_next = o_broadcast_load_data; // Broadcast Data
      //
      exmem_cs_next           = exmem_cs;         
      exmem_write_read_next   = exmem_write_read;   
      exmem_addr_next         = exmem_addr;         
      exmem_write_data_next   = exmem_write_data;   
      exmem_write_data_v_next = exmem_write_data_v; 
      //
      hit_line_no_next        = hit_line_no_reg;
      write_back_addr_next    = write_back_addr_reg;
      //
      o_mem_busy = 1'b1; 
    case(state)
       IDLE:            
         begin                                          
            exmem_write_data_next   = '0;
            exmem_write_data_v_next = '0;  
            //
            if(i_cs)
            begin                                 
               // SAVE THE INPUT VALUES     
               addr_next       =   i_addr;                     
               rob_addr_next   =   i_rob_addr;  
               load_store_next =   i_load_store;
               store_data_next =   i_store_data;
               size_next       =   i_size; 
               signed_unsigned_next =   i_signed_unsigned;
               //
               // GO TO THE CACHE-HIT-CHECK 
                                            state_next = CACHE_HIT_CHECK;    
               // SET THE CACHE-HIT-CHECK SIGNALS                                
               hit_check_next = 1'b1;   
               hit_addr_next  = i_addr;                                                
            end else begin
               o_mem_busy = 1'b0;
            end  
            //
         end 
       CACHE_HIT_CHECK: 
         begin 
               // RESET THE CACHE_HIT_CHECK SIGNALS 
               hit_check_next = 1'b0;   
               hit_addr_next  = '0; 
               // Save the Cache-Hit-Check Returns 
               hit_line_no_next     = hit_line_no; // Save the Hit line No 
               write_back_addr_next = write_back_addr;
               // CHECK THE CACHE HIT 
               if(hit)
               begin
                  //
                  wrd_line_no_next  = hit_line_no; // Write Read Data Line Number 
                  wrd_addr_next     = addr_reg;    // Write Read Data Address 
                  wrd_size_next     = size_reg;    // Write Read Data Size  
                  if(load_store_reg)
                  begin
                                            state_next = DATA_WRITE;  
                     // WRITE DATA SIGNALS                       
                     wrd_en_next       = 1'b1;           // Write Read Data Enable  
                     wrd_wr_next       = 1'b1;           // 1:Write 0:Read  
                     wrd_wdata_next    = store_data_reg; // Write Read Data Write Data                   
                  end else begin
                                            state_next = DATA_READ_COMMAND_SEND;  
                     // READ DATA SIGNALS                         
                     wrd_en_next       = 1'b1; // Write Read Data Enable  
                     wrd_wr_next       = 1'b0; // 1:Write 0:Read  
                     wrd_wdata_next    = '0;   // Write Read Data Write Data 
                  end   
                  // 
               end else begin
                  // CACHE MISS 
                  // THE LINE WE NEED TO REPLACE IS DIRTY SO WE NEED TO WRITE LINE BACK TO MEMORY[BURST READ LINE]  
                  if(hit_line_d)begin
                                            state_next = WRITE_BACK_MEM_COMMAND;                    
                     // WRITE BACK EXTERNAL MEMORY SIGNALS 
                     exmem_cs_next            <= 1'b1;         
                     exmem_write_read_next    <= 1'b1; // WRITE    
                     exmem_addr_next          <= write_back_addr;         
                     exmem_write_data_next    <= '0;   
                     exmem_write_data_v_next  <= '0;  
                  end else begin                  
                  // THE LINE WE NEED TO REPLACE IS NOT DIRTY SO WE CAN OVERWRITE IT 
                                            state_next = LOAD_CACHE_COMMAND;                  
                     burst_wr_next      = 1'b1;   // 1:BURST WRITE 0:BURST READ   
                  end 
                  //
               end 
               //
         end 
       DATA_WRITE: 
         begin
                                            state_next = IDLE;
         end 
       DATA_READ_COMMAND_SEND:
         begin
                                            state_next = DATA_READ;                        
           
         end 
       DATA_READ: 
         begin
                                            state_next = BROADCAST;
            // BROADCAST SIGNALS                                 
            broadcast_ready_next     = 1'b1;         // Broadcast Data Ready 
            broadcast_rob_addr_next  = rob_addr_reg; // Broadcast ROB Addr 
            broadcast_load_data_next = wrd_rdata;    // Broadcast Data                                 
         end 
         
       WRITE_BACK_MEM_COMMAND:
         begin
            // WRITE BACK EXTERNAL MEMORY SIGNALS 
            exmem_cs_next            = '0;         
            exmem_write_read_next    = '0; // WRITE    
            exmem_addr_next          = '0;         
            exmem_write_data_next    = '0;   
            exmem_write_data_v_next  = '0;           
         
         
            // Wait for the External Memory to be Ready to Receive Data. 
            if(exmem_write_ready)
            begin
            // External Memory is Ready to Receive Data 
                                            state_next = WRITE_BACK_MEM;    
            // Start the Burst Write in Cache.                                 
               burst_start_next   = 1'b1; 
               burst_wr_next      = 1'b0;                // READ CACHE/WRITE TO EXTERNAL MEMORY    
               burst_addr_next    = write_back_addr_reg; // The Address to Read from Cache wnd write back the the memory.  
               burst_line_no_next = hit_line_no_reg;     // The Line to read from the cache and write back to the memory.                                        
            end 
         end    
       WRITE_BACK_MEM:
         begin
            // READ A LINE FROM THE CACHE AND WRITE TO THE MEMORY 
            burst_start_next        = '0; 
            burst_addr_next         = '0;     
            burst_line_no_next      = '0;
            exmem_write_data_next   = burst_rdata; 
            exmem_write_data_v_next = burst_rv;    
            // Wait for the Cache READ to complete 
            if(burst_done)
            begin
                                            state_next = IDLE;    
               // Start the Burst Write in Cache.                                 
               burst_start_next   = 1'b1; 
               burst_wr_next      = 1'b1;                // READ Memory & Write to the Cache   
               burst_addr_next    = write_back_addr_reg; // The Address to Read from Cache wnd write back the the memory.  
               burst_line_no_next = hit_line_no_reg;     // The Line to read from the cache and write back to the memory.                                                                                         
            end 
            //
         end 
       READ_MEM:
         begin
        // READ A BLOCK FROM THE MEMORY AND WRITE IT TO THE CACHE 
        
         end 
       BROADCAST:
         begin
            //
            if(i_broadcast_en)
            begin
                                            state_next = IDLE;            
               // BROADCAST SIGNALS                                 
               broadcast_ready_next     = 1'b0;         // Broadcast Data Ready 
               broadcast_rob_addr_next  = '0; // Broadcast ROB Addr 
               broadcast_load_data_next = '0;    // Broadcast Data   
            end 
            //
         end 
    endcase 



end 




//============================
// STATE REGISTER 
//============================
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      state <= IDLE;
   end else begin
      state <= state_next;
   end 
end 


//============================
// REGISTERS 
//============================
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      // CACHE INPUT SIGNALS 
      hit_check     <= '0;
      hit_addr      <= '0;
      wrd_en        <= '0;
      wrd_wr        <= '0;
      wrd_line_no   <= '0;
      wrd_addr      <= '0;
      wrd_size      <= '0;
      wrd_wdata     <= '0;        
      burst_start   <= '0;
      burst_wr      <= '0;
      burst_addr    <= '0;
      burst_line_no <= '0;
      burst_wdata   <= '0;
      burst_wv      <= '0;
      // INPUT REGISTERS 
      rob_addr_reg   <= '0;  
      addr_reg       <= '0;         
      rob_addr_reg   <= '0;        
      load_store_reg <= '0;     
      store_data_reg <= '0;    
      size_reg       <= '0;     
      signed_unsigned_reg <= '0;
      //
      o_broadcast_ready     <= '0; // Broadcast Data Ready 
      o_broadcast_rob_addr  <= '0; // Broadcast ROB Addr 
      o_broadcast_load_data <= '0; // Broadcast Data   
      //
      exmem_cs           <= '0;
      exmem_write_read   <= '0;
      exmem_addr         <= '0;
      exmem_write_data   <= '0;
      exmem_write_data_v <= '0;
      //
      hit_line_no_reg     <= '0;
      write_back_addr_reg <= '0;
   end else begin
      // CACHE INPUT REGISTERS  
      hit_check     <= hit_check_next;   
      hit_addr      <= hit_addr_next;     
      wrd_en        <= wrd_en_next;      
      wrd_wr        <= wrd_wr_next;      
      wrd_line_no   <= wrd_line_no_next; 
      wrd_addr      <= wrd_addr_next;    
      wrd_size      <= wrd_size_next;    
      wrd_wdata     <= wrd_wdata_next;            
      burst_start   <= burst_start_next; 
      burst_wr      <= burst_wr_next;    
      burst_addr    <= burst_addr_next;  
      burst_line_no <= burst_line_no_next;
      burst_wdata   <= burst_wdata_next; 
      burst_wv      <= burst_wv_next; 
      // INPUT REGISTERS 
      rob_addr_reg   <= rob_addr_next;         
      addr_reg       <= addr_next;             
      rob_addr_reg   <= rob_addr_next;          
      load_store_reg <= load_store_next;        
      store_data_reg <= store_data_next;        
      size_reg       <= size_next;        
      signed_unsigned_reg <= signed_unsigned_next; 
      // BROADCAST SIGNALS 
      o_broadcast_ready     <= broadcast_ready_next;     // Broadcast Data Ready 
      o_broadcast_rob_addr  <= broadcast_rob_addr_next;  // Broadcast ROB Addr 
      o_broadcast_load_data <= broadcast_load_data_next; // Broadcast Data
      //
      exmem_cs           <= exmem_cs_next;         
      exmem_write_read   <= exmem_write_read_next;   
      exmem_addr         <= exmem_addr_next;         
      exmem_write_data   <= exmem_write_data_next;   
      exmem_write_data_v <= exmem_write_data_v_next;
      //
      hit_line_no_reg    <= hit_line_no_next;
      //
      write_back_addr_reg <= write_back_addr_next;  
   end 
end 

//=============================
// CACHE INSTANTIATION
//=============================
CACHE 
#( .LINEWORDSIZE (BLOCKWORDSIZE),  // Number of Words(32-bit) in each MemoryBlock/CacheLine 
   .CACHESETSIZE (CACHESETSIZE),  // Number of Sets in Cache  
   .CACHEWAYSIZE (CACHEWAYSIZE))
uCACHE
(
   .clk               (clk),          // CLOCK
   .rstn              (rstn),         // ACTIVE LOW ASYNCHRONOUS RESET
   // CACHE HIT CHECK 
   .i_hit_check       (hit_check),    // Check Hit Enable 
   .i_hit_addr        (hit_addr),     // Address to check the cache hit
   .o_hit             (hit),           // 1: Cache Hit 0:Cache Miss
   .o_hit_line_no     (hit_line_no),  // o_hit==1: The line that hits, 
                                    // o_hit==0: The line that we should write the block from memory.
   .o_hit_line_v      (hit_line_v),   // 1: Hit line is Valid 0: Hit line is NOT Valid 
   .o_hit_line_d      (hit_line_d),   // 1: Hit Line is Dirty 0: Hit line is NOT Dirty
   .o_write_back_addr (write_back_addr), // TAG NUMBER of the Line to return Back   
   // WRITE READ DATA 
   .i_wrd_en          (wrd_en),       // Write Read Data Enable  
   .i_wrd_wr          (wrd_wr),       // 1:Write 0:Read  
   .i_wrd_line_no     (wrd_line_no),  // Write Read Data Line Number 
   .i_wrd_addr        (wrd_addr),     // Write Read Data Address 
   .i_wrd_size        (wrd_size),     // Write Read Data Size  
   .i_wrd_wdata       (wrd_wdata),    // Write Read Data Write Data 
   .o_wrd_rdata       (wrd_rdata),    // Write Read Data Read Data 
   // Write Read Line 
   .i_burst_start     (burst_start),  // Start the Burst 
   .i_burst_wr        (burst_wr),     // 1: Write Burst 0: Read Burst 
   .i_burst_addr      (burst_addr),   // Burst Start Address
   .i_burst_line_no   (burst_line_no),// Line to Read/Write  
   .i_burst_wdata     (burst_wdata),  // 32-bit Value to Write 
   .o_burst_wready    (burst_wready), // Cache is Ready to Receive Data for Write 
   .o_burst_rdata     (burst_rdata),  // 32-bit Value to Read 
   .i_burst_wv        (burst_wv),     // burst_wdata valid,
   .o_burst_rv        (burst_rv),      // burst_rdata valid
   .o_burst_done      (burst_done) 
    ); 



//=============================
// EXTERNAL MEMORY INSTANTIATION
//=============================
EXTERNAL_MEMORY
#( .BLOCKSIZE     (BLOCKSIZE),      // Number of Blocks 
   .BLOCKWORDSIZE (BLOCKWORDSIZE) ) // Number of Words(32-bit) in each Block  
uEXTERNAL_MEMORY
(
   .clk            (clk),               // Clock    
   .rstn           (rstn),              // Active low Asyncronous Reset 
   .i_cs           (exmem_cs),          // CHIP SELECT  
   .i_write_read   (exmem_write_read),  // 1:Write 0:Read 
   .i_addr         (exmem_addr),        // READ/WRITE ADDR 
   .i_write_data   (exmem_write_data),  // WRITE DATA WORD
   .i_write_data_v (exmem_write_data_v),// WRITE DATA VALID
   .o_read_data    (exmem_read_data),   // READ DATA WORD 
   .o_read_data_v  (exmem_read_data_v), // READ DATA VALID 
   .o_write_ready  (exmem_write_ready), // READY TO RECIVE DATA  
   .o_burst_done   (exmem_burst_done)   // BURST IS DONE 
    );



    
    
endmodule : DCACHE_CONTROLLER




//==================================
// DCACHE_CONTROLLER TEST BENCH 
//==================================
module DCACHE_CONTROLLER_tb();

parameter ROBSIZE=8;
parameter BLOCKSIZE     = 64; // Number of Blocks in External Memory  
parameter BLOCKWORDSIZE = 4;  // Number of Words(32-bit) in each MemoryBlock/CacheLine 
parameter CACHESETSIZE  = 4;  // Number of Sets in Cache  
parameter CACHEWAYSIZE  = 4;  // Number of Lines in Each Cache Set 

localparam CACHEOFFSETADDRSIZE =  $clog2(BLOCKWORDSIZE*4);
localparam CACHESETADDRSIZE    =  $clog2(CACHESETSIZE); 
localparam CACHETAGADDRSIZE    =  32-(CACHESETADDRSIZE+CACHEOFFSETADDRSIZE);


logic                         clk;
logic                         rstn; 
logic                         i_cs;                 // CHIP SELECT
logic [31:0]                  i_addr;               // Memory Address 
logic [$clog2(ROBSIZE):0]     i_rob_addr;           // ROB Addr
logic                         i_load_store;         // LOAD OR STORE COMMAND 
logic [31:0]                  i_store_data;         // Store Data 
logic [1:0]                   i_size;               // Data Size-Byte|Half-Word|Word
logic                         i_signed_unsigned;    // Signed|Unsigned 
// 
logic                         i_broadcast_en;        // Broadcast Enable 
logic                         o_broadcast_ready;     // Broadcast Data Ready 
logic [$clog2(ROBSIZE):0]     o_broadcast_rob_addr;  // Broadcast ROB Addr 
logic [31:0]                  o_broadcast_load_data; // Broadcast Data 
//
logic                         o_mem_busy;            //Memory Busy Flag  
//
int error;
int test_cnt;


//=====================
// CLOCK GENERATION
//=====================
initial begin
   clk = 1'b0;
   forever #10 clk = ~clk;
end 

//=====================
// RESET GENERATION
//=====================
task RESET();
begin
   i_cs              <= '0;
   i_addr            <= '0;
   i_rob_addr        <= '0;
   i_load_store      <= '0;
   i_store_data      <= '0;
   i_size            <= '0;
   i_signed_unsigned <= '0;
   i_broadcast_en    <= '0;
   //
   rstn = 1'b1;
   @(posedge clk);
   rstn = 1'b0;
   repeat(2)@(posedge clk);
   rstn = 1'b1;
end 
endtask 


//==============================
// STORE TASK 
//==============================
task STORE(
   input logic [(CACHETAGADDRSIZE-1):0]    tag,
   input logic [(CACHESETADDRSIZE-1):0]    index,
   input logic [(CACHEOFFSETADDRSIZE-1):0] offset,
   input logic [$clog2(ROBSIZE):0]         rob_addr,
   input logic [31:0]                      store_data,
   input logic [1:0]                       size,
   input logic                             signed_unsigned
);
begin
        wait(~o_mem_busy)
        @(posedge clk);
          i_cs              <= 1'b1;
          i_addr            <= {tag,index,offset};
          i_rob_addr        <= rob_addr;
          i_load_store      <= 1'b1;
          i_store_data      <= store_data;
          i_size            <= size;
          i_signed_unsigned <= signed_unsigned;  
        @(posedge clk);          
          i_cs              <= '0;
          i_addr            <= '0;
          i_rob_addr        <= '0;
          i_load_store      <= '0;
          i_store_data      <= '0;
          i_size            <= '0;
          i_signed_unsigned <= '0; 
end 
endtask




//==============================
// LOAD TASK 
//==============================
task LOAD(
   input logic [(CACHETAGADDRSIZE-1):0]    tag,
   input logic [(CACHESETADDRSIZE-1):0]    index,
   input logic [(CACHEOFFSETADDRSIZE-1):0] offset,
   input logic [31:0]                      ex_data,
   input logic [$clog2(ROBSIZE):0]         rob_addr,
   input logic [1:0]                       size,
   input logic                             signed_unsigned
);
begin 
        wait(~o_mem_busy)
        @(posedge clk);
          i_cs              <= 1'b1;
          i_addr            <= {tag,index,offset};
          i_rob_addr        <= rob_addr;
          i_load_store      <= 1'b0;
          i_store_data      <= '0;
          i_size            <= size;
          i_signed_unsigned <= signed_unsigned; 
        @(posedge clk);          
          i_cs              <= '0;
          i_addr            <= '0;
          i_rob_addr        <= '0;
          i_load_store      <= '0;
          i_store_data      <= '0;
          i_size            <= '0;
          i_signed_unsigned <= '0; 
        wait(o_broadcast_ready)
        @(posedge clk);  
        if(o_broadcast_load_data != ex_data) error++;
        i_broadcast_en = 1'b1;
        @(posedge clk);
        i_broadcast_en = 1'b0;  
end 
endtask


logic [(CACHETAGADDRSIZE-1):0] RANDOM_TAG [(CACHEWAYSIZE-1):0];
logic [31:0]                   RANDOM_DATA [(CACHEWAYSIZE-1):0];
int wordnum;


//============================================
// TEST 1 
//============================================
// 1- INITIALIZE THE MEMORY TO HAVE A CACHE-HIT 
// 2- WRITE A 32-bit 32'hDEADBEEF to "offset" of all the lines of the "set"    
task test1(input int set = 0, 
           input logic [(CACHEOFFSETADDRSIZE-1):0] offset ='0 );
begin
   error    = '0;
   test_cnt++;
   //
   RESET();
   // MAKE ALL THE LINES OF SET0 VALID/ 
   for(int i=0;i<CACHEWAYSIZE;i++)
   begin
      uDCACHE_CONTROLLER.uCACHE.T_LINE_VALID[set][i] =  1'b1;
      RANDOM_TAG[i] = $random;
      uDCACHE_CONTROLLER.uCACHE.T_LINE_TAG[set][i]   = RANDOM_TAG[i]; 
   end 
   //
   for(int i=0;i<CACHEWAYSIZE;i++)
   begin
      STORE( .tag (RANDOM_TAG[i]),.index (set),.offset (offset),  .rob_addr (5), .store_data (32'hDEADBEEF), .size (2'b10), .signed_unsigned (1'b0));
   end 
   // WRITE CHECK 
   wait(o_mem_busy);
   repeat(3)@(posedge clk);
   for(int i=0;i<CACHEWAYSIZE;i++)
   begin
      if(uDCACHE_CONTROLLER.uCACHE.T_CACHE_DATA[set][i][(offset>>2)] != 'hDEADBEEF) error++;
   end
    
   //
   if(error==0) $display("TEST %d PASSED",test_cnt);
   else         $display("TEST %d FAILED. %d ERRORS",test_cnt,error);
end 
endtask 




//============================================
// TEST 2 
//============================================
// 1- INITIALIZE THE MEMORY TO HAVE A CACHE-HIT 
// 2- WRITE A 32-bit DATA TO THE MEMORY AND THEN READ IT   
task test2(input int set = 0, 
           input logic [(CACHEOFFSETADDRSIZE-1):0] offset ='0 );
begin
   error    = '0;
   test_cnt++;
   //
   RESET();
   // MAKE ALL THE LINES OF SET0 VALID/ 
   for(int i=0;i<CACHEWAYSIZE;i++)
   begin
      uDCACHE_CONTROLLER.uCACHE.T_LINE_VALID[set][i] =  1'b1;
      RANDOM_TAG[i] = $random;
      uDCACHE_CONTROLLER.uCACHE.T_LINE_TAG[set][i]   = RANDOM_TAG[i]; 
      RANDOM_DATA[i] =$random;
   end 
   // WRITE TO MEMORY 
   for(int i=0;i<CACHEWAYSIZE;i++)
   begin
      STORE( .tag (RANDOM_TAG[i]),.index (set),.offset (offset),  .rob_addr (5), .store_data (RANDOM_DATA[i]), .size (2'b10), .signed_unsigned (1'b0));
   end 
   // READ FROM THE MEMORY 
   for(int i=0;i<CACHEWAYSIZE;i++)
   begin
      LOAD ( .tag (RANDOM_TAG[i]),.index (set),.offset (offset), .ex_data (RANDOM_DATA[i]), .rob_addr (5), .size (2'b10),.signed_unsigned (1'b0));
   end 
   //
   wait(o_mem_busy);
   repeat(3)@(posedge clk);
   //
   if(error==0) $display("TEST %d PASSED",test_cnt);
   else         $display("TEST %d FAILED. %d ERRORS",test_cnt,error);
end 
endtask 

 //       line_row        Line_column                 set                line    
 logic [(BLOCKWORDSIZE-1):0][31:0]  RANDOM_CACHE_DATA [(CACHESETSIZE-1):0][(CACHEWAYSIZE-1):0]; 
//============================================
// TEST 3 
//============================================
// 1- INITIALIZE THE MEMORY TO HAVE A CACHE-MISS(ALL VALID-NO TAG HIT- LRU line is Dirty Line)
// 2- CHOOSE THE LRU LINE and Write it Back to the Memory 
// 3- Read the Memory and bring the Block we want
// 4- Write the Data to the Memory 
task test3(input int set = 0, 
           input logic [(CACHEOFFSETADDRSIZE-1):0] offset ='0 );
begin
   error    = '0;
   test_cnt++;
   //
   RESET();
   // MAKE ALL THE LINES OF SET0 VALID/ 
   for(int i=0;i<CACHEWAYSIZE;i++)
   begin
      uDCACHE_CONTROLLER.uCACHE.T_LINE_VALID[set][i] =  1'b1;
      uDCACHE_CONTROLLER.uCACHE.T_LINE_DIRTY[set][i] =  1'b1;
      RANDOM_TAG[i] = $random;
      uDCACHE_CONTROLLER.uCACHE.T_LINE_TAG[set][i]   = RANDOM_TAG[i]; 

   end 

   
   for(int i0=0;i0<CACHESETSIZE;i0++)
   begin   
      for(int i1=0;i1<CACHEWAYSIZE;i1++)
      begin   
         for(int i2=0;i2<BLOCKWORDSIZE;i2++)
         begin
            RANDOM_CACHE_DATA[i0][i1][i2] = $random;
            uDCACHE_CONTROLLER.uCACHE.T_CACHE_DATA[i0][i1][i2] = RANDOM_CACHE_DATA[i0][i1][i2];
         end       
      end
   end        
   
   // WRITE TO THE CACHE 
   STORE( .tag ('hFFFFF),.index (set),.offset (offset),  .rob_addr (5), .store_data (32'hDEADBEEF), .size (2'b10), .signed_unsigned (1'b0));
   //
   wait(o_mem_busy);
   repeat(3)@(posedge clk);
   //
   if(error==0) $display("TEST %d PASSED",test_cnt);
   else         $display("TEST %d FAILED. %d ERRORS",test_cnt,error);
end 
endtask 







initial begin
   //
   //test1(.set (1), .offset ('d4));
   //test2(.set (0), .offset ('d0));
   test3(.set (0), .offset ('d0));



   $finish;
end  



//===========================
// DUT Instantiation 
//===========================
DCACHE_CONTROLLER #(.ROBSIZE       (ROBSIZE),
                    .BLOCKSIZE     (BLOCKSIZE),
                    .BLOCKWORDSIZE (BLOCKWORDSIZE),
                    .CACHESETSIZE  (CACHESETSIZE),
                    .CACHEWAYSIZE  (CACHEWAYSIZE) ) uDCACHE_CONTROLLER (.*);
    

endmodule 


