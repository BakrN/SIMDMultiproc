from model.cmd import Command, cmd_from_bin
import sys

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print ("Usage: python view_cmds.py <cmd_queue_file>")
        sys.exit(1)
    with open(sys.argv[1], "r") as f:
       lines = f.readlines()
       lines = list(map(lambda x: x.strip(), lines))
       commands = list(map(lambda x: cmd_from_bin(x), lines)) 
       f.close()

    for cmd in commands:
        print (cmd) 

