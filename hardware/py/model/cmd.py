
from re import A
from typing import Dict, Union
from model.mem import Mem
from enum import Enum
from dataclasses import dataclass
import random 
import bisect
MAX_ID = 15 
MAX_COUNT = 63
class Status(Enum): 
    WAITING = 0
    RUNNING = 1 
    DONE = 2
class Opcode(Enum): 
    ADD = 0
    SUB = 1
    MUL_2x = 2
    MUL_3x = 3
class Command: 
    id : int = 0     # Command ID 
    dep_id :int = 0 # Dependency ID
    opcode : Opcode= Opcode.ADD # Operation code (e.g. ADD, SUB, MUL)
    addr0  : int = 0 # address of the first operand
    addr1  : int = 0 # address of the second operand
    count  : int = 0 # Number of elements the operation is applied to
    writeback_addr : int= 0 # Address for writeback data 
    status : Status = Status.WAITING # Status of the command
    def __str__(self) -> str:
        """Return a string representation of the command."""
        return str(self.id) + " " + str(self.opcode) + " " + str(self.addr0) + " " + str(self.addr1) + " " + str(self.count) + " " + str(self.writeback_addr) + " " + str(self.status) + " " + str(self.dep_id) 
    def to_packed_hex(self):
       id_hex = hex(self.id)[2:].zfill(2)   # Convert ID to hex and pad with leading zeros if necessary
       dep_id_hex = hex(self.dep_id)[2:].zfill(2)   # Convert Dependency ID to hex and pad with leading zeros if necessary
       opcode_hex = hex(self.opcode.value)[2:].zfill(2)  # Convert Opcode value to hex and pad with leading zeros if necessary
       addr0_hex = hex(self.addr0)[2:].zfill(6)  # Convert address of the first operand to hex and pad with leading zeros if necessary
       addr1_hex = hex(self.addr1)[2:].zfill(6)  # Convert address of the second operand to hex and pad with leading zeros if necessary
       count_hex = hex(self.count)[2:].zfill(2)  # Convert Number of elements to hex and pad with leading zeros if necessary
       writeback_addr_hex = hex(self.writeback_addr)[2:].zfill(6)  # Convert Address for writeback data to hex and pad with leading zeros if necessary
       packed_hex = f"{id_hex}{dep_id_hex}{opcode_hex}{addr0_hex}{addr1_hex}{count_hex}{writeback_addr_hex}"
       
       return packed_hex
    def to_packed_bin(self):
        id_bin =   bin(self.id)[2:].zfill(4)   # 4 bits
        dep_id_bin = bin(self.dep_id)[2:].zfill(4)   # 4 bits
        opcode_bin = bin(self.opcode.value)[2:].zfill(2) # 2bits
        addr0_bin = bin(self.addr0)[2:].zfill(24)  # 24 bits
        addr1_bin = bin(self.addr1)[2:].zfill(24)  # 24 bits 
        count_bin = bin(self.count)[2:].zfill(6)  # 6 bits
        writeback_addr_bin = bin(self.writeback_addr)[2:].zfill(24)  # 24 bits  
        packed_bin = f"{id_bin}{dep_id_bin}{opcode_bin}{addr0_bin}{addr1_bin}{count_bin}{writeback_addr_bin}" 
        return packed_bin
def cmd_from_bin(bin_str):
    cmd = Command()
    cmd.id = int(bin_str[0:4], 2)
    cmd.dep_id = int(bin_str[4:8], 2)
    cmd.opcode = Opcode(int(bin_str[8:10], 2))
    cmd.addr0 = int(bin_str[10:34], 2)
    cmd.addr1 = int(bin_str[34:58], 2)
    cmd.count = int(bin_str[58:64], 2)
    cmd.writeback_addr = int(bin_str[64:88], 2)
    return cmd
class Node: 
    def __init__(self, data, parent = None , children: list = None) -> None:
        self.data = data 
        self.parent = parent
        self.children = []
    def add_child(self, node):
        self.children.append(node)
    def root (self): 
        if self.parent == None : 
            return self
        else : 
            return self.parent.root()
    def rank(self): 
        return sum([child.rank() for child in self.children]) + 1
    def data(self): 
        return self.data

# find start addr less than addr_start , and then check for next start addr and check if it's overlapping with the cmd we want to insert     

