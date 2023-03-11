
import random 
from utils import verify 
BITWIDTH = 32 
def twos_complement(hexstr):
    value = int(hexstr, 16)
    if value & (1 << (32- 1)):
        value -= 1 << 32 
    return value
COUNT = 1000
WIDTH = 4
UPPER_LIMIT =  2**15 - 1 
LOWER_LIMIT =  -2^15   
import os
def generate_files(): 
    with open("outputs_add.txt", "w")as f_add, open("inputs.txt", "w") as f_i , open("outputs_sub.txt", "w") as f_sub,  open("outputs_mul.txt", "w") as f_mul :  
        for i in range (COUNT):  
            in_1  = [random.randint(LOWER_LIMIT, UPPER_LIMIT) for i in range(WIDTH)] 
            in_2  = [random.randint(LOWER_LIMIT, UPPER_LIMIT) for i in range(WIDTH)] 
            out_add = list(map(lambda x , y: x + y , in_1 , in_2 )) 
            out_sub = list(map(lambda x , y: x - y , in_1 , in_2 ))                            
            out_mul = list(map(lambda x , y: x * y , in_1 , in_2 ))                              
            out_add = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , out_add))  # 32 bit ints
            out_sub = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , out_sub))   # 32 bit ints  
            out_mul = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , out_mul))  # 32 bit ints 
            in_1    = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , in_1))   # 32 bit ints  
            in_2    = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , in_2))  # 32 bit ints 


            f_i.write("{}\n".format  (','.join(  i.zfill(8) for i in in_1)))
            f_i.write("{}\n".format  (','.join(  i.zfill(8) for i in in_2)))
            f_add.write("{}\n".format(','.join(i.zfill(8)   for i in out_add)))
            f_sub.write("{}\n".format(','.join(i.zfill(8)   for i in out_sub)))
            f_mul.write("{}\n".format(','.join(i.zfill(8)   for i in out_mul)))
        f_i.close() 
        f_add.close() 
        f_mul.close() 
        f_sub.close() 
# Run experiment 
#os.system("cd .. && iverilog -DTEST_CASE=" +str(COUNT) + " -Wall -g2012 -o sim/tb_proc.vvp tb_proc.sv ")
#os.system("vvp ../sim/tb_proc.vvp") 
# Verification  
# * FULLY VERIFIES 
verify("test_add.txt", "outputs_add.txt") 
verify("test_sub.txt", "outputs_sub.txt")
verify("test_mul.txt", "outputs_mul.txt")
