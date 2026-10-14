COBC ?= cobc
BINS = INPUTCSV FIXEDREC TBLSRCH BATCHRPT

.PHONY: all build check run clean run-csv run-fixed run-table run-report

all: build

build: $(BINS)

check:
	@echo "=== Checking syntax for standalone COBOL examples ==="
	$(COBC) -fsyntax-only INPUTCSV.COB
	$(COBC) -fsyntax-only FIXEDREC.COB
	$(COBC) -fsyntax-only TBLSRCH.COB
	$(COBC) -fsyntax-only BATCHRPT.COB
	@echo "All standalone examples passed syntax check."

INPUTCSV: INPUTCSV.COB EMP-REC.CPY
	$(COBC) -x -o $@ $<

FIXEDREC: FIXEDREC.COB TX-REC.CPY
	$(COBC) -x -o $@ $<

TBLSRCH: TBLSRCH.COB
	$(COBC) -x -o $@ $<

BATCHRPT: BATCHRPT.COB
	$(COBC) -x -o $@ $<

run: build run-csv run-fixed run-table run-report
	@echo "All 4 standalone COBOL examples executed successfully."

run-csv: INPUTCSV
	./INPUTCSV
	@cat output.csv

run-fixed: FIXEDREC tx_input.dat
	./FIXEDREC
	@cat tx_report.txt

run-table: TBLSRCH
	./TBLSRCH

run-report: BATCHRPT sales_data.txt
	./BATCHRPT
	@cat sales_report.txt

clean:
	rm -f $(BINS) output.csv tx_report.txt sales_report.txt
