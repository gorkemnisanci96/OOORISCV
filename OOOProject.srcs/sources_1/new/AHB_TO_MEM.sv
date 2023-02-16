`timescale  1ns / 1ns
// Data memory (Dual-port RAM)
//

module  AHB_TO_MEM #(parameter MEMWIDTH = 16)	
  (
  //==== ==== Slave Select 
  input wire        HSEL_i,
  //==== ==== Clock and Reset Signals 
  input             HCLK_i   ,  // Positive-edge triggered clock
  input             HRESETn_i,  // active-Low Reset 
  //==== ==== 
  input wire        HREADY,
  input wire [31:0] HADDR,
  input wire [1:0]  HTRANS,
  input wire        HWRITE,
  input wire [2:0]  HSIZE,
  input wire [31:0] HWDATA,
  //==== ==== Outputs 
  output wire       HREADYOUT,
  output reg [31:0] HRDATA
) ;


//=====================================
// Local Wires and Registers 
//=====================================

reg   [31:0]  ram  [(MEMWIDTH-1):0];// Memory array


integer i;
initial begin
for(i = 0 ; i <MEMWIDTH; i = i + 1) ram[i] = 32'h0;
//$readmemh("test.mem",ram);
end 

//=====================================
// Write Signal Generation 
//=====================================
//HSIZE[2] HSIZE[1] HSIZE[0] 
//   0        0       0      BYTE  
//   0        0       1      HALFWORD 
//   0        1       0      WORD 
wire byte_     = ~HSIZE[2]& ~HSIZE[1]& ~HSIZE[0]; 
wire half_word = ~HSIZE[2]& ~HSIZE[1]&  HSIZE[0]; 
wire word      = ~HSIZE[2]&  HSIZE[1]&  ~HSIZE[0];

wire byte_00 = byte_ & ~HADDR[1] & ~HADDR[0];
wire byte_01 = byte_ & ~HADDR[1] &  HADDR[0];
wire byte_10 = byte_ &  HADDR[1] & ~HADDR[0];
wire byte_11 = byte_ &  HADDR[1] &  HADDR[0];

wire half_word_00_01 = half_word & ~HADDR[1];
wire half_word_10_11 = half_word &  HADDR[1];

wire byte0 = word | half_word_00_01 | byte_00;
wire byte1 = word | half_word_00_01 | byte_01;
wire byte2 = word | half_word_10_11 | byte_10;
wire byte3 = word | half_word_10_11 | byte_11;


//=====================================
// Write Operation
//=====================================
always@ (posedge HCLK_i) begin
   if(HSEL_i & HWRITE)
   begin
       if(byte0)
           ram[HADDR[MEMWIDTH-1:2]][7:0]   <= HWDATA[7:0];
       if(byte1)
           ram[HADDR[MEMWIDTH-1:2]][15:8]  <= HWDATA[15:8];
       if(byte2)
           ram[HADDR[MEMWIDTH-1:2]][23:16] <= HWDATA[23:16];
       if(byte3)
           ram[HADDR[MEMWIDTH-1:2]][31:24] <= HWDATA[31:24];
   end
end 

//=====================================
// Read Operation
//=====================================

always@ (posedge HCLK_i)
begin
   if(HSEL_i)
   begin
      HRDATA <= ram[HADDR[MEMWIDTH-1:2]]; 
   end
end 

//=====================================
// Data Memory Ready Output 
//=====================================
assign HREADYOUT=1'b1;


endmodule