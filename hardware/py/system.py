# system  test 
from typing import List, Union
from model.mem import Mem  , MemHexSerializer
from model.cmd import Command, gen_add_cmd, gen_cmd_queue, CmdQueueSerializer , execute_cmd, Status , cmd_from_bin, gen_sub_cmd, CmdQueue
from model.proc import Pool
import random 

MEM_SIZE = 1024 
PROC_COUNT = 4
CMD_COUNT = 10  


buffer = Mem(MEM_SIZE).randomize()    
mem_serializer = MemHexSerializer(buffer)
mem_serializer.serialize("tests/shared_mem.txt")

#queue = gen_cmd_queue(CMD_COUNT,buffer)  
queue = CmdQueue() 
# create cmd 
cmd0 = gen_add_cmd(1 , 0  , 100 , 20 , 20) 
cmd1 = gen_sub_cmd(2 , 30 , 400 , 35, 300  ,1 )  # depends on cmd0
cmd2 = gen_sub_cmd(3 , 332, 800 , 200 , 700 ,2 ) # depends on cmd1
queue.add_cmd(cmd0)
queue.add_cmd(cmd1)
queue.add_cmd(cmd2)

serializer = CmdQueueSerializer(queue)# for teseting
print(serializer)
serializer.serialize("tests/cmd_queue.txt")
commands = []
# create list from file 
with open("tests/cmd_queue.txt", "r") as f:
    lines = f.readlines()
    lines = list(map(lambda x: x.strip(), lines))
    commands = list(map(lambda x: cmd_from_bin(x), lines)) 

for cmd in commands:
    execute_cmd(cmd, buffer) 

mem_serializer.serialize("tests/valid_mem.txt")


