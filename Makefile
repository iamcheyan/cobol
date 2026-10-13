.PHONY: all build check course-check legacy-course-check run clean run-csv run-fixed run-table run-report

COBC = cobc
BINS = INPUTCSV FIXEDREC TBLSRCH BATCHRPT

all: build

build: $(BINS)

check:
	@echo "=== Checking Syntax for all COBOL programs ==="
	$(COBC) -fsyntax-only INPUTCSV.COB
	$(COBC) -fsyntax-only FIXEDREC.COB
	$(COBC) -fsyntax-only TBLSRCH.COB
	$(COBC) -fsyntax-only BATCHRPT.COB
	@echo "✓ All COBOL programs passed syntax check!"

course-check:
	@echo "=== Checking CPR #31 course and Lesson 01 ==="
	@set -eu; for lesson in lessons/[0-9][0-9]; do \
		test -f "$$lesson/lesson_$${lesson##*/}.cob"; \
		test -f "$$lesson/README.md"; \
		test -f "$$lesson/exercise.md"; \
		test -f "$$lesson/answer.md"; \
	done
	@tmp=$$(mktemp -d); trap 'rm -rf "$$tmp"' EXIT; \
		$(COBC) -fsyntax-only lessons/01/lesson_01.cob; \
		$(COBC) -x -Wall -o "$$tmp/lesson_01" lessons/01/lesson_01.cob; \
		output=$$("$$tmp/lesson_01"); \
		test "$$output" = 'Hello, COBOL!'; \
		printf '%s\n' "$$output"

legacy-course-check:
	@echo "=== Checking the legacy workshop lessons ==="
	@find extensions/legacy-workshop/lessons -name '*.COB' -exec $(COBC) -I extensions/legacy-workshop/lessons/14-copybooks-redefines -fsyntax-only {} +
	@bash -n extensions/legacy-workshop/lessons/22-bash-build-run/run.sh
	@bash -n extensions/legacy-workshop/lessons/23-bash-tests-batch/test.sh
	@bash -n extensions/legacy-workshop/lessons/24-bash-pipelines-scheduling/run-pipeline.sh
	@extensions/legacy-workshop/lessons/23-bash-tests-batch/test.sh

INPUTCSV: INPUTCSV.COB EMP-REC.CPY
	$(COBC) -x -o $@ $<

FIXEDREC: FIXEDREC.COB TX-REC.CPY
	$(COBC) -x -o $@ $<

TBLSRCH: TBLSRCH.COB
	$(COBC) -x -o $@ $<

BATCHRPT: BATCHRPT.COB
	$(COBC) -x -o $@ $<

run: build run-csv run-fixed run-table run-report
	@echo ""
	@echo "=================================================="
	@echo "✓ All 4 COBOL demo programs executed successfully!"
	@echo "=================================================="

run-csv: INPUTCSV
	@echo ""
	@echo ">>> [1/4] Running INPUTCSV (Pipe-delimited to CSV)..."
	./INPUTCSV
	@echo "--- [Preview output.csv] ---"
	@cat output.csv

run-fixed: FIXEDREC tx_input.dat
	@echo ""
	@echo ">>> [2/4] Running FIXEDREC (80-col Fixed Records & REDEFINES)..."
	./FIXEDREC
	@echo "--- [Preview tx_report.txt] ---"
	@cat tx_report.txt

run-table: TBLSRCH
	@echo ""
	@echo ">>> [3/4] Running TBLSRCH (Tables, OCCURS & SEARCH ALL)..."
	./TBLSRCH

run-report: BATCHRPT sales_data.txt
	@echo ""
	@echo ">>> [4/4] Running BATCHRPT (Two-level Control Break Audit)..."
	./BATCHRPT
	@echo "--- [Preview sales_report.txt] ---"
	@cat sales_report.txt

clean:
	rm -f $(BINS) output.csv tx_report.txt sales_report.txt
