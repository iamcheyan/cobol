.PHONY: course-check course-check-sql legacy-course-check standalone-check standalone-run standalone-clean

COBC = cobc
EXAMPLES = extensions/standalone-examples
BINS = INPUTCSV FIXEDREC TBLSRCH BATCHRPT

# 32 课主课程：交付物完整性 + 全课语法检查 + 第 01 课行为 smoke。
# 第 29–32 课需要 GixSQL 预编译器，由 course-check-sql 覆盖（见下）。
course-check:
	@echo "=== 32 课主课程：交付物完整性检查 ==="
	@set -eu; for lesson in lessons/[0-9][0-9]_*; do \
		test -f "$$lesson/lesson.cob"; \
		test -f "$$lesson/README.md"; \
		test -f "$$lesson/exercise.md"; \
		test -f "$$lesson/answer.md"; \
	done
	@echo "=== 第 01–28 课语法检查（第 29–32 课见 course-check-sql） ==="
	@set -eu; for lesson in lessons/[0-9][0-9]_*; do \
		case "$$lesson" in \
			*29_*|*30_*|*31_*|*32_*) echo "SKIP $$lesson (Embedded SQL，需 GixSQL)"; continue;; \
		esac; \
		include_opt=""; \
		if [ -d "$$lesson/copybooks" ]; then include_opt="-I $$lesson/copybooks"; fi; \
		printf 'CHECK %s ... ' "$$lesson"; \
		$(COBC) -fsyntax-only $$include_opt "$$lesson"/*.cob; \
		echo OK; \
	done
	@echo "=== 第 01 课行为 smoke test ==="
	@tmp=$$(mktemp -d); trap 'rm -rf "$$tmp"' EXIT; \
		$(COBC) -fsyntax-only lessons/01_hello-cobol/lesson.cob; \
		$(COBC) -x -Wall -o "$$tmp/lesson_01" lessons/01_hello-cobol/lesson.cob; \
		output=$$("$$tmp/lesson_01"); \
		test "$$output" = 'こんにちは、COBOL！'; \
		printf '%s\n' "$$output"
	@echo "course-check PASS（语法层）：行为验收以各课 README 与第 32 课 ./check.sh 为准"

# 第 29–32 课需要 GixSQL 工具链（先在第 29 课运行 ./install-toolchain.sh）；
# 第 32 课还会跑 8 个端到端场景。
course-check-sql:
	@echo "=== 第 29–32 课：预编译 + 语法检查 ==="
	@for lesson in lessons/29_embedded-sql lessons/30_sql-cursors \
		lessons/31_data-synchronization lessons/32_bank-reconciliation-project; do \
		printf 'CHECK %s ... ' "$$lesson"; \
		(cd "$$lesson" && ./build.sh check); \
		echo OK; \
	done
	@echo "=== 第 32 课：端到端场景 ==="
	@(cd lessons/32_bank-reconciliation-project && ./check.sh)

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
