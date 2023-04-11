CC=g++
CFLAGS=-c -Wall -g

all: program test runtest

program: *.cpp
	$(CC) *.cpp -o test 

test:  test/*.cpp
	$(CC) test/*.cpp -o test/runtest
runtest: test
	./test/runtest
clean:
	rm -rf *o test

