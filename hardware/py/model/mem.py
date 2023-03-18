import random 
from typing import List

class Mem:  
    def __init__(self, count, fetch_size =4 ) -> None:
        self.count = count
        self.data = [0] * count 
        self.fetch_size = 4 
    def read(self, index):  
        return [self.data[index + i] for i in range(self.fetch_size)]
    def write(self , index, value : List, size = 4): 
        assert (len(value) == size)
        for  i in range(size) : 
            self.data[index + i] = value[i]
    def cpy(self): 
        return self.data.copy()
    def randomize(self, min = -2**8, max = 2**8-1) :  
        for i in range(self.count): 
            self.data[i] = random.randint(min, max) 
        return self 
    
class MemHexSerializer(Mem): 
    def __init__(self, mem : Mem) -> None:
        self.mem = mem
    def serialize(self , filename = "mem.txt"): 
        with open(filename, "w") as f:
            for i in range(self.mem.count): 
                f.write(hex(self.mem.data[i] &  0xFFFFFFFF)[2:])
        return 
    
        