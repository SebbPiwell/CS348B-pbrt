###########################################################################
# user-configurable section
###########################################################################

# common locations for the OpenEXR libraries; may need to be updated
# for unusual installation locations
HAVE_EXR=1
EXR_INCLUDES=-I/usr/local/include/OpenEXR -I/usr/include/OpenEXR -I/opt/local/include/OpenEXR 
EXR_LIBDIR=-L/usr/local/lib -L/opt/local/lib

HAVE_LIBTIFF=1	
TIFF_INCLUDES=-I/usr/local/include -I/opt/local/include
TIFF_LIBDIR=-L/usr/local/lib -L/opt/local/lib

HAVE_DTRACE=0

# remove -DPBRT_HAS_OPENEXR to build without OpenEXR support
DEFS=-DPBRT_HAS_OPENEXR

# 32 bit
#MARCH=-m32 -msse2 -mfpmath=sse

# 64 bit
MARCH=-m64

# change this to -g3 for debug builds
# no debug -03
OPT=-O3
# comment out this line to enable assertions at runtime
DEFS += -DNDEBUG

#########################################################################
# nothing below this line should need to be changed (usually)
#########################################################################

ARCH = $(shell uname)

LEX=flex
YACC=bison -d -v -t
ifeq ($(ARCH),OpenBSD)
    LEXLIB = -ll
else
    LEBLIB = -lfl
endif

ifeq ($(HAVE_DTRACE),1)
    DEFS += -DPBRT_PROBES_DTRACE
else
    DEFS += -DPBRT_PROBES_NONE
endif

EXRLIBS=$(EXR_LIBDIR) -Bstatic -lIex -lIlmImf -lIlmThread -lImath -lIex -lHalf -Bdynamic
ifeq ($(ARCH),Linux)
  EXRLIBS += -lpthread
endif
ifeq ($(ARCH),OpenBSD)
  EXRLIBS += -lpthread
endif
ifeq ($(ARCH),Darwin)
  EXRLIBS += -lz
endif

CC=gcc
CXX=g++
LD=$(CXX) $(OPT) $(MARCH)
INCLUDE=-I. -Icore $(EXR_INCLUDES) $(TIFF_INCLUDES)
WARN=-Wall
CWD=$(shell pwd)
CXXFLAGS=$(OPT) $(MARCH) $(INCLUDE) $(WARN) $(DEFS)
CCFLAGS=$(CXXFLAGS)
LIBS=$(LEXLIB) $(EXR_LIBDIR) $(EXRLIBS) -lm 

LIB_CSRCS=core/targa.c
LIB_CXXSRCS  = $(wildcard core/*.cpp) core/pbrtlex.cpp core/pbrtparse.cpp
LIB_CXXSRCS += $(wildcard accelerators/*.cpp cameras/*.cpp film/*.cpp filters/*.cpp )
LIB_CXXSRCS += $(wildcard integrators/*.cpp lights/*.cpp materials/*.cpp renderers/*.cpp )
LIB_CXXSRCS += $(wildcard samplers/*.cpp shapes/*.cpp textures/*.cpp volumes/*.cpp)

LIBOBJS  = $(addprefix objs/, $(subst /,_,$(LIB_CSRCS:.c=.o)))
LIBOBJS += $(addprefix objs/, $(subst /,_,$(LIB_CXXSRCS:.cpp=.o)))

HEADERS = $(wildcard */*.h)

TOOLS = bin/bsdftest bin/exravg bin/exrdiff bin/obj2pbrt
ifeq ($(HAVE_LIBTIFF),1)
    TOOLS += bin/exrtotiff
endif

default: dirs bin/pbrt $(TOOLS)

bin/%: dirs

pbrt: bin/pbrt

dirs:
	/bin/mkdir -p bin objs

$(LIBOBJS): $(HEADERS)

.PHONY: dirs tools 
.SECONDARY:

objs/libpbrt.a: $(LIBOBJS)
	@echo "Building the core rendering library (libpbrt.a)"
	@ar rcs $@ $(LIBOBJS)

objs/accelerators_%.o: accelerators/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/cameras_%.o: cameras/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/core_%.o: core/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/core_%.o: core/%.c
	@echo "Building object $@"
	@$(CC) $(CCFLAGS) -o $@ -c $<

objs/film_%.o: film/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/filters_%.o: filters/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/integrators_%.o: integrators/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/lights_%.o: lights/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/main_%.o: main/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/materials_%.o: materials/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/renderers_%.o: renderers/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/samplers_%.o: samplers/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/shapes_%.o: shapes/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/textures_%.o: textures/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/volumes_%.o: volumes/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/pbrt.o: main/pbrt.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

objs/tools_%.o: tools/%.cpp
	@echo "Building object $@"
	@$(CXX) $(CXXFLAGS) -o $@ -c $<

bin/pbrt: objs/main_pbrt.o objs/libpbrt.a
	@echo "Linking $@"
	@$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

bin/%: objs/tools_%.o objs/libpbrt.a 
	@echo "Linking $@"
	@$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

bin/exrtotiff: objs/tools_exrtotiff.o 
	@echo "Linking $@"
	@$(CXX) $(CXXFLAGS) -o $@ $^ $(TIFF_LIBDIR) -ltiff $(LIBS) 

core/pbrtlex.cpp: core/pbrtlex.ll core/pbrtparse.cpp
	@echo "Lex'ing pbrtlex.ll"
	@$(LEX) -o$@ core/pbrtlex.ll

core/pbrtparse.cpp: core/pbrtparse.yy
	@echo "YACC'ing pbrtparse.yy"
	@$(YACC) -o $@ core/pbrtparse.yy
	@if [ -e core/pbrtparse.cpp.h ]; then /bin/mv core/pbrtparse.cpp.h core/pbrtparse.hh; fi
	@if [ -e core/pbrtparse.hpp ]; then /bin/mv core/pbrtparse.hpp core/pbrtparse.hh; fi

ifeq ($(HAVE_DTRACE),1)
core/dtrace.h: core/dtrace.d
	/usr/sbin/dtrace -h -s $^ -o $@

$(LIBOBJS): core/dtrace.h
endif

$(RENDERER_BINARY): $(RENDERER_OBJS) $(CORE_LIB)

clean:
	rm -f objs/* bin/* core/pbrtlex.[ch]* core/pbrtparse.[ch]*
