
from typing import Dict
from model.mem import Mem
from enum import Enum
from dataclasses import dataclass
import random 
import bisect

class Status(Enum): 
    WAITING = 0
    RUNNING = 1 
    DONE = 2
class Opcode(Enum): 
    ADD = 0
    SUB = 1
    MUL = 2
class Command: 
    id : int = 0     # Command ID 
    dep_id :int = -1 # Dependency ID
    opcode : Opcode= Opcode.ADD # Operation code (e.g. ADD, SUB, MUL)
    addr0  : int = 0 # address of the first operand
    addr1  : int = 0 # address of the second operand
    count  : int = 0 # Number of elements the operation is applied to
    writeback_addr : int= 0 # Address for writeback data 
    status : Status = Status.WAITING # Status of the command


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
        if func(arr[mid]) < x and mid +1 < len(arr) and func(arr[mid+1]) >= x:
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
        idx = binary_search_less_than(self.top_cmd, 0, len(self.top_cmd) - 1, cmd.writeback_addr, lambda x: x.data.writeback_addr) + 1
        if self.top_cmd[idx].data.addr_end >= cmd.writeback_addr: 
                cmd.dep_id = self.top_cmd[idx].data.id
                self.top_cmd[idx].data.add_child(cmd)  
        else:
            self.top_cmd.insert(idx, Node(cmd))  
            # Now check following instructions if they're dependent on the cmd we want to insert
            for i in range(idx + 1, len(self.top_cmd)):
                if self.top_cmd[i].data.writeback_addr < cmd.addr_end :  
                    self.top_cmd[i].data.dep_id = cmd.id 
                    self.top_cmd[idx].add_child(self.top_cmd[i])
                    self.top_cmd.pop(i)
                else : 
                    break     
    def push_top(self): # delete finished commands and push new commands to the top
        for i in range (self.top_cmd): 
            if self.top_cmd[i].data.status == Status.DONE : # cleanup done commands
                for node in self.top_cmd[i].children : 
                    self.add_cmd(node)  
                self.top_cmd.pop(i)
    def get_next_cmds(self, count):  # get the next batch of commands to be executed
        return [self.top_cmd[i].data for i in range(min(count, len(self.top_cmd)))]
    def empty(self): 
        return len(self.top_cmd) == 0
    def size(self): 
        return sum([cmd.rank() for cmd in self.top_cmd])
 
    
class CmdQueueSerializer: # serialize command queue 
    def __init__(self) -> None:
        pass


#generate add cmd with a dependency parameter that is set to -1 by default 
def gen_add_cmd(id,  addr0, addr1, count, writeback_addr, dep_id=-1):
    cmd = Command()
    cmd.id = id
    cmd.dep_id = dep_id
    cmd.opcode = Opcode.ADD
    cmd.addr0 = addr0
    cmd.addr1 = addr1
    cmd.count = count
    cmd.writeback_addr = writeback_addr
    return cmd
# generate a mul cmd 
def gen_mul_cmd(id,  addr0, addr1, count, writeback_addr, dep_id=-1):
    cmd = Command()
    cmd.id = id
    cmd.dep_id = dep_id
    cmd.opcode = Opcode.MUL
    cmd.addr0 = addr0
    cmd.addr1 = addr1
    cmd.count = count
    cmd.writeback_addr = writeback_addr
    return cmd
#generate a sub cmd
def gen_sub_cmd(id,  addr0, addr1, count, writeback_addr, dep_id=-1):
    cmd = Command()
    cmd.id = id
    cmd.dep_id = dep_id
    cmd.opcode = Opcode.SUB
    cmd.addr0 = addr0
    cmd.addr1 = addr1
    cmd.count = count
    cmd.writeback_addr = writeback_addr
    return cmd

# Generate a random list of commands with different dependencies
def gen_cmd_queue(count,mem : Mem , max_dep = 10): 
    queue = CmdQueue()
    for i in range(count) :  
        cmd_type = random.randint(0,2) 
        addr0 = 0 
        addr1 = 0 
        if cmd_type == 0 :
            cmd = gen_add_cmd(i , addr_start, addr_end, random.randint(1,100), ) 
        elif cmd_type == 1 : 
            cmd = gen_sub_cmd()
        else :
            cmd = gen_mul_cmd()
        queue.add_cmd(cmd)
