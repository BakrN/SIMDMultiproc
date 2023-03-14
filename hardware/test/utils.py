def verify(file1 , file2) : 
    with open(file1, 'r') as f1:
        with open(file2, 'r') as f2:
            for line1, line2 in zip(f1, f2):
                if line1 != line2:
                    print("Error at line: ", line1, line2)
                    raise Exception("Error at line: {} {} {}".format(line1, line2))
            f1.close() 
            f2.close() 