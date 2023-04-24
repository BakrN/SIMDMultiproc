
import random 
from utils import verify 
BITWIDTH = 32 
def twos_complement(hexstr):
    value = int(hexstr, 16)
    if value & (1 << (32- 1)):
        value -= 1 << 32 
    return value
COUNT = 1000
WIDTH = 5
UPPER_LIMIT =  2**15 - 1 
LOWER_LIMIT =  -2^15   
import os
def generate_files(): 
    with open("tests/proc/outputs_add.txt", "w")as f_add, open("tests/proc/inputs.txt", "w") as f_i , open("tests/proc/outputs_sub.txt", "w") as f_sub,open("tests/proc/outputs_mul_2x.txt", "w") as f_mul_2x, open("tests/proc/outputs_mul_3x.txt", "w") as f_mul_3x  :  
        for i in range (COUNT):  
            in_1  = [random.randint(LOWER_LIMIT, UPPER_LIMIT) for i in range(WIDTH)]  # mat
            in_2  = [random.randint(LOWER_LIMIT, UPPER_LIMIT) for i in range(WIDTH)]  # vec 
            out_add = list(map(lambda x , y: x + y , in_1 , in_2 )) 
            out_sub = list(map(lambda x , y: x - y , in_1 , in_2 ))                            
            out_2x = [in_1[1]*in_2[0] + in_1[2]*in_2[1], 
                      in_1[0]*in_2[0] +in_1[1]*in_2[1], 
                      0 ,0 ,0]  # v0 v1 X X X
            out_3x = [in_1[2]*in_2[0]+in_1[3]*in_2[1]+in_1[4]*in_2[2], 
                      in_1[1]*in_2[0]+in_1[2]*in_2[1]+in_1[3]*in_2[2], 
                      in_1[0]*in_2[0]+in_1[1]*in_2[1]+in_1[2]*in_2[2], 
                      0 ,0
                      ]  # v0 v1 v2 X X

            out_add = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , out_add))  # 32 bit ints
            out_sub = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , out_sub))   # 32 bit ints  
            out_mul_2x = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , out_2x))  # 32 bit ints 
            out_mul_3x = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , out_3x))  # 32 bit ints 
            in_1    = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , in_1))   # 32 bit ints  
            in_2    = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , in_2))  # 32 bit ints 


            f_i.write("{}\n".format  (','.join(  i.zfill(8) for i in in_1)))
            f_i.write("{}\n".format  (','.join(  i.zfill(8) for i in in_2)))
            f_add.write("{}\n".format(','.join(i.zfill(8)   for i in out_add)))
            f_sub.write("{}\n".format(','.join(i.zfill(8)   for i in out_sub))) 
            f_mul_2x.write("{}\n".format(','.join(i.zfill(8)   for i in out_mul_2x)))
            f_mul_3x.write("{}\n".format(','.join(i.zfill(8)   for i in out_mul_3x)))
        f_i.close() 
        f_add.close() 
        f_sub.close() 
        f_mul_2x.close() 
        f_mul_3x.close() 

# Run experiment 
generate_files() 
# Verification  
# * FULLY VERIFIES 
#verify("tests/proc/test_add.txt", "tests/proc/outputs_add.txt") 
#verify("tests/proc/test_sub.txt", "tests/proc/outputs_sub.txt")
#verify("tests/proc/test_mul_2x.txt", "tests/proc/outputs_mul_2x.txt")
#verify("tests/proc/test_mul_3x.txt", "tests/proc/outputs_mul_3x.txt") 
