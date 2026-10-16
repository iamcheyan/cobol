"""Content for the reference / cheat-sheet page.

Every table here was checked against the GnuCOBOL 3.2 compiler in this
repository (`cobc`) and the official GnuCOBOL Quick Reference; the byte sizes
and file status codes are measured, not assumed. The page is trilingual.
"""

REFERENCE = {
    "zh-cn": {
        "eyebrow": "REFERENCE",
        "title": "COBOL 速查手册",
        "lead": "一页查到最常用的东西：固定格式的列规则、程序骨架、数据定义、PIC 符号、常用语句与文件状态码。表中的字节数与状态码都在 GnuCOBOL 3.2 上实测过。",
        "note": "这里的字节数是 GnuCOBOL 在 Linux/x86-64 上的实测结果，用于快速核对；生产接口长度仍应以目标编译器和平台规则为准。",
        "search_label": "在本页筛选",
        "search_placeholder": "输入关键字，如 PIC、OCCURS、PERFORM、35",
        "no_match": "没有匹配的条目。",
        "sections": [
            {
                "id": "format",
                "title": "固定格式的列",
                "kind": "table",
                "head": ["列", "区域", "写什么"],
                "rows": [
                    ("1–6", "序号区", "传统上放卡片编号；现代源码通常留空"),
                    ("7", "指示区", "空格＝正文，`*`＝注释，`/`＝换页，`-`＝续行"),
                    ("8–11", "Area A", "`DIVISION`、`SECTION`、段落名、`01`/`77` 级、`FD`/`SD`"),
                    ("12–72", "Area B", "语句、子句、`02`–`49` 级与 `88` 级"),
                    ("73–80", "标识区", "编译器忽略；正文不要越过第 72 列"),
                ],
                "after": [
                    "`source_format = \"free\"` 时不用这些列区；GnuCOBOL 也会对非固定格式的文件给出 `free format detected` 提示。",
                ],
            },
            {
                "id": "skeleton",
                "title": "程序骨架",
                "kind": "code",
                "code": """       IDENTIFICATION DIVISION.
       PROGRAM-ID. MYPROG.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO "in.txt"
               FILE STATUS IS WS-STATUS
               ORGANIZATION IS LINE SEQUENTIAL.
       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE.
       01  IN-REC              PIC X(80).
       WORKING-STORAGE SECTION.
       01  WS-STATUS           PIC XX.
       01  WS-EOF              PIC X VALUE "N".
           88  EOF-YES         VALUE "Y".
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INIT
           PERFORM 2000-PROCESS UNTIL EOF-YES
           PERFORM 9000-FINISH
           STOP RUN.
       1000-INIT.
           OPEN INPUT IN-FILE.
       2000-PROCESS.
           READ IN-FILE
               AT END SET EOF-YES TO TRUE
               NOT AT END DISPLAY IN-REC
           END-READ.
       9000-FINISH.
           CLOSE IN-FILE.""",
                "after": [
                    "四个 Division 的顺序是固定的；`PROCEDURE DIVISION` 里用 `PERFORM` 把流程拆成命名段落，是本课程的默认写法。",
                ],
            },
            {
                "id": "levels",
                "title": "数据层级与子句",
                "kind": "table",
                "head": ["层级", "含义"],
                "rows": [
                    ("`01`", "记录（最外层数据项）"),
                    ("`02`–`49`", "组项或基本项，数字越大层级越深"),
                    ("`66`", "`RENAMES`，为已有字段重新组合视图"),
                    ("`77`", "独立的单字段，不能有下级"),
                    ("`88`", "条件名，为上级字段的取值起名字，不占存储"),
                ],
                "after": [
                    "常用子句：`PIC`（格式）、`USAGE`（存储方式）、`VALUE`（初值）、`OCCURS`（重复）、`REDEFINES`（重叠视图）、`SIGN`（符号位置）、`BLANK WHEN ZERO`。",
                ],
                "table2_title": "定义规则",
                "table2_head": ["规则", "说明"],
                "table2_rows": [
                    ("层级编号", "从 `01` 开始，下级编号必须大于上级；同一层可重复"),
                    ("组项", "只有层级编号和名字，不带 `PIC`；长度由下级字段累加"),
                    ("基本项", "带 `PIC`，是真正占用存储的最小单位"),
                    ("`88` 条件名", "必须紧跟在它描述的字段之后，不占存储"),
                    ("`VALUE`", "只对基本项和 `88` 级有效，组项上无意义"),
                    ("`FILLER`", "占位字段，可以不写名字，不能用 `OF` 限定引用"),
                ],
            },
            {
                "id": "pic",
                "title": "PIC 符号",
                "kind": "table",
                "intro": "`PIC` 描述字段的显示格式。下表为常用符号。",
                "head": ["符号", "含义"],
                "rows": [
                    ("`9`", "一位数字"),
                    ("`X`", "一个任意字符"),
                    ("`A`", "一个字母或空格"),
                    ("`V`", "隐含小数点，不占存储"),
                    ("`S`", "符号位（默认与末位数字合并，不额外占字节）"),
                    ("`P`", "假定的小数点位置，用于定标（如 `PIC 9(3)P(2)`）"),
                    ("`Z`", "前导零替换为空格（`PIC ZZZ9` 的 `42` 显示为 `  42`）"),
                    ("`*`", "前导零替换为星号（`PIC ***9` 的 `42` 显示为 `**42`）"),
                    ("`,`", "插入千分位逗号"),
                    ("`.`", "插入小数点"),
                    ("`+` / `-`", "插入正负号（`PIC +99999` 的 `42` 显示为 `+00042`）"),
                    ("`CR` / `DB`", "负值时在末尾显示 `CR` 或 `DB`"),
                    ("`B`", "插入一个空格（`PIC B99999B` 显示为 ` 00042 `）"),
                    ("`/`", "插入斜杠（`PIC 999/99` 显示为 `000/42`）"),
                    ("`0`", "插入固定零（`PIC 99900` 显示为 `04200`）"),
                    ("`$`", "浮动货币符号（`PIC $$$,$$$,$$9.99` 的 `12500` 显示为 `    $12,500.00`）"),
                ],
                "after": [
                    "重复次数用括号写：`PIC X(20)` 等价于 `PIC XXXXXXXXXXXXXXXXXXXX`。编辑符号（`Z * , . + - CR DB B / 0 $`）只影响显示，不改变数值本身。",
                ],
            },
            {
                "id": "usage",
                "title": "USAGE 与实测字节数",
                "kind": "table",
                "intro": "`USAGE` 决定存储方式。下表的字节数是 GnuCOBOL 3.2 上用 `FUNCTION LENGTH` 实测的结果。",
                "head": ["声明", "存储方式", "实测字节"],
                "rows": [
                    ("`PIC 9(1)`–`9(2)` `COMP`", "二进制", "1"),
                    ("`PIC 9(3)`–`9(4)` `COMP`", "二进制", "2"),
                    ("`PIC 9(5)`–`9(9)` `COMP`", "二进制", "4"),
                    ("`PIC 9(10)`–`9(18)` `COMP`", "二进制", "8"),
                    ("`PIC S9(7) COMP-3`", "压缩十进制", "4"),
                    ("`PIC S9(7)V99 COMP-3`", "压缩十进制", "5"),
                    ("`PIC X(20)`", "`DISPLAY`", "20"),
                    ("`PIC 9(5)V99`", "`DISPLAY`", "7"),
                    ("`PIC S9(5)`", "`DISPLAY`（符号并入末位）", "5"),
                    ("`PIC S9(5) SIGN IS LEADING SEPARATE`", "`DISPLAY`（独立符号位）", "6"),
                ],
                "after": [
                    "**`COMP-3` 的估算公式**：`ceil((数字位数 + 1) / 2)`。例如 `S9(7)V99 COMP-3` 有 9 位数字，加 1 个符号半字节共 10 个半字节，即 5 字节。",
                    "**`COMP` 的边界**：1–2 位→1 字节，3–4 位→2 字节，5–9 位→4 字节，10–18 位→8 字节。这是 GnuCOBOL 的方案，其他编译器可能不同。",
                ],
            },
            {
                "id": "statements",
                "title": "常用语句",
                "kind": "table",
                "head": ["语句", "用途", "写法要点"],
                "rows": [
                    ("`MOVE`", "赋值", "`MOVE A TO B`；数值按接收方格式截断或补零"),
                    ("`ADD` / `SUBTRACT`", "加减", "`ADD 1 TO N`；可带 `GIVING`、`ON SIZE ERROR`"),
                    ("`MULTIPLY` / `DIVIDE`", "乘除", "`DIVIDE A BY B GIVING C`；除零用 `ON SIZE ERROR` 捕获"),
                    ("`COMPUTE`", "表达式计算", "`COMPUTE X = A + B * 2`；小数位按接收方字段决定"),
                    ("`IF` / `ELSE` / `END-IF`", "条件分支", "块必须以 `END-IF` 结束，不要只靠句点"),
                    ("`EVALUATE`", "多路分支", "`EVALUATE TRUE` 或 `EVALUATE 变量`，分支用 `WHEN`，结尾 `END-EVALUATE`"),
                    ("`PERFORM`", "执行段落或循环", "`PERFORM 段落`；循环用 `PERFORM UNTIL 条件` 或 `PERFORM n TIMES`"),
                    ("`PERFORM VARYING`", "计数循环", "`PERFORM VARYING I FROM 1 BY 1 UNTIL I > 10`"),
                    ("`INITIALIZE`", "重置字段", "把字段设回类型默认值；可用 `REPLACING` 只重置部分"),
                    ("`SET`", "设置条件名/索引", "`SET EOF-YES TO TRUE`；切换 `88` 条件名或调整索引"),
                    ("`STRING`", "拼接字符串", "`STRING A B DELIMITED BY SIZE INTO C END-STRING`"),
                    ("`UNSTRING`", "拆分字符串", "`UNSTRING S DELIMITED BY \"|\" INTO A B C END-UNSTRING`"),
                    ("`INSPECT`", "计数/替换字符", "`INSPECT S TALLYING N FOR ALL \"x\"`、`REPLACING`"),
                    ("`DISPLAY`", "输出到标准输出", "`DISPLAY A B`；调试和批处理日志常用"),
                    ("`ACCEPT`", "从标准输入读取", "`ACCEPT WS-LINE`"),
                    ("`OPEN` / `CLOSE`", "打开/关闭文件", "`OPEN INPUT F`、`OPEN OUTPUT F`、`CLOSE F`"),
                    ("`READ`", "读一条记录", "`READ F AT END ... NOT AT END ... END-READ`"),
                    ("`WRITE` / `REWRITE`", "写出/更新记录", "`WRITE REC`、`REWRITE REC`（需先成功 `READ`）"),
                    ("`DELETE`", "删除记录", "用于索引/相对文件；顺序文件不支持"),
                    ("`START`", "定位到指定键", "配合 `READ NEXT` 使用"),
                    ("`CALL` / `USING`", "调用子程序", "`CALL \"SUBPROG\" USING A B`；参数在 `LINKAGE SECTION` 声明"),
                    ("`SORT`", "排序文件或表", "可带 `INPUT PROCEDURE` / `OUTPUT PROCEDURE`"),
                    ("`SEARCH` / `SEARCH ALL`", "表查找", "`SEARCH ALL` 要求带 `ASCENDING/DESCENDING KEY`，为二分查找"),
                    ("`GO TO`", "无条件跳转", "维护旧代码会遇到；新代码优先用 `PERFORM`"),
                    ("`STOP RUN` / `GOBACK`", "结束程序", "`STOP RUN` 终止运行；子程序用 `GOBACK` 返回"),
                ],
            },
            {
                "id": "status",
                "title": "文件状态码（`FILE STATUS`）",
                "kind": "table",
                "intro": "在 `FILE-CONTROL` 里声明 `FILE STATUS IS WS-STATUS`，每次文件操作后检查。下表为实测常见值。",
                "head": ["状态码", "含义"],
                "rows": [
                    ("`00`", "操作成功"),
                    ("`10`", "已到文件末尾（`READ` 的 `AT END`）"),
                    ("`22`", "重复键（索引文件）"),
                    ("`23`", "找不到记录（索引文件）"),
                    ("`35`", "打开时文件不存在（缺少输入文件时实测得到）"),
                    ("`37`", "打开文件时权限不足"),
                    ("`39`", "文件属性与程序声明冲突"),
                    ("`41`", "文件已被打开"),
                    ("`42`", "文件未打开"),
                    ("`46`", "文件已读到末尾，无法继续读取"),
                    ("`47`", "对已关闭的文件执行 I/O（实测得到）"),
                    ("`9x`", "运行时或系统级错误，需查 GnuCOBOL 文档"),
                ],
                "after": [
                    "`35`、`47` 等值由本机 GnuCOBOL 3.2 实测确认；不同实现可能有额外状态码，遇到未列出的值请查官方文档。",
                ],
            },
            {
                "id": "compare",
                "title": "条件与比较",
                "kind": "table",
                "head": ["写法", "含义"],
                "rows": [
                    ("`=` / `EQUAL TO`", "相等"),
                    ("`NOT =` / `NOT EQUAL TO`", "不相等"),
                    ("`>` / `LESS THAN`", "比较大小"),
                    ("`IS NUMERIC`", "是否为数字"),
                    ("`IS ALPHABETIC`", "是否全为字母"),
                    ("`IS SPACES` / `IS ZERO`", "是否为空格 / 零"),
                    ("`AND` / `OR` / `NOT`", "逻辑组合"),
                    ("`88` 条件名", "`IF EOF-YES` 直接判断字段是否等于其 `VALUE`"),
                ],
                "after": [
                    "数值比较按数值语义，字符比较按字符顺序；`COMP`、`COMP-3` 与 `DISPLAY` 字段混用比较时，先确认双方都是数值项。",
                ],
            },
            {
                "id": "compiler",
                "title": "常用 `cobc` 命令",
                "kind": "table",
                "head": ["命令", "用途"],
                "rows": [
                    ("`cobc -fsyntax-only PROG.COB`", "只做语法检查，不生成文件"),
                    ("`cobc -x -o PROG PROG.COB`", "编译并链接为可执行程序"),
                    ("`cobc -m -o MOD.so MOD.COB`", "编译为可被 `CALL` 的模块"),
                    ("`cobc -I copy ...`", "指定 Copybook 搜索目录"),
                    ("`cobc -free PROG.COB`", "按自由格式编译"),
                    ("`cobc -fixed PROG.COB`", "按固定格式编译"),
                    ("`cobc -Wall PROG.COB`", "开启全部警告"),
                    ("`cobc -std=default`", "使用默认方言（不要随意用 `-std=cobol85`）"),
                ],
                "after": [
                    "课程里的 `make -C extensions/standalone-examples check` 用的就是 `-fsyntax-only`；插件 `<leader>cl` 调用的也是同一条路径。",
                ],
            },
        ],
    },
    "en": {
        "eyebrow": "REFERENCE",
        "title": "COBOL reference sheet",
        "lead": "One page for the things you look up most: fixed-format columns, program skeleton, data definitions, PICTURE symbols, common statements and file status codes. Every byte count and status code was measured on GnuCOBOL 3.2.",
        "note": "Byte counts are measured on GnuCOBOL 3.2 for Linux/x86-64 and are meant for quick checking; production interface lengths should still follow the target compiler and platform rules.",
        "search_label": "Filter this page",
        "search_placeholder": "Type a keyword, e.g. PIC, OCCURS, PERFORM, 35",
        "no_match": "No matching entries.",
        "sections": [
            {
                "id": "format",
                "title": "Fixed-format columns",
                "kind": "table",
                "head": ["Columns", "Area", "What goes there"],
                "rows": [
                    ("1–6", "Sequence", "Traditionally a card number; modern source usually leaves it blank"),
                    ("7", "Indicator", "Blank = source, `*` = comment, `/` = page eject, `-` = continuation"),
                    ("8–11", "Area A", "`DIVISION`, `SECTION`, paragraph names, level `01`/`77`, `FD`/`SD`"),
                    ("12–72", "Area B", "Statements, clauses, levels `02`–`49` and `88`"),
                    ("73–80", "Identification", "Ignored by the compiler; never write source past column 72"),
                ],
                "after": [
                    "With `source_format = \"free\"` these areas do not apply; GnuCOBOL also prints `free format detected` for source that is not fixed format.",
                ],
            },
            {
                "id": "skeleton",
                "title": "Program skeleton",
                "kind": "code",
                "code": """       IDENTIFICATION DIVISION.
       PROGRAM-ID. MYPROG.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO "in.txt"
               FILE STATUS IS WS-STATUS
               ORGANIZATION IS LINE SEQUENTIAL.
       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE.
       01  IN-REC              PIC X(80).
       WORKING-STORAGE SECTION.
       01  WS-STATUS           PIC XX.
       01  WS-EOF              PIC X VALUE "N".
           88  EOF-YES         VALUE "Y".
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INIT
           PERFORM 2000-PROCESS UNTIL EOF-YES
           PERFORM 9000-FINISH
           STOP RUN.
       1000-INIT.
           OPEN INPUT IN-FILE.
       2000-PROCESS.
           READ IN-FILE
               AT END SET EOF-YES TO TRUE
               NOT AT END DISPLAY IN-REC
           END-READ.
       9000-FINISH.
           CLOSE IN-FILE.""",
                "after": [
                    "The four divisions always appear in this order. Inside `PROCEDURE DIVISION`, `PERFORM` splits the flow into named paragraphs — the default style in this course.",
                ],
            },
            {
                "id": "levels",
                "title": "Data levels and clauses",
                "kind": "table",
                "head": ["Level", "Meaning"],
                "rows": [
                    ("`01`", "A record (the outermost data item)"),
                    ("`02`–`49`", "Group or elementary items; a higher number is a deeper level"),
                    ("`66`", "`RENAMES`: a new view over existing fields"),
                    ("`77`", "A standalone item that cannot have subordinates"),
                    ("`88`", "A condition name that names values of its parent; occupies no storage"),
                ],
                "after": [
                    "Common clauses: `PIC` (format), `USAGE` (storage), `VALUE` (initial value), `OCCURS` (repetition), `REDEFINES` (overlapping view), `SIGN` (sign position), `BLANK WHEN ZERO`.",
                ],
                "table2_title": "Definition rules",
                "table2_head": ["Rule", "Detail"],
                "table2_rows": [
                    ("Level numbers", "Start at `01`; a subordinate must use a larger number; numbers may repeat within a level"),
                    ("Group item", "Only a level number and a name, with no `PIC`; its length is the sum of its subordinates"),
                    ("Elementary item", "Has a `PIC` and is the smallest unit that actually occupies storage"),
                    ("`88` condition name", "Must immediately follow the field it describes; occupies no storage"),
                    ("`VALUE`", "Only meaningful on elementary items and `88` levels, not on groups"),
                    ("`FILLER`", "A placeholder that may be unnamed and cannot be referenced with `OF`"),
                ],
            },
            {
                "id": "pic",
                "title": "PICTURE symbols",
                "kind": "table",
                "intro": "`PIC` describes a field's display format. These are the symbols you meet most often.",
                "head": ["Symbol", "Meaning"],
                "rows": [
                    ("`9`", "One digit"),
                    ("`X`", "One character of any kind"),
                    ("`A`", "One letter or space"),
                    ("`V`", "Assumed decimal point; occupies no storage"),
                    ("`S`", "Sign (merged with the last digit by default, costing no extra byte)"),
                    ("`P`", "Assumed scaling position, e.g. `PIC 9(3)P(2)`"),
                    ("`Z`", "Suppress leading zeros as spaces (`PIC ZZZ9` shows `42` as `  42`)"),
                    ("`*`", "Suppress leading zeros as asterisks (`PIC ***9` shows `42` as `**42`)"),
                    ("`,`", "Insert a thousands separator"),
                    ("`.`", "Insert a decimal point"),
                    ("`+` / `-`", "Insert a sign (`PIC +99999` shows `42` as `+00042`)"),
                    ("`CR` / `DB`", "Append `CR` or `DB` for negative values"),
                    ("`B`", "Insert a space (`PIC B99999B` shows ` 00042 `)"),
                    ("`/`", "Insert a slash (`PIC 999/99` shows `000/42`)"),
                    ("`0`", "Insert a fixed zero (`PIC 99900` shows `04200`)"),
                    ("`$`", "Floating currency symbol (`PIC $$$,$$$,$$9.99` shows `12500` as `    $12,500.00`)"),
                ],
                "after": [
                    "Write repetition counts in parentheses: `PIC X(20)` equals `PIC XXXXXXXXXXXXXXXXXXXX`. Editing symbols (`Z * , . + - CR DB B / 0 $`) affect display only; they do not change the value.",
                ],
            },
            {
                "id": "usage",
                "title": "USAGE and measured sizes",
                "kind": "table",
                "intro": "`USAGE` selects the storage format. The sizes below were measured with `FUNCTION LENGTH` on GnuCOBOL 3.2.",
                "head": ["Declaration", "Storage", "Measured bytes"],
                "rows": [
                    ("`PIC 9(1)`–`9(2)` `COMP`", "Binary", "1"),
                    ("`PIC 9(3)`–`9(4)` `COMP`", "Binary", "2"),
                    ("`PIC 9(5)`–`9(9)` `COMP`", "Binary", "4"),
                    ("`PIC 9(10)`–`9(18)` `COMP`", "Binary", "8"),
                    ("`PIC S9(7) COMP-3`", "Packed decimal", "4"),
                    ("`PIC S9(7)V99 COMP-3`", "Packed decimal", "5"),
                    ("`PIC X(20)`", "`DISPLAY`", "20"),
                    ("`PIC 9(5)V99`", "`DISPLAY`", "7"),
                    ("`PIC S9(5)`", "`DISPLAY` (sign merged into the last digit)", "5"),
                    ("`PIC S9(5) SIGN IS LEADING SEPARATE`", "`DISPLAY` (separate sign byte)", "6"),
                ],
                "after": [
                    "**Estimating `COMP-3`**: `ceil((digits + 1) / 2)`. `S9(7)V99 COMP-3` has 9 digits plus a sign nibble, so 10 nibbles = 5 bytes.",
                    "**`COMP` boundaries**: 1–2 digits → 1 byte, 3–4 → 2, 5–9 → 4, 10–18 → 8. This is GnuCOBOL's scheme; other compilers may differ.",
                ],
            },
            {
                "id": "statements",
                "title": "Common statements",
                "kind": "table",
                "head": ["Statement", "Purpose", "Notes"],
                "rows": [
                    ("`MOVE`", "Assign a value", "`MOVE A TO B`; numeric receivers truncate or pad to their own format"),
                    ("`ADD` / `SUBTRACT`", "Add and subtract", "`ADD 1 TO N`; supports `GIVING` and `ON SIZE ERROR`"),
                    ("`MULTIPLY` / `DIVIDE`", "Multiply and divide", "`DIVIDE A BY B GIVING C`; catch division by zero with `ON SIZE ERROR`"),
                    ("`COMPUTE`", "Evaluate an expression", "`COMPUTE X = A + B * 2`; the receiver's decimals decide rounding"),
                    ("`IF` / `ELSE` / `END-IF`", "Conditional branch", "Terminate the block with `END-IF`, not just a period"),
                    ("`EVALUATE`", "Multi-way branch", "`EVALUATE TRUE` or `EVALUATE field`, branches via `WHEN`, ends with `END-EVALUATE`"),
                    ("`PERFORM`", "Run a paragraph or loop", "`PERFORM para`; loops use `PERFORM UNTIL` or `PERFORM n TIMES`"),
                    ("`PERFORM VARYING`", "Counting loop", "`PERFORM VARYING I FROM 1 BY 1 UNTIL I > 10`"),
                    ("`INITIALIZE`", "Reset fields", "Restores type defaults; `REPLACING` resets only part"),
                    ("`SET`", "Set a condition name or index", "`SET EOF-YES TO TRUE`; switches `88` names or adjusts indexes"),
                    ("`STRING`", "Concatenate", "`STRING A B DELIMITED BY SIZE INTO C END-STRING`"),
                    ("`UNSTRING`", "Split", "`UNSTRING S DELIMITED BY \"|\" INTO A B C END-UNSTRING`"),
                    ("`INSPECT`", "Count or replace characters", "`INSPECT S TALLYING N FOR ALL \"x\"`, `REPLACING`"),
                    ("`DISPLAY`", "Write to standard output", "`DISPLAY A B`; common for debug and batch logs"),
                    ("`ACCEPT`", "Read from standard input", "`ACCEPT WS-LINE`"),
                    ("`OPEN` / `CLOSE`", "Open and close files", "`OPEN INPUT F`, `OPEN OUTPUT F`, `CLOSE F`"),
                    ("`READ`", "Read one record", "`READ F AT END ... NOT AT END ... END-READ`"),
                    ("`WRITE` / `REWRITE`", "Write or update a record", "`WRITE REC`, `REWRITE REC` (requires a successful `READ` first)"),
                    ("`DELETE`", "Delete a record", "For indexed/relative files; sequential files do not support it"),
                    ("`START`", "Position at a key", "Used together with `READ NEXT`"),
                    ("`CALL` / `USING`", "Call a subprogram", "`CALL \"SUBPROG\" USING A B`; declare parameters in `LINKAGE SECTION`"),
                    ("`SORT`", "Sort a file or table", "May use `INPUT PROCEDURE` / `OUTPUT PROCEDURE`"),
                    ("`SEARCH` / `SEARCH ALL`", "Table lookup", "`SEARCH ALL` needs `ASCENDING/DESCENDING KEY` and does a binary search"),
                    ("`GO TO`", "Unconditional jump", "You will meet it in legacy code; prefer `PERFORM` in new code"),
                    ("`STOP RUN` / `GOBACK`", "End the program", "`STOP RUN` terminates; subprograms use `GOBACK` to return"),
                ],
            },
            {
                "id": "status",
                "title": "File status codes (`FILE STATUS`)",
                "kind": "table",
                "intro": "Declare `FILE STATUS IS WS-STATUS` in `FILE-CONTROL` and check it after every file operation. These values were measured here.",
                "head": ["Code", "Meaning"],
                "rows": [
                    ("`00`", "Operation succeeded"),
                    ("`10`", "End of file reached (`READ`'s `AT END`)"),
                    ("`22`", "Duplicate key (indexed files)"),
                    ("`23`", "Record not found (indexed files)"),
                    ("`35`", "File does not exist when opened (measured with a missing input file)"),
                    ("`37`", "Insufficient permission to open the file"),
                    ("`39`", "File attributes conflict with the program's declaration"),
                    ("`41`", "File is already open"),
                    ("`42`", "File is not open"),
                    ("`46`", "File is already at end, so it cannot be read further"),
                    ("`47`", "I/O attempted on a closed file (measured)"),
                    ("`9x`", "Runtime or system error; consult the GnuCOBOL documentation"),
                ],
                "after": [
                    "Values such as `35` and `47` were confirmed on this machine's GnuCOBOL 3.2. Implementations may define additional codes — check the official documentation for anything not listed.",
                ],
            },
            {
                "id": "compare",
                "title": "Conditions and comparisons",
                "kind": "table",
                "head": ["Form", "Meaning"],
                "rows": [
                    ("`=` / `EQUAL TO`", "Equal"),
                    ("`NOT =` / `NOT EQUAL TO`", "Not equal"),
                    ("`>` / `LESS THAN`", "Ordering comparison"),
                    ("`IS NUMERIC`", "Is numeric"),
                    ("`IS ALPHABETIC`", "Is alphabetic"),
                    ("`IS SPACES` / `IS ZERO`", "Is spaces / is zero"),
                    ("`AND` / `OR` / `NOT`", "Logical combination"),
                    ("`88` condition name", "`IF EOF-YES` tests whether the field equals its `VALUE`"),
                ],
                "after": [
                    "Numeric comparisons use numeric semantics and character comparisons use collating order. When mixing `COMP`, `COMP-3` and `DISPLAY` fields, make sure both sides are numeric items.",
                ],
            },
            {
                "id": "compiler",
                "title": "Common `cobc` commands",
                "kind": "table",
                "head": ["Command", "Purpose"],
                "rows": [
                    ("`cobc -fsyntax-only PROG.COB`", "Syntax check only; produces no output file"),
                    ("`cobc -x -o PROG PROG.COB`", "Compile and link an executable"),
                    ("`cobc -m -o MOD.so MOD.COB`", "Compile a module that `CALL` can load"),
                    ("`cobc -I copy ...`", "Add a copybook search directory"),
                    ("`cobc -free PROG.COB`", "Compile as free format"),
                    ("`cobc -fixed PROG.COB`", "Compile as fixed format"),
                    ("`cobc -Wall PROG.COB`", "Enable all warnings"),
                    ("`cobc -std=default`", "Use the default dialect (avoid casual `-std=cobol85`)"),
                ],
                "after": [
                    "The course's `make -C extensions/standalone-examples check` uses `-fsyntax-only`, and the plugin's `<leader>cl` takes the same path.",
                ],
            },
        ],
    },
    "ja": {
        "eyebrow": "REFERENCE",
        "title": "COBOL クイックリファレンス",
        "lead": "よく引く情報を 1 ページにまとめました。固定形式の桁、プログラムの骨組み、データ定義、PIC 記号、主要な文、ファイル状態コード。表中のバイト数と状態コードは GnuCOBOL 3.2 で実測した値です。",
        "note": "バイト数は Linux/x86-64 上の GnuCOBOL 3.2 で実測した確認用の値です。本番インターフェースの長さは対象コンパイラとプラットフォームの規則に従ってください。",
        "search_label": "このページを絞り込む",
        "search_placeholder": "キーワードを入力（例: PIC、OCCURS、PERFORM、35）",
        "no_match": "一致する項目がありません。",
        "sections": [
            {
                "id": "format",
                "title": "固定形式の桁",
                "kind": "table",
                "head": ["桁", "領域", "書く内容"],
                "rows": [
                    ("1–6", "連番領域", "伝統的にはカード番号。現代のソースでは通常空欄"),
                    ("7", "指示領域", "空白＝本文、`*`＝コメント、`/`＝改ページ、`-`＝継続行"),
                    ("8–11", "Area A", "`DIVISION`、`SECTION`、段落名、`01`/`77` レベル、`FD`/`SD`"),
                    ("12–72", "Area B", "文、句、`02`〜`49` レベルと `88` レベル"),
                    ("73–80", "識別領域", "コンパイラは無視します。72 桁を超えて本文を書かないこと"),
                ],
                "after": [
                    "`source_format = \"free\"` の場合はこれらの領域は適用されません。固定形式でないソースには GnuCOBOL が `free format detected` と表示します。",
                ],
            },
            {
                "id": "skeleton",
                "title": "プログラムの骨組み",
                "kind": "code",
                "code": """       IDENTIFICATION DIVISION.
       PROGRAM-ID. MYPROG.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO "in.txt"
               FILE STATUS IS WS-STATUS
               ORGANIZATION IS LINE SEQUENTIAL.
       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE.
       01  IN-REC              PIC X(80).
       WORKING-STORAGE SECTION.
       01  WS-STATUS           PIC XX.
       01  WS-EOF              PIC X VALUE "N".
           88  EOF-YES         VALUE "Y".
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INIT
           PERFORM 2000-PROCESS UNTIL EOF-YES
           PERFORM 9000-FINISH
           STOP RUN.
       1000-INIT.
           OPEN INPUT IN-FILE.
       2000-PROCESS.
           READ IN-FILE
               AT END SET EOF-YES TO TRUE
               NOT AT END DISPLAY IN-REC
           END-READ.
       9000-FINISH.
           CLOSE IN-FILE.""",
                "after": [
                    "4 つの DIVISION はこの順序で固定です。`PROCEDURE DIVISION` では `PERFORM` で処理を名前付き段落に分けるのが本コースの標準的な書き方です。",
                ],
            },
            {
                "id": "levels",
                "title": "データの階層と句",
                "kind": "table",
                "head": ["レベル", "意味"],
                "rows": [
                    ("`01`", "レコード（最上位のデータ項目）"),
                    ("`02`〜`49`", "集団項目または基本項目。数値が大きいほど下位"),
                    ("`66`", "`RENAMES`。既存項目に対する別のビュー"),
                    ("`77`", "下位項目を持てない独立項目"),
                    ("`88`", "条件名。上位項目の値を名付けるもので、記憶域を取りません"),
                ],
                "after": [
                    "よく使う句：`PIC`（形式）、`USAGE`（記憶方式）、`VALUE`（初期値）、`OCCURS`（繰り返し）、`REDEFINES`（重なりビュー）、`SIGN`（符号位置）、`BLANK WHEN ZERO`。",
                ],
                "table2_title": "定義の規則",
                "table2_head": ["規則", "内容"],
                "table2_rows": [
                    ("レベル番号", "`01` から始め、下位は上位より大きい番号にする。同じ階層では重複可"),
                    ("集団項目", "レベル番号と名前のみで `PIC` を持たない。長さは下位項目の合計"),
                    ("基本項目", "`PIC` を持ち、実際に記憶域を占める最小単位"),
                    ("`88` 条件名", "対象項目の直後に置く必要があり、記憶域を取りません"),
                    ("`VALUE`", "基本項目と `88` レベルでのみ意味を持ち、集団項目では無効"),
                    ("`FILLER`", "名前を省略できる詰め物項目。`OF` で参照できません"),
                ],
            },
            {
                "id": "pic",
                "title": "PIC 記号",
                "kind": "table",
                "intro": "`PIC` は項目の表示形式を記述します。よく使う記号を挙げます。",
                "head": ["記号", "意味"],
                "rows": [
                    ("`9`", "数字 1 桁"),
                    ("`X`", "任意の文字 1 文字"),
                    ("`A`", "英字または空白 1 文字"),
                    ("`V`", "想定小数点。記憶域を取りません"),
                    ("`S`", "符号（既定では末尾の数字と統合され、余分なバイトを取りません）"),
                    ("`P`", "想定スケーリング位置（例 `PIC 9(3)P(2)`）"),
                    ("`Z`", "先行ゼロを空白に（`PIC ZZZ9` の `42` は `  42`）"),
                    ("`*`", "先行ゼロをアスタリスクに（`PIC ***9` の `42` は `**42`）"),
                    ("`,`", "桁区切りのカンマを挿入"),
                    ("`.`", "小数点を挿入"),
                    ("`+` / `-`", "符号を挿入（`PIC +99999` の `42` は `+00042`）"),
                    ("`CR` / `DB`", "負値のときに末尾へ `CR` または `DB` を表示"),
                    ("`B`", "空白を 1 文字挿入（`PIC B99999B` は ` 00042 `）"),
                    ("`/`", "スラッシュを挿入（`PIC 999/99` は `000/42`）"),
                    ("`0`", "固定のゼロを挿入（`PIC 99900` は `04200`）"),
                    ("`$`", "浮動通貨記号（`PIC $$$,$$$,$$9.99` の `12500` は `    $12,500.00`）"),
                ],
                "after": [
                    "繰り返しは括弧で書きます。`PIC X(20)` は `PIC XXXXXXXXXXXXXXXXXXXX` と同じです。編集記号（`Z * , . + - CR DB B / 0 $`）は表示だけを変え、値自体は変えません。",
                ],
            },
            {
                "id": "usage",
                "title": "USAGE と実測バイト数",
                "kind": "table",
                "intro": "`USAGE` は記憶方式を決めます。下記のバイト数は GnuCOBOL 3.2 で `FUNCTION LENGTH` により実測した値です。",
                "head": ["宣言", "記憶方式", "実測バイト"],
                "rows": [
                    ("`PIC 9(1)`〜`9(2)` `COMP`", "バイナリ", "1"),
                    ("`PIC 9(3)`〜`9(4)` `COMP`", "バイナリ", "2"),
                    ("`PIC 9(5)`〜`9(9)` `COMP`", "バイナリ", "4"),
                    ("`PIC 9(10)`〜`9(18)` `COMP`", "バイナリ", "8"),
                    ("`PIC S9(7) COMP-3`", "パック十進", "4"),
                    ("`PIC S9(7)V99 COMP-3`", "パック十進", "5"),
                    ("`PIC X(20)`", "`DISPLAY`", "20"),
                    ("`PIC 9(5)V99`", "`DISPLAY`", "7"),
                    ("`PIC S9(5)`", "`DISPLAY`（符号は末尾の数字に統合）", "5"),
                    ("`PIC S9(5) SIGN IS LEADING SEPARATE`", "`DISPLAY`（符号専用バイト）", "6"),
                ],
                "after": [
                    "**`COMP-3` の見積り**：`ceil((桁数 + 1) / 2)`。`S9(7)V99 COMP-3` は 9 桁に符号ニブルを加えて 10 ニブル、つまり 5 バイトです。",
                    "**`COMP` の境界**：1〜2 桁→1 バイト、3〜4 桁→2、5〜9 桁→4、10〜18 桁→8。これは GnuCOBOL の方式で、他のコンパイラでは異なる場合があります。",
                ],
            },
            {
                "id": "statements",
                "title": "主要な文",
                "kind": "table",
                "head": ["文", "用途", "書き方の要点"],
                "rows": [
                    ("`MOVE`", "値の代入", "`MOVE A TO B`。数値は受け側の形式に合わせて切捨てまたは桁合わせ"),
                    ("`ADD` / `SUBTRACT`", "加算・減算", "`ADD 1 TO N`。`GIVING` と `ON SIZE ERROR` が使えます"),
                    ("`MULTIPLY` / `DIVIDE`", "乗算・除算", "`DIVIDE A BY B GIVING C`。ゼロ除算は `ON SIZE ERROR` で捕捉"),
                    ("`COMPUTE`", "式の計算", "`COMPUTE X = A + B * 2`。端数処理は受け側の小数桁で決まります"),
                    ("`IF` / `ELSE` / `END-IF`", "条件分岐", "ブロックは `END-IF` で閉じます。ピリオドだけに頼らないこと"),
                    ("`EVALUATE`", "多分岐", "`EVALUATE TRUE` または `EVALUATE 変数`。分岐は `WHEN`、最後は `END-EVALUATE`"),
                    ("`PERFORM`", "段落の実行とループ", "`PERFORM 段落`。ループは `PERFORM UNTIL` や `PERFORM n TIMES`"),
                    ("`PERFORM VARYING`", "回数ループ", "`PERFORM VARYING I FROM 1 BY 1 UNTIL I > 10`"),
                    ("`INITIALIZE`", "項目の初期化", "型ごとの既定値に戻します。`REPLACING` で一部のみ初期化も可"),
                    ("`SET`", "条件名・索引の設定", "`SET EOF-YES TO TRUE`。`88` 条件名の切替や索引の調整"),
                    ("`STRING`", "文字列の連結", "`STRING A B DELIMITED BY SIZE INTO C END-STRING`"),
                    ("`UNSTRING`", "文字列の分割", "`UNSTRING S DELIMITED BY \"|\" INTO A B C END-UNSTRING`"),
                    ("`INSPECT`", "文字の計数・置換", "`INSPECT S TALLYING N FOR ALL \"x\"`、`REPLACING`"),
                    ("`DISPLAY`", "標準出力への出力", "`DISPLAY A B`。デバッグやバッチのログで多用"),
                    ("`ACCEPT`", "標準入力からの入力", "`ACCEPT WS-LINE`"),
                    ("`OPEN` / `CLOSE`", "ファイルの開閉", "`OPEN INPUT F`、`OPEN OUTPUT F`、`CLOSE F`"),
                    ("`READ`", "1 レコードの読み込み", "`READ F AT END ... NOT AT END ... END-READ`"),
                    ("`WRITE` / `REWRITE`", "レコードの書出し・更新", "`WRITE REC`、`REWRITE REC`（先に `READ` 成功が必要）"),
                    ("`DELETE`", "レコードの削除", "索引／相対ファイル用。順編成ファイルでは使えません"),
                    ("`START`", "指定キーへの位置付け", "`READ NEXT` と組み合わせて使います"),
                    ("`CALL` / `USING`", "副プログラムの呼出し", "`CALL \"SUBPROG\" USING A B`。引数は `LINKAGE SECTION` で宣言"),
                    ("`SORT`", "ファイル・表の整列", "`INPUT PROCEDURE` / `OUTPUT PROCEDURE` が使えます"),
                    ("`SEARCH` / `SEARCH ALL`", "表の探索", "`SEARCH ALL` は `ASCENDING/DESCENDING KEY` が必要で二分探索になります"),
                    ("`GO TO`", "無条件ジャンプ", "保守で遭遇します。新規コードでは `PERFORM` を優先"),
                    ("`STOP RUN` / `GOBACK`", "プログラムの終了", "`STOP RUN` は実行を終了。副プログラムは `GOBACK` で戻ります"),
                ],
            },
            {
                "id": "status",
                "title": "ファイル状態コード（`FILE STATUS`）",
                "kind": "table",
                "intro": "`FILE-CONTROL` で `FILE STATUS IS WS-STATUS` を宣言し、ファイル操作ごとに確認します。下記は実測した主な値です。",
                "head": ["コード", "意味"],
                "rows": [
                    ("`00`", "操作成功"),
                    ("`10`", "ファイル終端に到達（`READ` の `AT END`）"),
                    ("`22`", "キーの重複（索引ファイル）"),
                    ("`23`", "レコードが見つからない（索引ファイル）"),
                    ("`35`", "オープン時にファイルが存在しない（入力ファイル欠如で実測）"),
                    ("`37`", "オープン時の権限不足"),
                    ("`39`", "ファイル属性がプログラムの宣言と矛盾"),
                    ("`41`", "ファイルは既に開かれている"),
                    ("`42`", "ファイルが開かれていない"),
                    ("`46`", "既に終端に達しており、これ以上読めない"),
                    ("`47`", "閉じたファイルに対する入出力（実測）"),
                    ("`9x`", "実行時またはシステムレベルのエラー。GnuCOBOL の資料を確認"),
                ],
                "after": [
                    "`35` や `47` は本機の GnuCOBOL 3.2 で確認した値です。実装によって追加のコードがあり得るため、記載のない値は公式ドキュメントを参照してください。",
                ],
            },
            {
                "id": "compare",
                "title": "条件と比較",
                "kind": "table",
                "head": ["書き方", "意味"],
                "rows": [
                    ("`=` / `EQUAL TO`", "等しい"),
                    ("`NOT =` / `NOT EQUAL TO`", "等しくない"),
                    ("`>` / `LESS THAN`", "大小比較"),
                    ("`IS NUMERIC`", "数値かどうか"),
                    ("`IS ALPHABETIC`", "英字かどうか"),
                    ("`IS SPACES` / `IS ZERO`", "空白か／ゼロか"),
                    ("`AND` / `OR` / `NOT`", "論理結合"),
                    ("`88` 条件名", "`IF EOF-YES` で項目が `VALUE` と等しいかを判定"),
                ],
                "after": [
                    "数値比較は数値の意味で、文字比較は照合順序で行われます。`COMP`、`COMP-3`、`DISPLAY` を混在させる場合は、両辺が数値項目であることを確認してください。",
                ],
            },
            {
                "id": "compiler",
                "title": "よく使う `cobc` コマンド",
                "kind": "table",
                "head": ["コマンド", "用途"],
                "rows": [
                    ("`cobc -fsyntax-only PROG.COB`", "構文検査のみ。出力ファイルを作りません"),
                    ("`cobc -x -o PROG PROG.COB`", "コンパイルして実行ファイルをリンク"),
                    ("`cobc -m -o MOD.so MOD.COB`", "`CALL` で読み込むモジュールとしてコンパイル"),
                    ("`cobc -I copy ...`", "Copybook の検索ディレクトリを追加"),
                    ("`cobc -free PROG.COB`", "自由形式としてコンパイル"),
                    ("`cobc -fixed PROG.COB`", "固定形式としてコンパイル"),
                    ("`cobc -Wall PROG.COB`", "すべての警告を有効化"),
                    ("`cobc -std=default`", "既定の方言を使用（安易な `-std=cobol85` は避ける）"),
                ],
                "after": [
                    "本コースの `make -C extensions/standalone-examples check` は `-fsyntax-only` を使い、プラグインの `<leader>cl` も同じ経路を通ります。",
                ],
            },
        ],
    },
}
