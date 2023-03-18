from model.cmd import Command , Status , Opcode
from model.mem import Mem
from enum import Enum
class ProcState(Enum): 
    IDLE = 0 
    RUNNING = 1

class Processor: 
    def __init__(self, width = 4) :  
        self.state = ProcState.IDLE 
        self.width = width 
    def is_busy(self): 
        return self.state != ProcState.IDLE 
    def run(self, mem : Mem) : 
        if self.state != ProcState.RUNNING:
            return False
        data0 = mem.read(self.cmd.addr0)
        data1 = mem.read(self.cmd.addr1)
        if self.cmd.opcode == Opcode.ADD:
            out = list(map(lambda x,y : x+y, data0, data1))
        elif self.cmd.opcode == Opcode.sub:
            out = list(map(lambda x,y : x-y, data0, data1))
        else :
            out = list(map(lambda x,y : x*y, data0, data1))
        mem.write(self.cmd.writeback_addr, out , self.cmd.count % self.width+1)
        if self.cmd.count <self.width : 
            self.cmd_count = 0 
            self.cmd.status = Status.DONE 
            self.state = ProcState.IDLE
        self.cmd.count -= self.width
        self.data0+= self.width
        self.data1+= self.width
        self.writeback_addr+= self.width 
        return True
    def assign_cmd(self, cmd: Command): # returns true if successful
        if self.is_busy():
            return False
        cmd.status = Status.RUNNING
        self.cmd = cmd 
        self.state = ProcState.RUNNING 
        return True
    def Idle(self): 
        self.state = ProcState.IDLE

class Pool: 
    def __init__(self , proc_count = 4) -> None: 
        self.procs = [Processor() for i in range(proc_count)]
        self.size = proc_count
    def run(self, mem : Mem): 
        for proc in self.procs:
            proc.run(mem)
    def assign_cmd(self, cmd : Command ):
        for proc in self.procs:
            if proc.assign_cmd(cmd):
                return True
        return False
    def busy(self): # returns number of busy processors
        count = 0 
        for proc in self.procs:
            if proc.is_busy():
                count += 1
        return count


 