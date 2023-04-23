# system  test 
from typing import List, Union
from model.mem import Mem  , MemHexSerializer
from model.cmd import Command, gen_cmd_queue, CmdQueueSerializer , execute_cmd, Status , cmd_from_bin
from model.proc import Pool
import random 

MEM_SIZE = 4096
PROC_COUNT = 4
CMD_COUNT = 1000


buffer = Mem(MEM_SIZE).randomize()    
mem_serializer = MemHexSerializer(buffer)
mem_serializer.serialize("tests/shared_mem.txt")

queue = gen_cmd_queue(CMD_COUNT,buffer)  

serializer = CmdQueueSerializer(queue)# for teseting

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


