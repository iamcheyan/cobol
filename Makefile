.PHONY: all run build check clean

PROG = INPUTCSV
SRC  = INPUTCSV.COB
CPY  = EMP-REC.CPY
IN   = input.txt
OUT  = output.csv

all: run

build: $(PROG)

$(PROG): $(SRC) $(CPY)
	cobc -x -o $(PROG) $(SRC)

run: build
	./$(PROG)
	@echo "--- [Preview $(OUT)] ---"
	@cat $(OUT)

check:
	cobc -fsyntax-only $(SRC)
	@echo "Syntax check passed!"

clean:
	rm -f $(PROG)
