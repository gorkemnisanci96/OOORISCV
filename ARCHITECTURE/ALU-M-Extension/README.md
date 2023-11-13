## Micro-Architecture of -M Extension Implementation    

-   -M Extension Instructions   
    
0000001 rs2 rs1 000 rd 0110011 MUL     
0000001 rs2 rs1 001 rd 0110011 MULH     
0000001 rs2 rs1 010 rd 0110011 MULHSU     
0000001 rs2 rs1 011 rd 0110011 MULHU     
0000001 rs2 rs1 100 rd 0110011 DIV     
0000001 rs2 rs1 101 rd 0110011 DIVU     
0000001 rs2 rs1 110 rd 0110011 REM     
0000001 rs2 rs1 111 rd 0110011 REMU     

MUL: It performs 32-bit x 32-bit Multiplication and places the LOWER 32-bit of the 64-bit result in the destination register.        
MULH: It performs 32-bit(signed) x 32-bit(signed) Multiplication and places the UPPER 32-bit of the 64-bit result in the destination register.      
MULHU: It performs 32-bit(unsigned) x 32-bit(unsigned) Multiplication and places the UPPER 32-bit of the 64-bit result in the destination register.     
MULHU: It performs 32-bit(signed) x 32-bit(unsigned) Multiplication and places the UPPER 32-bit of the 64-bit result in the destination register.     

DIV:  It performes signed interger division of rs1 by rs2, rounding towards zero.     
DIVU: It performes unsigned interger division of rs1 by rs2, rounding towards zero.    
REM:  It provides the remainder of the DIV operation. Sign of the remainder is the sign of the dividend.       
REMU: It provides the remainder of the DIVU operation. 

-   Micro-Architecture of the MUL_DIV module.



