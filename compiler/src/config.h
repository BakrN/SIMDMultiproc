#pragma once 

#define BASE_MMUL_2x_SIZE 64// lowest point where we actuall do the multiplication (could try out with different values  later)  
#define BASE_MMUL_3x_SIZE 9
#define MAX_OP_COUNT 127 // 8 bits 
#define COUNT_BITS 8
#define ADDR_BITS 24
#define OPCODE_BITS 2  // add sub mul2x mul3x 
#define ID_BITS 4 
#define CMD_BITS  90 
#define MIN_CMD_ID 1