# implement a binary search algorithm on a sorted array and return the index of the first element that is less than the target
def binary_search_less_than(arr, l, r, x, func):
    # Check base case
    if r >= l:
        mid = l + (r - l) // 2
        # If element is present at the middle itself
        if func(arr[mid]) < x and ((mid +1 < len(arr) and func(arr[mid+1]) >= x) or (mid +1 == len(arr)) ):
            return mid
        # If element is smaller than mid, then it
        # can only be present in left subarray
        elif func(arr[mid]) > x:
            return binary_search_less_than(arr, l, mid-1, x, func)
        # Else the element can only be present
        # in right subarray
        else:
            return binary_search_less_than(arr, mid + 1, r, x, func) 
    else:
        return -1 # no value less than x . Insert at 0 

# Command queue 
class CmdQueue:
    def __init__(self) -> None:
        self.top_cmd : list[Node] = []  # list of top commands to be executed (sorted by addr_start)

    def add_cmd(self, cmd : Command): 
        # find the first cmd that has a start addr less than the cmd we want to insert
        if not self.top_cmd: 
            self.top_cmd.append(Node(cmd)) 
            return 
        idx = binary_search_less_than(self.top_cmd, 0, len(self.top_cmd) - 1, cmd.writeback_addr, lambda x: x.data.writeback_addr) 
        
        lesser_node = self.top_cmd[idx]
        
        if lesser_node.data.writeback_addr == cmd.writeback_addr: 
            cmd.dep_id = lesser_node.data.id
            lesser_node.add_child(Node(cmd)  )
            return

        elif lesser_node.data.writeback_addr < cmd.writeback_addr and lesser_node.data.writeback_addr -1 + lesser_node.data.count >= cmd.writeback_addr: 
            cmd.dep_id = lesser_node.data.id
            lesser_node.add_child(Node(cmd))
            return
        # Now check following instructions if they're dependent on the cmd we want to insert
        insert_index = idx + 1 
        if insert_index >= len(self.top_cmd): 
            self.top_cmd.append(Node(cmd))
            return 
        else:  
            self.top_cmd.insert(insert_index, Node(cmd))  
        i = insert_index + 1
        while i < len(self.top_cmd):
            if self.top_cmd[i].data.writeback_addr <= cmd.writeback_addr + cmd.count -1  :   
                self.top_cmd[i].data.dep_id = cmd.id 
                if self.top_cmd[i].data.id == cmd.id: 
                    self.top_cmd[i].data.id = max(1, (self.top_cmd[i].data.id + 1) % (MAX_ID+1) ) 

                self.top_cmd[insert_index].add_child(self.top_cmd[i]) 
                self.top_cmd.pop(i)  
            else : 
                break  
        return    
    def update(self): # delete finished commands and push new commands to the top
        i = 0 
        while i < len(self.top_cmd): 
            if self.top_cmd[i].data.status == Status.DONE : # cleanup done commands
                parent_node =self.top_cmd.pop(i) 
                for node in parent_node.children : 
                    self.add_node(node)  
                
            else :
                i+= 1 
    def add_node(self, cmd_node : Node): 
        if not self.top_cmd: 
            self.top_cmd.append(cmd_node) 
            return 
        idx = binary_search_less_than(self.top_cmd, 0, len(self.top_cmd) - 1, cmd_node.data.writeback_addr, lambda x: x.data.writeback_addr) 
        
        lesser_node = self.top_cmd[idx]
        
        if lesser_node.data.writeback_addr == cmd_node.data.writeback_addr: 
            cmd_node.data.dep_id = lesser_node.data.id
            lesser_node.add_child(cmd_node)
            return

        elif lesser_node.data.writeback_addr < cmd_node.data.writeback_addr and lesser_node.data.writeback_addr -1 + lesser_node.data.count >= cmd_node.data.writeback_addr: 
            cmd_node.data.dep_id = lesser_node.data.id
            lesser_node.add_child(cmd_node)
            return
        # Now check following instructions if they're dependent on the cmd we want to insert
        insert_index = idx + 1 
        if insert_index >= len(self.top_cmd): 
            self.top_cmd.append(cmd_node)
            return 
        else:  
            self.top_cmd.insert(insert_index, cmd_node)  
        i = insert_index + 1
        while i < len(self.top_cmd):
            if self.top_cmd[i].data.writeback_addr <= cmd_node.data.writeback_addr + cmd_node.data.count -1  :   
                self.top_cmd[i].data.dep_id = cmd_node.data.id 
                self.top_cmd[insert_index].add_child(self.top_cmd[i]) 
                self.top_cmd.pop(i)  
            else : 
                break  
        return    
                
    def get_cmd_nodes_lvl(self, lvl=0):  # get cmd from index
        queue = self.top_cmd
        while lvl > 0 and len(queue) > 0 :
            next_queue = []
            for node in queue:
                next_queue += node.children
            queue = next_queue
            lvl -= 1
        return queue
    def empty(self): 
        return len(self.top_cmd) == 0
    def size(self): 
        return sum([cmd.rank() for cmd in self.top_cmd])
 
   
