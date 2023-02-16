`timescale 1ns / 1ps
// N-Way Set Associative Cache 

// TODO: Take Only One Addr instead of hit_addr,wrd_addr, burst_addr  
// TODO: Fix the Write/Read DATA Based on the Size problem 
 
//imm[11:0] rs1 000 rd 0000011 LB
//imm[11:0] rs1 001 rd 0000011 LH
//imm[11:0] rs1 010 rd 0000011 LW
//imm[11:0] rs1 100 rd 0000011 LBU
//imm[11:0] rs1 101 rd 0000011 LHU
//imm[11:5] rs2 rs1 000 imm[4:0] 0100011 SB
//imm[11:5] rs2 rs1 001 imm[4:0] 0100011 SH
//imm[11:5] rs2 rs1 010 imm[4:0] 0100011 SW






module CACHE
#(parameter LINEWORDSIZE  = 4,  // Number of Words(32-bit) in each MemoryBlock/CacheLine 
  parameter CACHESETSIZE  = 4,  // Number of Sets in Cache  
  parameter CACHEWAYSIZE  = 4)  // Number of Lines in each Set 
(
   input logic         clk, 
   input logic         rstn,
   // CACHE HIT CHECK 
   input  logic        i_hit_check,     // Check Hit Enable 
   input  logic [31:0] i_hit_addr,      // Address to check the cache hit
   output logic        o_hit,           // 1: Cache Hit 0:Cache Miss
   output logic [($clog2(CACHEWAYSIZE)-1):0]  o_hit_line_no,   // o_hit==1: The line that hits, 
                                        // o_hit==0: The line that we should write the block from memory.
   output logic        o_hit_line_v,    // 1: Hit line is Valid 0: Hit line is NOT Valid 
   output logic        o_hit_line_d,    // 1: Hit Line is Dirty 0: Hit line is NOT Dirty 
   output logic [31:0] o_write_back_addr,  // The External_memory_block that we need to write back   
   // WRITE READ DATA 
   input  logic        i_wrd_en,        // Write Read Data Enable  
   input  logic        i_wrd_wr,        // 1:Write 0:Read  
   input  logic [($clog2(CACHEWAYSIZE)-1):0]  i_wrd_line_no,   // Write Read Data Line Number 
   input  logic [31:0] i_wrd_addr,      // Write Read Data Address 
   input  logic [1:0]  i_wrd_size,      // Write Read Data Size  
   input  logic [31:0] i_wrd_wdata,     // Write Read Data Write Data 
   output logic [31:0] o_wrd_rdata,     // Write Read Data Read Data 
   // Write Read Line 
   input  logic        i_burst_start,   // Start the Burst 
   input  logic        i_burst_wr,      // 1: Write Burst 0: Read Burst 
   input  logic [31:0] i_burst_addr,    // Burst Start Address
   input  logic [($clog2(CACHEWAYSIZE)-1):0]  i_burst_line_no, // Line to Read/Write  
   input  logic [31:0] i_burst_wdata,    // 32-bit Value to Write 
   input  logic        i_burst_wv,       // burst_wdata valid,
   output logic        o_burst_wready,   // Flag that shows it is ready to recive data  
   output logic [31:0] o_burst_rdata,    // 32-bit Value to Read 
   output logic        o_burst_rv,       // burst_rdata valid
   output logic        o_burst_done      
    );
 
localparam CACHEOFFSETADDRSIZE =  $clog2(LINEWORDSIZE*4);
localparam CACHESETADDRSIZE    =  $clog2(CACHESETSIZE); 
localparam CACHETAGADDRSIZE    =  (32-(CACHESETADDRSIZE+CACHEOFFSETADDRSIZE));  // Number of Lines in Each Set 
    
    
 // CACHE MEMORY
 // cache_mem[set][line][line_row][line_column]
 //       line_row        Line_column                 set                line    
 logic [(LINEWORDSIZE-1):0][31:0]  T_CACHE_DATA [(CACHESETSIZE-1):0][(CACHEWAYSIZE-1):0]; 
 //                                                 set                 line
 logic                             T_LINE_VALID [(CACHESETSIZE-1):0][(CACHEWAYSIZE-1):0]; 
 logic                             T_LINE_DIRTY [(CACHESETSIZE-1):0][(CACHEWAYSIZE-1):0]; 
 //     tag                                         set                 line
 logic [(CACHETAGADDRSIZE-1):0]    T_LINE_TAG   [(CACHESETSIZE-1):0][(CACHEWAYSIZE-1):0]; 
  
 
 // LOCAL SIGNALS 
 logic [(CACHEOFFSETADDRSIZE-1):0]  hit_offset;  
 logic [(CACHESETADDRSIZE-1):0]     hit_index;  
 logic [(CACHETAGADDRSIZE-1):0]     hit_tag;
 logic all_valid;
 logic invalid_found; 
 // 
 logic [(CACHEOFFSETADDRSIZE-1):0]  wrd_offset;  
 logic [(CACHESETADDRSIZE-1):0]     wrd_index;  
 logic [(CACHETAGADDRSIZE-1):0]     wrd_tag; 
 //   
 logic [(CACHEOFFSETADDRSIZE-1):0]  burst_offset;  
 logic [(CACHESETADDRSIZE-1):0]     burst_index, burst_index_reg;  
 logic [(CACHETAGADDRSIZE-1):0]     burst_tag; 
 //
 logic [(LINEWORDSIZE):0]            burst_addr_cnt;
 logic [($clog2(CACHEWAYSIZE)-1):0]  burst_line_no_reg;
 //            line_no                                    set   
 logic [($clog2(CACHEWAYSIZE)-1):0]  lru_line_no [(CACHESETSIZE-1):0];
 //             cnt                                        set                line 
 logic [($clog2(CACHEWAYSIZE)-1):0]  lru_cnts    [(CACHESETSIZE-1):0][(CACHEWAYSIZE-1):0];


//============================================
// TAG-INDEX-OFFSET Assignment  
//============================================ 
assign hit_offset   = i_hit_addr[(CACHEOFFSETADDRSIZE-1):0];  
assign hit_index    = i_hit_addr[(CACHESETADDRSIZE+CACHEOFFSETADDRSIZE-1):CACHEOFFSETADDRSIZE];  
assign hit_tag      = i_hit_addr[31:(CACHESETADDRSIZE+CACHEOFFSETADDRSIZE)];  
//
assign wrd_offset   = i_wrd_addr[(CACHEOFFSETADDRSIZE-1):0];  
assign wrd_index    = i_wrd_addr[(CACHESETADDRSIZE+CACHEOFFSETADDRSIZE-1):CACHEOFFSETADDRSIZE];  
assign wrd_tag      = i_wrd_addr[31:(CACHESETADDRSIZE+CACHEOFFSETADDRSIZE)];  
// 
assign burst_offset = i_burst_addr[(CACHEOFFSETADDRSIZE-1):0];  
assign burst_index  = i_burst_addr[(CACHESETADDRSIZE+CACHEOFFSETADDRSIZE-1):CACHEOFFSETADDRSIZE];  
assign burst_tag    = i_burst_addr[31:(CACHESETADDRSIZE+CACHEOFFSETADDRSIZE)];   
    


//============================================
// Least Recently Used (LRU) Algorithm for Cache Lines  
//============================================
// UPDATE LRU COUNTS 
always_ff @(posedge clk or negedge rstn)
begin

   if(!rstn)
   begin
      //
      for(int set_indx0=0;set_indx0<CACHESETSIZE;set_indx0++)
      begin
         for(int line_indx0=0;line_indx0<CACHEWAYSIZE;line_indx0++)
         begin
            lru_cnts[set_indx0][line_indx0] = line_indx0;    
         end 
      end 
      //
   end else begin
      // UPDATE LEAST RECENTLY USED COUNTERS 
      if(i_wrd_en) 
      begin
         lru_cnts[wrd_index][i_wrd_line_no] <= (CACHEWAYSIZE-1);
         for(int i4=0;i4<CACHEWAYSIZE;i4++)
         begin
            if(lru_cnts[wrd_index][i4] > lru_cnts[wrd_index][i_wrd_line_no] )
            begin
               lru_cnts[wrd_index][i4] <= lru_cnts[wrd_index][i4] - 1;
            end 
         end 
      end 
      
      // 
   end 
end 

//FIND THE LEAST RECENTLY USED LINES (IF LRU Counter == 0 --> It is the LRU Line)
always_comb
begin 
   for(int i2=0;i2<CACHESETSIZE;i2++)
   begin
      for(int i3=0;i3<CACHEWAYSIZE;i3++)
      begin
         if(lru_cnts[i2][i3] == 'd0)
         begin
            lru_line_no[i2] = i3; // Least Recently Used Line of the Set i2 is i3. 
         end   
      end 
   end 
end 







//============================================
// FUNCTION1: CACHE HIT CHECK 
//============================================
always_comb
begin
   o_hit         = '0;
   o_hit_line_no = '0;
   all_valid     = 1'b1;  
   invalid_found = '0;
   o_hit_line_v  = '0; 
   o_hit_line_d  = '0; 
   o_write_back_addr= '0; 
   // HIT CHECK 
   if(i_hit_check)
   begin
	   for(int i =0;i<CACHEWAYSIZE;i++)
	   begin
		   if((T_LINE_TAG[hit_index][i]==hit_tag) && (T_LINE_VALID[hit_index][i]==1'b1) )
		   begin
			  o_hit = 1'b1;
			  o_hit_line_no = i;
			  o_hit_line_v  = T_LINE_VALID[hit_index][o_hit_line_no];
			  o_hit_line_d  = T_LINE_DIRTY[hit_index][o_hit_line_no];          
		   end 
	   end 
	  //
	  // IF IT IS A CACHE-MISS, RETURN LINE NUMBER TO WRITE THE INCOMING BLOCK.  
	  if(o_hit == 1'b0)
	  begin
		 // CHECK IF ALL THE LINES IN THE INDEX-hit_index are valid 
		 for(int i =0;i<CACHEWAYSIZE;i++)
		 begin
			all_valid = all_valid & T_LINE_VALID[hit_index][i];
		 end 
		 //
		 // IF ALL LINES ARE VALID --> Return the LRU Line_no 
		 if(all_valid)
		 begin
			 o_hit_line_no     = lru_line_no[hit_index]; 
			 o_hit_line_v      = T_LINE_VALID[hit_index][o_hit_line_no];
			 o_hit_line_d      = T_LINE_DIRTY[hit_index][o_hit_line_no];
			 o_write_back_addr = {T_LINE_TAG[hit_index][o_hit_line_no],hit_index,hit_offset};
		 end else begin
			// IF THERE IS AT LEAST ONE INVALID LINE --> Return the First Invalid line_no   
			for(int i =0;i<CACHEWAYSIZE;i++)
			begin
			   if((T_LINE_VALID[hit_index][i] == 1'b0) && ~invalid_found)
			   begin
				  o_hit_line_no  = i;
				  o_hit_line_v   = T_LINE_VALID[hit_index][o_hit_line_no];
				  o_hit_line_d   = T_LINE_DIRTY[hit_index][o_hit_line_no];
				  o_write_back_addr = {T_LINE_TAG[hit_index][o_hit_line_no],hit_index,hit_offset};
				  invalid_found = 1'b1;
			   end 
			end 
			//
		 end
		 //
	end
  end 
  
end 









//=====================================
// FUNCTION2 / FUNCTION3 : WRITE-READ-DATA /  
//=====================================
//=====================================
// Write Signal Generation 
//=====================================
// SIZE[2]  SIZE[1]  SIZE[0] 
//   0        0       0      BYTE  
//   0        0       1      HALFWORD 
//   0        1       0      WORD 
wire wrd_byte      =  ~i_wrd_size[1]& ~i_wrd_size[0]; 
wire wrd_half_word =  ~i_wrd_size[1]&  i_wrd_size[0]; 
wire wrd_word      =   i_wrd_size[1]& ~i_wrd_size[0];

wire byte_00 = wrd_byte & ~wrd_offset[1] & ~wrd_offset[0];
wire byte_01 = wrd_byte & ~wrd_offset[1] &  wrd_offset[0];
wire byte_10 = wrd_byte &  wrd_offset[1] & ~wrd_offset[0];
wire byte_11 = wrd_byte &  wrd_offset[1] &  wrd_offset[0];

wire half_word_00_01 = wrd_half_word & ~wrd_offset[1];
wire half_word_10_11 = wrd_half_word &  wrd_offset[1];

wire byte0 = wrd_word | half_word_00_01 | byte_00;
wire byte1 = wrd_word | half_word_00_01 | byte_01;
wire byte2 = wrd_word | half_word_10_11 | byte_10;
wire byte3 = wrd_word | half_word_10_11 | byte_11;


 

typedef enum{
     BURST_IDLE,
     BURST_READ,
     BURST_WRITE
    } burst_state_type;

burst_state_type burst_state;


// WRITE REGISTER BLOCK 
always_ff @(posedge clk or negedge rstn)
begin
   if(!rstn)
   begin
      // BURST STATE RESET 
      burst_state       <= BURST_IDLE;
      burst_addr_cnt    <= '0;
      o_burst_rv        <= '0;
      burst_index_reg   <= '0;
      burst_line_no_reg <= '0;
      o_burst_rdata     <= '0;
      o_burst_done      <= '0; 
      o_burst_wready    <= '0;    
      //
      for(int i0 = 0; i0<CACHESETSIZE;i0++)  // SET 
      begin
         for(int i1 = 0; i1<CACHEWAYSIZE;i1++) // LINE 
         begin
            T_LINE_VALID[i0][i1] = '0;
            T_LINE_DIRTY[i0][i1] = '0;
            T_LINE_TAG[i0][i1]   = '0;
            T_CACHE_DATA[i0][i1] = '0;
         end
      end 
   end else begin
      //DATA WRITE  
      
      case(burst_state)
         BURST_IDLE:
         begin
          o_burst_rv     <= 1'b0;
          o_burst_done   <= 1'b0;
		  if(i_wrd_en)
		  begin
			 //
			 if(i_wrd_wr)
			 begin
			    // Make the Line Dirty. 
			    T_LINE_DIRTY[wrd_index][i_wrd_line_no] <= 1'b1;
				// DATA WRITE 
				if(byte0)
				   T_CACHE_DATA[wrd_index][i_wrd_line_no][wrd_offset[(CACHEOFFSETADDRSIZE-1):2]][7:0]   <= i_wrd_wdata[7:0];
				if(byte1)
				   T_CACHE_DATA[wrd_index][i_wrd_line_no][wrd_offset[(CACHEOFFSETADDRSIZE-1):2]][15:8]  <= i_wrd_wdata[15:8];
				if(byte2)
				   T_CACHE_DATA[wrd_index][i_wrd_line_no][wrd_offset[(CACHEOFFSETADDRSIZE-1):2]][23:16] <= i_wrd_wdata[23:16];
				if(byte3)
				   T_CACHE_DATA[wrd_index][i_wrd_line_no][wrd_offset[(CACHEOFFSETADDRSIZE-1):2]][31:24] <= i_wrd_wdata[31:24];
			 end else begin
			 // DATA READ 
			 // TODO: READ BASED ON THE SIZE 
				   o_wrd_rdata <= T_CACHE_DATA[wrd_index][i_wrd_line_no][wrd_offset[(CACHEOFFSETADDRSIZE-1):2]];
			 end  
			 //    
		  end else if (i_burst_start)
		  begin
		     //
		     burst_index_reg   <= burst_index;
		     burst_line_no_reg <= i_burst_line_no; 
		     //
		     if(i_burst_wr)
		     begin
		        T_LINE_TAG[burst_index][i_burst_line_no]   <= burst_tag;
		        T_LINE_VALID[burst_index][i_burst_line_no] <= 1'b1;
		        burst_state    <= BURST_WRITE;
		        o_burst_wready <= 1'b1;
		     end else begin
		        T_LINE_VALID[burst_index][i_burst_line_no] <= 1'b0;
		        burst_state <= BURST_READ;
		     end 
		  end 
		  ////
       end
       BURST_READ:
       begin
          //       
          o_burst_rdata <= T_CACHE_DATA[burst_index_reg][burst_line_no_reg][burst_addr_cnt];
          o_burst_rv    <= 1'b1;
          

          
          if(burst_addr_cnt == (LINEWORDSIZE-1))
          begin
             o_burst_done   <= 1'b1;
             burst_addr_cnt <= '0;
             burst_state    <= BURST_IDLE;
          end else begin
             burst_addr_cnt <= burst_addr_cnt + 'd1;
          end 
          //
       end 
       BURST_WRITE:
       begin
       // 
          if(i_burst_wv)
          begin
             T_CACHE_DATA[burst_index_reg][burst_line_no_reg][burst_addr_cnt] <= i_burst_wdata;
             if(burst_addr_cnt == (LINEWORDSIZE-1))
             begin
                o_burst_done   <= 1'b1;
                o_burst_wready <= 1'b0;
                burst_addr_cnt <= '0;
                burst_state    <= BURST_IDLE;
             end else begin
                burst_addr_cnt <= burst_addr_cnt + 'd1;
             end 
          end  
       //
       end 
      
      endcase 
      //
   end 
end 




    
    

    
endmodule :CACHE 




//========================================
// CACHE TEST BENCH 
//========================================
module CACHE_tb();



parameter ROBSIZE       = 8;  // Re-Order Buffer Size  
parameter LINEWORDSIZE  = 16; // Number of Words(32-bit) in each MemoryBlock/CacheLine 
parameter CACHESETSIZE  = 4;  // Number of Sets in Cache  
parameter CACHEWAYSIZE  = 8;  // Number of Lines in Each Set 


localparam CACHEOFFSETADDRSIZE =  $clog2(LINEWORDSIZE*4);
localparam CACHESETADDRSIZE    =  $clog2(CACHESETSIZE); 
localparam CACHETAGADDRSIZE    =  (32-(CACHESETADDRSIZE+CACHEOFFSETADDRSIZE)); // Number of Lines in Each Set 



logic         clk; 
logic         rstn;
// CACHE HIT CHECK 
logic        i_hit_check;     // Check Hit Enable 
logic [31:0] i_hit_addr;      // Address to check the cache hit
logic        o_hit;           // 1: Cache Hit 0:Cache Miss
logic [($clog2(CACHEWAYSIZE)-1):0]  o_hit_line_no;   // o_hit==1: The line that hits; 
                              // o_hit==0: The line that we should write the block from memory.
logic        o_hit_line_v;    // 1: Hit line is Valid 0: Hit line is NOT Valid 
logic        o_hit_line_d;    // 1: Hit Line is Dirty 0: Hit line is NOT Dirty
logic [31:0] o_write_back_addr;  // External Memory Address that the block should be written back to 
// WRITE READ DATA 
logic        i_wrd_en;        // Write Read Data Enable  
logic        i_wrd_wr;        // 1:Write 0:Read  
logic [($clog2(CACHEWAYSIZE)-1):0]  i_wrd_line_no;   // Write Read Data Line Number 
logic [31:0] i_wrd_addr;      // Write Read Data Address 
logic [1:0]  i_wrd_size;      // Write Read Data Size  
logic [31:0] i_wrd_wdata;     // Write Read Data Write Data  
logic [31:0] o_wrd_rdata;     // Write Read Data Read Data 
// Write Read Line 
logic        i_burst_start;   // Start the Burst 
logic        i_burst_wr;      // 1: Write Burst 0: Read Burst 
logic [31:0] i_burst_addr;    // Burst Start Address
logic [($clog2(CACHEWAYSIZE)-1):0]  i_burst_line_no; // Line to Read/Write  
logic [31:0] i_burst_wdata;   // 32-bit Value to Write 
logic [31:0] o_burst_rdata;   // 32-bit Value to Read 
logic        i_burst_wv;      // burst_wdata valid
logic        o_burst_rv;      // burst_rdata valid 
logic        o_burst_wready;  // BURST WRITE READY
//
logic        o_burst_done;
//
int error;
int test_cnt;
//========================= 
// CLOCK Generation 
//========================= 
initial begin
   clk = 1'b0;
   forever #10 clk = ~clk;
end 


//===============================
// RESET TASK 
//===============================
task RESET();
begin
   i_hit_check     = '0;     
   i_hit_addr      = '0;      
   i_wrd_en        = '0;        
   i_wrd_wr        = '0;        
   i_wrd_line_no   = '0;   
   i_wrd_addr      = '0;      
   i_wrd_size      = '0;      
   i_burst_start   = '0;   
   i_burst_wr      = '0;      
   i_burst_addr    = '0;    
   i_burst_line_no = '0; 
   i_burst_wdata   = '0;   
   i_burst_wv      = '0; 
   test_cnt        = '0;          
   //
   rstn = 1'b1;
   @(posedge clk);
   rstn = 1'b0;
   repeat(2)@(posedge clk);
   rstn = 1'b1;
   repeat(4) @(posedge clk);
end 
endtask 


//===============================
// FUNCTION1: CHECK HIT TASK 
//===============================
task check_hit(input logic [(CACHETAGADDRSIZE-1):0]     tag, 
               input logic [(CACHESETADDRSIZE-1):0]     index,
               input logic [(CACHEOFFSETADDRSIZE-1):0]  offset,
               input logic                              ex_hit,           // 1: Cache Hit 0:Cache Miss
               input logic [($clog2(CACHEWAYSIZE)-1):0] ex_hit_line_no,   // o_hit==1: The line that hits, 
                                                                          // o_hit==0: The line that we should write the block from memory.
               input logic                              ex_hit_line_v,    // 1: Hit line is Valid 0: Hit line is NOT Valid 
               input logic                              ex_hit_line_d);    // 1: Hit Line is Dirty 0: Hit line is NOT Dirty  
               
begin
   @(posedge clk);
      i_hit_check <= 1'b1;
      i_hit_addr  <= {tag,index,offset};
      // CHECK EXPECTED OUTPUT 
      #2
      if(o_hit != ex_hit)                begin  $display("HIT_FLAG ERROR: EXPECTED:%d ACTUAL:       ",ex_hit, o_hit);                  error++; end                 
      if(o_hit_line_no != ex_hit_line_no)begin  $display("HIT LINE NO ERROR: EXPECTED:%d ACTUAL:    ",ex_hit_line_no, o_hit_line_no);  error++; end 
      if(o_hit_line_v  != ex_hit_line_v) begin  $display("HIT LINE VALID ERROR: EXPECTED:%d ACTUAL: ",ex_hit_line_v, o_hit_line_v);    error++; end 
      if(o_hit_line_d  != ex_hit_line_d) begin  $display("HIT LINE DIRTY ERROR: EXPECTED:%d ACTUAL: ",ex_hit_line_d, o_hit_line_d);    error++; end 
   @(posedge clk);
      i_hit_check <= 1'b0;
      i_hit_addr  <= '0;
end 
endtask 


//======================================
// FUNCTION2: WRITE/READ DATA TO A CACHE LINE 
//======================================
task WRD(input  logic                               wrd_wr,
         input  logic [31:0]                        wrd_wdata = '0,
         input  logic [($clog2(CACHEWAYSIZE)-1):0]  wrd_line_no,
         input  logic [(CACHETAGADDRSIZE-1):0]      wrd_tag,
         input  logic [(CACHESETADDRSIZE-1):0]      wrd_index,
         input  logic [(CACHEOFFSETADDRSIZE-1):0]   wrd_offset,
         input  logic [1:0]                         wrd_size);
begin
   @(posedge clk);
      i_wrd_en      <= 1'b1;
      i_wrd_wdata   <= wrd_wdata;
      i_wrd_wr      <= wrd_wr;
      i_wrd_line_no <= wrd_line_no;
      i_wrd_addr    <= {wrd_tag,wrd_index,wrd_offset};
      i_wrd_size    <= wrd_size;
   @(posedge clk);
      i_wrd_en      <= '0;
      i_wrd_wr      <= '0;
      i_wrd_line_no <= '0;
      i_wrd_addr    <= '0;
      i_wrd_size    <= '0;  
end 
endtask 


//======================================
// FUNCTION4: BURST READ WRITE  
//======================================
task BURST(input  logic                               burst_wr,
           input  logic [(CACHETAGADDRSIZE-1):0]      tag, 
           input  logic [(CACHESETADDRSIZE-1):0]      index,
           input  logic [(CACHEOFFSETADDRSIZE-1):0]   offset,
           input  logic [($clog2(CACHEWAYSIZE)-1):0]  burst_line_no,
           input  int                                 burst_start_data='0                      
);
begin
   @(posedge clk);
   wait(uCACHE.burst_state == uCACHE.BURST_IDLE);
   @(posedge clk);
       i_burst_start   <= 1'b1;
       i_burst_wr      <= burst_wr;
       i_burst_addr    <= {tag,index,offset};
       i_burst_line_no <= burst_line_no;
       i_burst_wv      <= 1'b0; 
   @(posedge clk);
       i_burst_start   <= 1'b0;
       i_burst_wr      <= '0;
       i_burst_addr    <= '0;
       i_burst_line_no <= '0;
       //
       if(i_burst_wr)
       begin 
          for(int i0=0;i0<LINEWORDSIZE;i0++)
          begin
             @(posedge clk);
                i_burst_wdata <= burst_start_data + i0;
                i_burst_wv    <= 1'b1;
          end 
       end
       //
       @(posedge clk);
       i_burst_wv    <= 1'b0;   
            
end 
endtask


 logic [(CACHETAGADDRSIZE-1):0] RANDOM_TAGS [(CACHEWAYSIZE-1):0];
//======================================
// TEST 1 
//======================================
// CHECH HIT FUNCTION TEST1:
// Case: All the lines in the Set0 are Valid and we check if they hit. 
task test1();
begin
   RESET();
   test_cnt++;
   error = 0;
   
  
   
   // 1- Make all The Lines at the SET0 Valid 
   for(int i0=0;i0<CACHEWAYSIZE;i0++)
   begin
      uCACHE.T_LINE_VALID[0][i0] = 1'b1;
      RANDOM_TAGS[i0] = $random;
      uCACHE.T_LINE_TAG[0][i0] = RANDOM_TAGS[i0];
   end 
   
   // 
   repeat(2) @(posedge clk);
   
   for(int i0=0;i0<CACHEWAYSIZE;i0++)
   begin
      check_hit(.tag(RANDOM_TAGS[i0]), .index (0), .offset(0), 
                .ex_hit (1'b1), .ex_hit_line_no (i0), .ex_hit_line_v (1'b1), .ex_hit_line_d (1'b0));
   end 
      
   if(error==0) $display("TEST 1 PASSED");          
   else         $display("TEST 1 FAILED. ERROR NUMBER :%d",error); 
   //                     
end 
endtask 



//======================================
// TEST2
//======================================
// THE LEAST RECENTLY USED LINE ALGORITHM TEST 
task test2();
begin
   RESET();
   error = 0;
   WRD( .wrd_wr (1'b1), .wrd_line_no ('d0), .wrd_tag ('d0), .wrd_index ('d0), .wrd_offset ('d0), .wrd_size('d0) );
   //
   @(posedge clk);
   #2;
   // 
   if(uCACHE.lru_line_no[0] != 1'd1) error++;
   //          
   if(error==0) $display("TEST 2 PASSED");          
   else         $display("TEST 2 FAILED. ERROR NUMBER :%d",error); 
   //  
end 
endtask



//======================================
// TEST 3: BURST READ TEST 
//======================================
task test3();
begin
   RESET();
   test_cnt++;
   error = 0;
   

 
   for(int i0=0;i0<CACHESETSIZE;i0++)
   begin    
      for(int i1=0;i1<CACHEWAYSIZE;i1++)
      begin   
         for(int i2=0;i2<LINEWORDSIZE;i2++)
         begin
            uCACHE.T_CACHE_DATA[i0][i1][i2] = $random;
         end 
      end 
   end 
   
   // EXECUTE BURST 
   for(int i0=0;i0<CACHEWAYSIZE;i0++)
   begin 
      BURST(.burst_wr (1'b0),.tag ('0),.index ('d0), .offset ('0), .burst_line_no (i0) );
   end  
   //
end 
endtask 



//======================================
// TEST 4: BURST WRITE TEST 
//======================================
task test4();
begin
   RESET();
   error = 0;
   //
   for(int i=0;i<CACHEWAYSIZE;i++)
   begin
      BURST(.burst_wr (1'b1),.tag ('0),.index ('d0), .offset ('0), .burst_line_no (i), .burst_start_data (5*i)  ); 
   end 
   //
end 
endtask 


//======================================
// TEST 5: WRITE WORD/HALF-WORD/BYTE TEST 
//======================================
task test5();
begin
   RESET();
   test_cnt++;
   error = 0;
   // WRITE WORD 
   WRD( .wrd_wr (1'b1), .wrd_wdata('h12345678), .wrd_line_no ('d0), .wrd_tag ('d0), .wrd_index ('d0), .wrd_offset ('d0), .wrd_size('b10) );
   // WRITE HALF WORD
   WRD( .wrd_wr (1'b1), .wrd_wdata('h22221111), .wrd_line_no ('d0), .wrd_tag ('d0), .wrd_index ('d1), .wrd_offset ('b00), .wrd_size('b01) );
   WRD( .wrd_wr (1'b1), .wrd_wdata('h22221111), .wrd_line_no ('d1), .wrd_tag ('d0), .wrd_index ('d1), .wrd_offset ('b10), .wrd_size('b01) );
   //WRITE BYTE 
   WRD( .wrd_wr (1'b1), .wrd_wdata('h44332211), .wrd_line_no ('d1), .wrd_tag ('d0), .wrd_index ('d2), .wrd_offset ('d0), .wrd_size('b00) );
   WRD( .wrd_wr (1'b1), .wrd_wdata('h44332211), .wrd_line_no ('d2), .wrd_tag ('d0), .wrd_index ('d2), .wrd_offset ('d1), .wrd_size('b00) );
   WRD( .wrd_wr (1'b1), .wrd_wdata('h44332211), .wrd_line_no ('d3), .wrd_tag ('d0), .wrd_index ('d2), .wrd_offset ('d2), .wrd_size('b00) );
   WRD( .wrd_wr (1'b1), .wrd_wdata('h44332211), .wrd_line_no ('d4), .wrd_tag ('d0), .wrd_index ('d2), .wrd_offset ('d3), .wrd_size('b00) );
   //
end 
endtask 


//====================================
// STIMULUS 
//====================================
initial begin
   RESET();
   //test1();
   //test2();
   //test3();
   test4();
   //test5();

   $finish;
end 


//========================
// DUT Instantiation 
//========================
CACHE #(.LINEWORDSIZE (LINEWORDSIZE),  // Number of Words(32-bit) in each MemoryBlock/CacheLine 
        .CACHESETSIZE (CACHESETSIZE),  // Number of Sets in Cache  
        .CACHEWAYSIZE (CACHEWAYSIZE)) uCACHE(.*);


endmodule: CACHE_tb 


