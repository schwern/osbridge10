CC=gcc
INC=-I/opt/local/include
LIBS=-L/opt/local/lib
CCFLAGS=-std=c99 -O2 -Wall -pedantic -pipe -fPIC -DNDEBUG -Werror

sound_math: sound_math.c
	$(CC) $(CCFLAGS) $(INC) $(LIBS) -o $@ ./sound_math.c -lportaudio

clean:
	-rm sound_math