class CmdQueueSerializer: # serialize command queue 
    def __init__(self , queue : CmdQueue) -> None: 
        self.queue = queue
        pass 
    def serialize(self, filename):
        # Write queue to file 
        with open(filename, 'w') as f:
            queue = self.queue.top_cmd           
            while len(queue) > 0: 
                next_queue = []
                for node in queue: 
                    f.write(node.data.to_packed_bin() + "\n")

                    next_queue += node.children
                queue = next_queue
        # Serialize the command queue to a file

        pass
    def __str__(self) -> str: 
        string = "Queue size: " + str(self.queue.size()) +"\n" 
 
        level = 0 
        # iterate over queue and print each command. Do a BFS traversal
        queue = self.queue.top_cmd
        while len(queue) > 0 :
            string+= "Level " + str(level) + ":\n"
            next_queue = []
            index = 0 
            for node in queue:
                string+= f"Index {index}: " + str(node.data) + "\n"
                next_queue += node.children
                index +=1 
            queue = next_queue
            level += 1

        return string 

class CmdFetcher: 
    def __init__(self , queue: CmdQueue, fetch_size = 4): 
        self.queue = queue
        self.count = fetch_size
        self.current_index = 0 
        self.level = 0 
        self.cmd_buffer = []
        pass
    

        

        

#generate add cmd with a dependency parameter that is set to -1 by default 
def gen_add_cmd(id,  addr0, addr1, count, writeback_addr, dep_id=0):
    cmd = Command()
    cmd.id = max(id % (MAX_ID + 1), 1) 
    cmd.dep_id = dep_id
    cmd.opcode = Opcode.ADD
    cmd.addr0 = addr0
    cmd.addr1 = addr1
    cmd.count = count % (MAX_COUNT + 1)
    cmd.writeback_addr = writeback_addr
    return cmd
#generate a sub cmd
def gen_sub_cmd(id,  addr0, addr1, count, writeback_addr, dep_id=0):
    cmd = Command()
    cmd.id = max(id  % (MAX_ID + 1), 1) 
    cmd.dep_id = dep_id
    cmd.opcode = Opcode.SUB
    cmd.addr0 = addr0
    cmd.addr1 = addr1
    cmd.count = count % (MAX_COUNT + 1)
    cmd.writeback_addr = writeback_addr
    return cmd

# Generate a random list of commands with different dependencies (dependency yhere based on writeback address not command itself)
def gen_cmd_queue(count,mem : Mem , max_op_size = 100): 
    queue = CmdQueue()
    for i in range(count) :  
        cmd_type = random.randint(0,2) 
        op_size = random.randint(1,max(2, max_op_size) )  
        addr0 = random.randint(0,mem.count-2*op_size)
        addr1 = random.randint(addr0+1,mem.count - op_size)   
        writeback_addr = random.randint(0,mem.count - op_size)
        if cmd_type == 0 :
            cmd = gen_add_cmd(i+1 , addr0, addr1, op_size, writeback_addr)
        else : 
            cmd = gen_sub_cmd(i+1 , addr0, addr1, op_size, writeback_addr)
        queue.add_cmd(cmd)
    return queue

def execute_cmd (cmd : Command , mem : Mem): 
    if cmd.opcode == Opcode.ADD :
        for i in range(cmd.count):
            mem.data[cmd.writeback_addr + i] = mem.data[cmd.addr0 + i] + mem.data[cmd.addr1 + i]
    elif cmd.opcode == Opcode.SUB :
        for i in range(cmd.count):
            mem.data[cmd.writeback_addr + i] = mem.data[cmd.addr0 + i] - mem.data[cmd.addr1 + i]
    cmd.status = Status.DONE
    return mem
