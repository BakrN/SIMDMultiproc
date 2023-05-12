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
MAT_UPPER_LIMIT = 2**8 - 1 
MAT_LOWER_LIMIT = -2**8
import os 

def generate_add_files():  
    with open("tests/proc/outputs_add.txt", "w")as f_add, open("tests/proc/inputs.txt", "w") as f_i , open("tests/proc/outputs_sub.txt", "w") as f_sub:  
        for i in range (COUNT):  
            in_1  = [random.randint(LOWER_LIMIT, UPPER_LIMIT) for i in range(WIDTH)]  # mat
            in_2  = [random.randint(LOWER_LIMIT, UPPER_LIMIT) for i in range(WIDTH)]  # vec 
            out_add = list(map(lambda x , y: x + y , in_1 , in_2 )) 
            out_sub = list(map(lambda x , y: x - y , in_1 , in_2 ))                            

            out_add = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , out_add))  # 32 bit ints
            out_sub = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , out_sub))   # 32 bit ints  
            in_1    = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , in_1))   # 32 bit ints  
            in_2    = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , in_2))  # 32 bit ints 


            f_i.write("{}\n".format  (','.join(  i.zfill(8) for i in in_1)))
            f_i.write("{}\n".format  (','.join(  i.zfill(8) for i in in_2)))
            f_add.write("{}\n".format(','.join(i.zfill(8)   for i in out_add)))
            f_sub.write("{}\n".format(','.join(i.zfill(8)   for i in out_sub))) 
        f_i.close() 
        f_add.close() 
        f_sub.close() 
def generate_matmul_files(size = 16):
    # Generate random toep 
    mat = [random.randint(MAT_LOWER_LIMIT, MAT_UPPER_LIMIT) for i in range(2*size-1)]
    vec = [random.randint(MAT_LOWER_LIMIT, MAT_UPPER_LIMIT) for i in range(size)]
    out = [0 for i in range(size)] 
    # mat vec multiplication 
    for row in range (size): 
        for col in range(size):
            out[row] += mat[(size)-1 - row + col ] * vec[col]
    #serialize 
    mat = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , mat))  # 32 bit ints
    vec = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , vec))   # 32 bit ints  
    out = list(map(lambda x: hex(x & 0xFFFFFFFF)[2:] , out))   # 32 bit ints  
    # write to file  
    with open("tests/proc/matmul/mat.txt", "w") as f_mat, open("tests/proc/matmul/vec.txt", "w") as f_vec, open("tests/proc/matmul/out.txt", "w") as f_o:  
        for ele in mat:
            f_mat.write("{}\n".format(ele.zfill(8)))
        for ele in vec: 
            f_vec.write("{}\n".format(ele.zfill(8))) 
        for ele in out: 
            f_o.write("{}\n".format(ele.zfill(8))) 
        f_mat.close() 
        f_vec.close()
        f_o.close()

# Run experiment 
#generate_add_files() 
#generate_matmul_files() 

mat = [random.randint(-4 , 4) for i in  range(7) ]
vec = [random.randint(-4 , 4) for i in  range(4) ]
out = [0 for i in range(4)]
for row in range (4):
    for col in range(4):
        out[row] += mat[3 - row + col ] * vec[col]
print("Printing mat: "  )  
print(mat) 
print("Printing vec: "  )
print(vec)
print("Printing out: "  )
print(out) 

# Verification  
# * FULLY VERIFIES 
#verify("tests/proc/test_add.txt", "tests/proc/outputs_add.txt") 
#verify("tests/proc/test_sub.txt", "tests/proc/outputs_sub.txt")
#verify("tests/proc/test_mul_2x.txt", "tests/proc/outputs_mul_2x.txt")
#verify("tests/proc/test_mul_3x.txt", "tests/proc/outputs_mul_3x.txt") 
