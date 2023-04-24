import random
from utils import verify
def GenerateFile(name) : 
    with open(input_file, 'w') as f:
        for i in range(COUNT):
            for j in range(WIDTH):
                f.write('{:02x}'.format(random.randint(0, 255)))
                f.write('')
            f.close()











# Generate a txt file with random hex values divided into COUNT lines with WIDTH bytes per line


COUNT = 1000 # number of lines
WIDTH = 4 # bytes per line 

input_file = 'input.txt'
GenerateFile(input_file)
output_file = 'output.txt' 

# Compare two of the files and raise an error where there is a difference and mention the line and both values
verify (input_file, output_file)







