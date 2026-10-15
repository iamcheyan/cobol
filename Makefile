.PHONY: course-check legacy-course-check standalone-check standalone-run standalone-clean

COBC = cobc
EXAMPLES = extensions/standalone-examples
BINS = INPUTCSV FIXEDREC TBLSRCH BATCHRPT

# 32 课主课程的快速完整性检查与第一课 smoke test
course-check:
	@echo "=== Checking CPR #31 course and Lesson 01 ==="
	@set -eu; for lesson in lessons/[0-9][0-9]_*; do \
		test -f "$$lesson/lesson.cob"; \
		test -f "$$lesson/README.md"; \
		test -f "$$lesson/exercise.md"; \
		test -f "$$lesson/answer.md"; \
	done
	@tmp=$$(mktemp -d); trap 'rm -rf "$$tmp"' EXIT; \
		$(COBC) -fsyntax-only lessons/01_hello-cobol/lesson.cob; \
		$(COBC) -x -Wall -o "$$tmp/lesson_01" lessons/01_hello-cobol/lesson.cob; \
		output=$$("$$tmp/lesson_01"); \
		test "$$output" = 'こんにちは、COBOL！'; \
		printf '%s\n' "$$output"

legacy-course-check:
	@echo "=== Checking the optional legacy workshop ==="
	@find extensions/legacy-workshop/lessons -name '*.COB' -exec $(COBC) -I extensions/legacy-workshop/lessons/14-copybooks-redefines -fsyntax-only {} +
	@bash -n extensions/legacy-workshop/lessons/22-bash-build-run/run.sh
	@bash -n extensions/legacy-workshop/lessons/23-bash-tests-batch/test.sh
	@bash -n extensions/legacy-workshop/lessons/24-bash-pipelines-scheduling/run-pipeline.sh
	@extensions/legacy-workshop/lessons/23-bash-tests-batch/test.sh

standalone-check:
	@echo "=== Checking optional standalone examples ==="
	@cd $(EXAMPLES) && $(COBC) -fsyntax-only INPUTCSV.COB FIXEDREC.COB TBLSRCH.COB BATCHRPT.COB

standalone-run:
	@$(MAKE) -C $(EXAMPLES) run

standalone-clean:
	@$(MAKE) -C $(EXAMPLES) clean
