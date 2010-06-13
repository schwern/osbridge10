# Where to find portaudio
INC=$(shell pkg-config portaudio-2.0 --cflags)
LIBS=$(shell pkg-config portaudio-2.0 --libs)

SPEECH_CMD=say -v cello
#SPEECH_CMD=festival --tts

# General flags for the C compiler
CCFLAGS=-std=c99 -O2 -Wall -pedantic -pipe -fPIC -DNDEBUG -Werror

# Project configuration flags
CONFIG_FLAGS=-DSPEECH_CMD='$(SPEECH_CMD)'

sound_math: Makefile sound_math.c
	$(CC) $(CCFLAGS) $(INC) $(LIBS) $(CONFIG_FLAGS) -o $@ ./sound_math.c -lportaudio

clean:
	-rm sound_math
