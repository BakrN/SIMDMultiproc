CC=g++
CFLAGS=-c -Wall -g -I./src/
SRC=$(wildcard src/*.cpp)
OBJ=$(patsubst src/%.cpp,%.o,$(SRC))

all: test runtest 

test: $(OBJ) test/*.cpp
	$(CC) $(OBJ) test/*.cpp $(CFLAGS) -o test/runtest
	
runtest: test
	./test/runtest

clean:
	rm -rf *.o test/runtest

%.o: src/%.cpp
	$(CC) $(CFLAGS) $< -o $@

