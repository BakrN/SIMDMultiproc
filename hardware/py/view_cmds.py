from model.cmd import Command, cmd_from_bin

with open("tests/cmd_queue.txt", "r") as f:
   lines = f.readlines()
   lines = list(map(lambda x: x.strip(), lines))
   commands = list(map(lambda x: cmd_from_bin(x), lines)) 

for cmd in commands:
    print (cmd) 

