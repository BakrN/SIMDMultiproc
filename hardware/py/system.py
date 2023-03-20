# system  test 
from typing import List, Union
from model.mem import Mem  , MemHexSerializer
from model.cmd import Command, gen_cmd_queue, CmdQueueSerializer , execute_cmd, Status
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
while not queue.empty(): 
    for cmd in map(lambda x: x.data, queue.top_cmd): 
        execute_cmd(cmd, buffer)
        cmd.status = Status.DONE 
    queue.update()  




mem_serializer.serialize("tests/valid_mem.txt")

#serializer = CmdQueueSerializer(queue)# for teseting
#print(serializer) 


# Test Pattern of operations 

# Element-wise adds 

# Generate a list of Command for element-wise adds






# Element-wise mult 

# Element-wise adds + mult

# Output to a file 

