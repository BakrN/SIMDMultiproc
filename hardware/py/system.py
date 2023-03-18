# system  test 
from typing import List, Union
from model.mem import Mem 
from model.cmd import Command, gen_cmd_queue, CmdQueueSerializer , CmdFetcher
from model.proc import Pool
import random 

MEM_SIZE = 4096
PROC_COUNT = 4
CMD_COUNT = 1000 


buffer = Mem(MEM_SIZE).randomize()    
original_buffer = buffer.cpy()

queue = gen_cmd_queue(1000,buffer)  
fetcher = CmdFetcher(queue, PROC_COUNT) 
pool = Pool(PROC_COUNT)
# stall for dependencies 

while not queue.empty() :  
    # Clock tick 
    # Get non busy processors  

    free_proc = pool.size - pool.busy() 
    next_cmds = fetcher.fetch( free_proc) 
    if free_proc > 0 and not next_cmds: 
        print("Finished executing all commands") 
        break
    # Execute the commands
    for cmd in next_cmds:
        pool.assign_cmd(cmd) 
    pool.run() 
    queue.update() 

#mem_serializer = MemHexSerializer(buffer)
#mem_serializer.serialize("mem.txt")
#mem_serializer = MemHexSerializer(original_buffer)
#mem_serializer.serialize("valid_mem.txt")
#serializer = CmdQueueSerializer(queue)# for teseting
#print(serializer) 


# Test Pattern of operations 

# Element-wise adds 

# Generate a list of Command for element-wise adds






# Element-wise mult 

# Element-wise adds + mult

# Output to a file 

