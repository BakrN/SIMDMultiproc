TITLE_COLOR = \033[33m
NO_COLOR = \033[0m

# when executing make, compile all exe's
all: product_processor

# When trying to compile one of the executables, first look for its .c files
# Then check if the libraries are in the lib folder
product_processor : main.c Matrix.c Product.c Vector.c 
	@echo "$(TITLE_COLOR)\n***** CPPCHECK *****$(NO_COLOR)"
	cppcheck --enable=all --check-config --suppress=missingIncludeSystem main.c matrix.c product.c vector.c
	@echo "$(TITLE_COLOR)\n***** COMPILING product_processor *****$(NO_COLOR)"
	gcc -c main.c      -Wall -std=c11 -Werror -o main.o      -fdiagnostics-color=auto -g
	gcc -c Matrix.c   -Wall -std=c11 -Werror -o matrix.o   -fdiagnostics-color=auto -g
	gcc -c Product.c   -Wall -std=c11 -Werror -o product.o   -fdiagnostics-color=auto -g
	gcc -c Vector.c -Wall -std=c11 -Werror -o vector.o -fdiagnostics-color=auto -g
	@echo "$(TITLE_COLOR)\n***** LINKING *****$(NO_COLOR)"
	gcc main.o matrix.o product.o vector.o -o product_processor -Wall -L./lib -Wl,-rpath=./lib -lsqlite3 -fdiagnostics-color=auto -g

# # If you only want to compile one of the libs, this target will match (e.g. make liblist)
# libdplist : lib/libdplist.so
# libtcpsock : lib/libtcpsock.so

# lib/libdplist.so : lib/dplist.c
# 	@echo "$(TITLE_COLOR)\n***** COMPILING LIB dplist *****$(NO_COLOR)"
# 	gcc -c lib/dplist.c -Wall -std=c11 -Werror -fPIC -o lib/dplist.o -fdiagnostics-color=auto
# 	@echo "$(TITLE_COLOR)\n***** LINKING LIB dplist< *****$(NO_COLOR)"
# 	gcc lib/dplist.o -o lib/libdplist.so -Wall -shared -lm -fdiagnostics-color=auto

# lib/libtcpsock.so : lib/tcpsock.c
# 	@echo "$(TITLE_COLOR)\n***** COMPILING LIB tcpsock *****$(NO_COLOR)"
# 	gcc -c lib/tcpsock.c -Wall -std=c11 -Werror -fPIC -o lib/tcpsock.o -fdiagnostics-color=auto
# 	@echo "$(TITLE_COLOR)\n***** LINKING LIB tcpsock *****$(NO_COLOR)"
# 	gcc lib/tcpsock.o -o lib/libtcpsock.so -Wall -shared -lm -fdiagnostics-color=auto

# do not look for files called clean, clean-all or this will be always a target
.PHONY : clean clean-all run zip

clean:
	rm -rf *.o sensor_gateway sensor_node file_creator gateway.log *.zip LOGFIFO  *~

clean-all: clean
	rm -rf lib/*.so

run: product_processor
	@echo "$(TITLE_COLOR)\n***** TEST RUN ACTIVE *****$(NO_COLOR)"
	./product_processor
