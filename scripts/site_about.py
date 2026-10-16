"""Content for the "What is COBOL" page and the reference / cheat-sheet page.

Both pages are static and trilingual. Keeping the copy here keeps build_site.py
focused on rendering and lets the two pages be reviewed like documentation.

Historical facts on the ABOUT page follow the COBOL article's history sections
on Wikipedia and the published ISO standard names; nothing here is invented.
"""

# ---------------------------------------------------------------------------
# ABOUT — what COBOL is, where it came from, who still runs it.
# ---------------------------------------------------------------------------

ABOUT = {
    "zh-cn": {
        "eyebrow": "BACKGROUND",
        "title": "COBOL 是什么",
        "lead": "COBOL 是面向商业数据处理的编程语言：它用接近英语的语句描述记录、文件和批处理流程。1959 年由美国国防部推动、多家厂商与政府机构共同设计，如今仍是银行、保险、政务等系统里大量核心账务与批处理程序的实现语言。",
        "source_note": "本页史实依据 COBOL 的公开历史资料与 ISO 标准编号整理；标准编号与年份以已发布版本为准。",
        "sections": [
            {
                "id": "what",
                "title": "它是什么",
                "kind": "prose",
                "body": [
                    "COBOL 是 Common Business-Oriented Language 的缩写，定位是**商业数据处理**，而不是科学计算或系统编程。它的设计目标直接决定了它的样子：读起来像英语、数据描述与执行指令分离、强调定长记录与文件处理、便于跨机器移植。",
                    "对今天的读者，最实际的三点认识是：",
                ],
                "bullets": [
                    "**它面向文件与记录**：定长记录、顺序文件、排序与对账是它的主场，这门课的全部示例都建立在这套模型上。",
                    "**它强调可读性而非简洁**：语句很长、保留字很多，这是刻意的取舍——程序要能被业务人员读懂、被下一代人维护。",
                    "**它是编译型语言**：源码经 `cobc` 编译为原生可执行程序，不是脚本。",
                ],
                "after": [
                    "一句话：COBOL 把「业务规则」写成接近英语的固定格式文本，交给编译器变成能在大型机或 Linux 上长期运行的批处理程序。",
                ],
            },
            {
                "id": "origin",
                "title": "它从何而来",
                "kind": "timeline",
                "intro": "COBOL 不是某个人一夜之间发明的，而是由一次跨厂商协作推动出来的标准语言。",
                "items": [
                    ("1959-04-08", "会议发起", "Burroughs 的计算机科学家 Mary K. Hawes 在宾夕法尼亚大学召集学界、用户与厂商代表，商议是否需要一个通用的商业语言。与会者包括 Grace Hopper、Jean Sammet 与 Saul Gorn。"),
                    ("1959-05-28", "五角大楼会议", "美国国防部出资在五角大楼召开会议，41 人参加，由 Charles A. Phillips 主持。背景很现实：国防部当时有 225 台计算机、另有 175 台在订购中，程序移植成本极高。"),
                    ("1959-06-04", "CODASYL 成立", "指导委员会把这项活动命名为 CODASYL（Committee on Data Systems Languages），并成立执行委员会；短期委员会被要求三个月内给出临时语言规范。"),
                    ("1960-04", "COBOL 60", "第一版规范提交给 CODASYL。它主要吸收了三门语言的经验：Grace Hopper 的 FLOW-MATIC（长变量名、英语命令、数据与指令分离）、IBM 的 COMTRAN，以及 AIMACO。"),
                    ("1963", "语法澄清", "COBOL 60 被发现存在歧义，委员会做了系统性清理；到 1963 年，其语法的可定义程度已与 ALGOL 相当。早期编译器很慢：1962 年一次美国海军评测记录的速度是每分钟 3–11 条语句。"),
                    ("1968-08", "首个国家标准", "ANSI 发布 USA Standard COBOL X3.23（即 ANS COBOL），成为后续各版的基石；ISO 于 1972 年采纳。"),
                    ("1974", "COBOL-74", "ANSI 发布修订版。此前 CODASYL 委员会在 1968–1973 年间持续改进语言，加入程序间通信、调试、文件合并、字符串处理与库引入等能力。"),
                    ("1985", "COBOL-85", "又一次大修。修订过程争议很大：草案与 COBOL-74 不向上兼容，保险公司的 4000 万行代码库迁移被形容为「非生产性」；第一轮公开评审收到 2200 份意见，其中 1700 份是反对。"),
                    ("2002", "面向对象", "ISO 发布 COBOL 2002，加入面向对象、自由格式源码、用户自定义函数、递归、区域设置与扩展字符集等。这些特性多数在 CODASYL 1978 年的开发期刊里就已出现，只是错过了 COBOL-85。"),
                    ("2014", "COBOL 2014", "把部分设施改为可选（如 VALIDATE、报表写出器、屏幕处理），引入 IEEE 754 数据类型与方法重载。"),
                    ("2023", "COBOL 2023", "最新标准：异步消息（`SEND`/`RECEIVE`）、事务处理（`COMMIT`/`ROLLBACK`）、`XOR`、`PERFORM UNTIL EXIT`、`SUBSTITUTE`、`CONVERT` 等。GCC 15.1 起的 `gcobol` 即基于此标准。"),
                ],
                "after": [
                    "当前标准编号是 **ISO/IEC 1989:2023**。标准演进的一条主线始终是：在不破坏既有代码的前提下增加能力——这也是 COBOL 程序寿命动辄数十年的原因之一。",
                ],
            },
            {
                "id": "industries",
                "title": "它用在哪里",
                "kind": "table",
                "intro": "COBOL 的存量集中在「交易量大、规则稳定、不能出错」的场景。",
                "head": ["行业", "典型用途"],
                "rows": [
                    ("银行与金融", "账户与账务、日终批处理、对账、清算、利息与费用计算"),
                    ("保险", "保单、理赔、保费计算与批量结算"),
                    ("零售与流通", "库存、结算、供应链批处理"),
                    ("航空与旅行", "订座与运价等长期运行的交易系统"),
                    ("医疗与公共事业", "理赔与缴费等批量处理"),
                    ("政府机构", "税务、福利、社保等大型事务处理系统"),
                ],
                "after": [
                    "运行平台同样很广：z/OS、z/VSE、VME、Unix、NonStop OS、OpenVMS、Windows 等。",
                ],
            },
            {
                "id": "legacy",
                "title": "为什么今天还要学它",
                "kind": "prose",
                "body": [
                    "这组数字能说明存量规模：",
                ],
                "bullets": [
                    "1997 年 Gartner Group 的估算：全世界约有 **2000 亿行** COBOL 代码，承载 **80%** 的商业程序。",
                    "2020 年前后：**95%** 的信用卡/借记卡刷卡交易，其后台处理经过 COBOL 程序。",
                    "2006 与 2012 年 Computerworld 的调查：超过 **60%** 的组织仍在使用 COBOL，其中约一半把它用于大部分内部软件。",
                    "2016 年美国众议院监督与政府改革委员会听证会记录：美国农业部、国土安全部、卫生与公众服务部、司法部、财政部、退伍军人事务部、国税局等机构仍在使用 COBOL。",
                ],
                "after": [
                    "**千年虫（Y2K）**是 COBOL 最近一次被大众关注：因为商业系统大量使用日期、且数据是定长字段，修复工作量集中落在 COBOL 上，有研究把高达 **24%** 的 Y2K 修复成本归因于 COBOL。清理之后，2003 年的一次调查发现这些程序大多仍在服役。",
                    "**人才缺口**是当下更实际的问题：到 2019 年，COBOL 程序员因退休而快速减少，而重写既有系统的成本高、风险大——一些银行的多年度迁移项目曾造成服务中断并招致罚款。COVID-19 期间，美国多个州的失业救济系统出现 COBOL 程序员短缺，成为公开报道的事件。",
                    "所以这门课的价值不在「追新」，而在于：**能读懂并安全修改已经在生产环境里运行了几十年的批处理程序**，同时用现代工具（编译器诊断、结构导航、测试）把它维护好。",
                ],
            },
            {
                "id": "shape",
                "title": "它长什么样",
                "kind": "code",
                "intro": "一个最小可运行的固定格式程序。前七列留空，第 8 列起写程序正文：",
                "code": """       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLO.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-NAME PIC X(10) VALUE "COBOL".
       PROCEDURE DIVISION.
           DISPLAY "HELLO, " WS-NAME.
           STOP RUN.""",
                "after": [
                    "四个 Division 各司其职：`IDENTIFICATION` 说明程序身份，`DATA` 描述数据，`PROCEDURE` 写执行步骤。`01` 定义记录或字段，`PIC X(10)` 表示 10 个字符位置。",
                    "想动手跑起来，从[第 01 课](lessons/01_hello-cobol/README.html)开始；想查语句与字段定义规则，用[速查手册](reference.html)。",
                ],
            },
        ],
    },
    "en": {
        "eyebrow": "BACKGROUND",
        "title": "What is COBOL",
        "lead": "COBOL is a programming language for business data processing: it describes records, files and batch flows in statements that read like English. Sponsored by the US Department of Defense and designed with manufacturers and government agencies from 1959, it still implements a large share of the core accounting and batch programs in banking, insurance and government.",
        "source_note": "The history on this page follows COBOL's public historical record and the published ISO standard numbers.",
        "sections": [
            {
                "id": "what",
                "title": "What it is",
                "kind": "prose",
                "body": [
                    "COBOL stands for Common Business-Oriented Language. Its target was **business data processing**, not scientific computing or systems programming, and that choice explains its shape: English-like statements, data descriptions kept separate from executable statements, a strong emphasis on fixed-length records and file handling, and portability across machines.",
                    "Three things matter most for a reader today:",
                ],
                "bullets": [
                    "**It is built around files and records**: fixed-length records, sequential files, sorting and reconciliation are its home ground, and every example in this course uses that model.",
                    "**It favours readability over brevity**: long statements and many reserved words are a deliberate trade-off, so business staff can read a program and the next generation can maintain it.",
                    "**It is a compiled language**: source is compiled by `cobc` into a native executable, not interpreted.",
                ],
                "after": [
                    "In one sentence: COBOL writes business rules as English-like fixed-format text and hands them to a compiler that produces batch programs able to run for decades on a mainframe or on Linux.",
                ],
            },
            {
                "id": "origin",
                "title": "Where it came from",
                "kind": "timeline",
                "intro": "COBOL was not invented overnight by one person; it came out of a cross-vendor standardisation effort.",
                "items": [
                    ("1959-04-08", "The first meeting", "Mary K. Hawes, a computer scientist at Burroughs, convened representatives from academia, users and manufacturers at the University of Pennsylvania to discuss a common business language. Attendees included Grace Hopper, Jean Sammet and Saul Gorn."),
                    ("1959-05-28", "The Pentagon meeting", "The US Department of Defense sponsored a meeting at the Pentagon: 41 people, chaired by Charles A. Phillips. The motivation was concrete — the DoD operated 225 computers with 175 more on order, and porting programs was expensive."),
                    ("1959-06-04", "CODASYL is formed", "The steering committee named the activity CODASYL (Committee on Data Systems Languages) and formed an executive committee; the short-range committee had three months to produce an interim language specification."),
                    ("1960-04", "COBOL 60", "The first specification was delivered to CODASYL. It drew mainly on three languages: Grace Hopper's FLOW-MATIC (long variable names, English command words, data descriptions separated from instructions), IBM's COMTRAN, and AIMACO."),
                    ("1963", "Syntax cleaned up", "COBOL 60 was found to contain ambiguities, and the committee performed a systematic cleanup; by 1963 its syntax was as definable as ALGOL's. Early compilers were slow: a 1962 US Navy evaluation measured 3-11 statements per minute."),
                    ("1968-08", "First national standard", "ANSI published USA Standard COBOL X3.23 (ANS COBOL), the cornerstone for later versions; ISO adopted it in 1972."),
                    ("1974", "COBOL-74", "ANSI published a revision. CODASYL had been improving the language through 1968-1973, adding inter-program communication, debugging, file merging, better string handling and library inclusion."),
                    ("1985", "COBOL-85", "Another major revision, and a contentious one: the draft was not upward compatible with COBOL-74, one insurer called migrating its 40-million-line code base 'non-productive', and the first public review drew 2200 responses of which 1700 were negative."),
                    ("2002", "Object orientation", "ISO published COBOL 2002 with object-oriented features, free-form source, user-defined functions, recursion, locale-based processing and extended character sets. Most had appeared in CODASYL's 1978 Journal of Development but missed COBOL-85."),
                    ("2014", "COBOL 2014", "Made several facilities optional (VALIDATE, the report writer, screen handling) and added IEEE 754 data types and method overloading."),
                    ("2023", "COBOL 2023", "The current standard: asynchronous messaging (`SEND`/`RECEIVE`), transaction processing (`COMMIT`/`ROLLBACK`), `XOR`, `PERFORM UNTIL EXIT`, `SUBSTITUTE`, `CONVERT` and more. `gcobol`, from GCC 15.1, is based on it."),
                ],
                "after": [
                    "The current standard is **ISO/IEC 1989:2023**. One theme runs through every revision: add capability without breaking existing code — part of why COBOL programs live for decades.",
                ],
            },
            {
                "id": "industries",
                "title": "Where it is used",
                "kind": "table",
                "intro": "COBOL's installed base sits where volume is high, rules are stable and failure is expensive.",
                "head": ["Industry", "Typical use"],
                "rows": [
                    ("Banking and finance", "Accounts and ledgers, end-of-day batch, reconciliation, clearing, interest and fee calculation"),
                    ("Insurance", "Policies, claims, premium calculation and batch settlement"),
                    ("Retail and distribution", "Inventory, settlement and supply-chain batch jobs"),
                    ("Airlines and travel", "Long-lived reservation and fare systems"),
                    ("Healthcare and utilities", "Claims and billing batch processing"),
                    ("Government", "Tax, benefits and social-security transaction systems"),
                ],
                "after": [
                    "It also runs on a wide range of platforms: z/OS, z/VSE, VME, Unix, NonStop OS, OpenVMS and Windows, among others.",
                ],
            },
            {
                "id": "legacy",
                "title": "Why it is still worth learning",
                "kind": "prose",
                "body": [
                    "A few numbers convey the scale of the installed base:",
                ],
                "bullets": [
                    "A 1997 Gartner Group estimate: roughly **200 billion lines** of COBOL in existence, running **80%** of the world's business programs.",
                    "Around 2020: **95%** of the time a credit or debit card was swiped, COBOL ran the background processing.",
                    "Computerworld surveys in 2006 and 2012: over **60%** of organisations still used COBOL, and for about half of them it covered most of their internal software.",
                    "Testimony before the US House Committee on Oversight and Government Reform in 2016: COBOL remained in use at the USDA, DHS, HHS, Department of Justice, Treasury, Veterans Affairs and the IRS, among others.",
                ],
                "after": [
                    "**Y2K** was the last time the public noticed COBOL. Because business systems lean on dates and use fixed-length fields, the repair effort concentrated there; some studies attribute as much as **24%** of Y2K software repair costs to COBOL. After the cleanup, a 2003 survey found most of those programs still in service.",
                    "**The skills gap** is the practical issue now: by 2019 the number of COBOL programmers was shrinking fast through retirement, while rewriting legacy systems has proved expensive and risky — some banks' multi-year migrations caused service disruptions and fines. During COVID-19, several US states publicly reported a shortage of COBOL programmers for unemployment systems.",
                    "So the value of this course is not novelty: it is being able to **read and safely change batch programs that have run in production for decades**, while maintaining them with modern tools such as compiler diagnostics, structure navigation and tests.",
                ],
            },
            {
                "id": "shape",
                "title": "What it looks like",
                "kind": "code",
                "intro": "A minimal runnable fixed-format program. The first seven columns are blank and the program text starts in column 8:",
                "code": """       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLO.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-NAME PIC X(10) VALUE "COBOL".
       PROCEDURE DIVISION.
           DISPLAY "HELLO, " WS-NAME.
           STOP RUN.""",
                "after": [
                    "Each division has a job: `IDENTIFICATION` states the program's identity, `DATA` describes the data, and `PROCEDURE` holds the executable steps. `01` defines a record or field, and `PIC X(10)` means ten character positions.",
                    "To run something, start with [lesson 01](lessons/01_hello-cobol/README.html); to look up statements and data-definition rules, use the [reference sheet](reference.html).",
                ],
            },
        ],
    },
    "ja": {
        "eyebrow": "BACKGROUND",
        "title": "COBOL とは",
        "lead": "COBOL は業務データ処理のためのプログラミング言語です。英語に近い文でレコード・ファイル・バッチ処理を記述します。1959 年に米国防総省の後押しで複数のメーカーと政府機関が共同設計し、現在も銀行・保険・行政などの基幹帳票処理やバッチ処理の多くを担っています。",
        "source_note": "本ページの史実は COBOL の公開された歴史資料と ISO 標準番号に基づいています。",
        "sections": [
            {
                "id": "what",
                "title": "どんな言語か",
                "kind": "prose",
                "body": [
                    "COBOL は Common Business-Oriented Language の略で、対象は**業務データ処理**です。科学技術計算でもシステムプログラミングでもありません。この目的が言語の形を決めました。英語に近い文、データ記述と実行命令の分離、固定長レコードとファイル処理の重視、そしてマシン間の移植性です。",
                    "現在の読者にとって重要な点は三つです。",
                ],
                "bullets": [
                    "**ファイルとレコードが中心**：固定長レコード、順編成ファイル、ソートと突合が主戦場で、本コースの全サンプルもこのモデルに乗っています。",
                    "**簡潔さより可読性**：文が長く予約語が多いのは意図的な選択で、業務担当者が読め、次世代が保守できることを狙っています。",
                    "**コンパイル言語**：ソースは `cobc` でネイティブ実行ファイルに変換されます。スクリプトではありません。",
                ],
                "after": [
                    "一言でいえば、業務ルールを英語に近い固定形式のテキストで書き、コンパイラがそれをメインフレームや Linux で長期運用できるバッチ処理プログラムに変換する言語です。",
                ],
            },
            {
                "id": "origin",
                "title": "成り立ち",
                "kind": "timeline",
                "intro": "COBOL は一人が一夜で作ったものではなく、ベンダー横断の標準化の取り組みから生まれました。",
                "items": [
                    ("1959-04-08", "最初の会合", "Burroughs の計算機科学者 Mary K. Hawes がペンシルバニア大学で学界・利用者・メーカーの代表を招集し、共通の業務用言語を検討しました。参加者には Grace Hopper、Jean Sammet、Saul Gorn が含まれます。"),
                    ("1959-05-28", "ペンタゴン会議", "米国防総省の後援でペンタゴンに 41 名が集まり、Charles A. Phillips が議長を務めました。背景は現実的で、当時 225 台の計算機を運用し 175 台を追加発注、プログラムの移植費用が大きな負担でした。"),
                    ("1959-06-04", "CODASYL 発足", "指導委員会はこの活動を CODASYL（Committee on Data Systems Languages）と命名し執行委員会を設置。短期委員会は 3 か月で暫定言語仕様を出すよう求められました。"),
                    ("1960-04", "COBOL 60", "最初の仕様が CODASYL に提出されました。主に三つの言語を取り込んでいます。Grace Hopper の FLOW-MATIC（長い変数名、英語の命令語、データ記述と命令の分離）、IBM の COMTRAN、そして AIMACO です。"),
                    ("1963", "文法の整理", "COBOL 60 には曖昧さが見つかり、委員会が体系的に整理しました。1963 年にはその文法は ALGOL と同程度に定義可能とされました。初期のコンパイラは低速で、1962 年の米海軍の評価では毎分 3〜11 文でした。"),
                    ("1968-08", "最初の国家規格", "ANSI が USA Standard COBOL X3.23（ANS COBOL）を発行。後の各版の基盤となり、1972 年に ISO が採用しました。"),
                    ("1974", "COBOL-74", "ANSI が改訂版を発行。CODASYL は 1968〜1973 年にプログラム間通信、デバッグ、ファイル併合、文字列処理、ライブラリ導入などを追加していました。"),
                    ("1985", "COBOL-85", "もう一つの大改訂。草案が COBOL-74 と上位互換でなく、保険会社の 4000 万行の移行が「非生産的」と評され、最初の公開審査では 2200 件の意見のうち 1700 件が反対でした。"),
                    ("2002", "オブジェクト指向", "ISO が COBOL 2002 を発行。オブジェクト指向、自由形式ソース、ユーザー定義関数、再帰、ロケール処理、拡張文字集合などを追加。多くは CODASYL の 1978 年開発誌に既出で、COBOL-85 に間に合わなかったものです。"),
                    ("2014", "COBOL 2014", "VALIDATE、帳票作成機能、画面処理などを任意機能とし、IEEE 754 データ型とメソッド多重定義を追加しました。"),
                    ("2023", "COBOL 2023", "最新規格。非同期メッセージ（`SEND`/`RECEIVE`）、トランザクション処理（`COMMIT`/`ROLLBACK`）、`XOR`、`PERFORM UNTIL EXIT`、`SUBSTITUTE`、`CONVERT` など。GCC 15.1 以降の `gcobol` はこの規格に基づきます。"),
                ],
                "after": [
                    "現在の規格番号は **ISO/IEC 1989:2023** です。改訂を貫くテーマは「既存コードを壊さずに能力を足す」こと。これが COBOL プログラムが数十年動き続ける理由の一つです。",
                ],
            },
            {
                "id": "industries",
                "title": "どこで使われているか",
                "kind": "table",
                "intro": "COBOL の既存資産は、取引量が多く、規則が安定し、失敗が高くつく領域に集中しています。",
                "head": ["業界", "代表的な用途"],
                "rows": [
                    ("銀行・金融", "口座と帳簿、日次バッチ、突合、決済、利息と手数料の計算"),
                    ("保険", "契約、請求、保険料計算、バッチ精算"),
                    ("小売・流通", "在庫、決済、サプライチェーンのバッチ処理"),
                    ("航空・旅行", "長期間運用される予約・運賃システム"),
                    ("医療・公益", "請求や料金のバッチ処理"),
                    ("政府機関", "税務、給付、社会保障などの基幹処理"),
                ],
                "after": [
                    "動作する環境も幅広く、z/OS、z/VSE、VME、Unix、NonStop OS、OpenVMS、Windows などがあります。",
                ],
            },
            {
                "id": "legacy",
                "title": "いま学ぶ意味",
                "kind": "prose",
                "body": [
                    "資産規模は次の数字がよく表しています。",
                ],
                "bullets": [
                    "1997 年の Gartner Group の推計：世界に約 **2000 億行**の COBOL コードがあり、業務プログラムの **80%** を動かしていました。",
                    "2020 年前後：クレジット／デビットカードの読み取り時、**95%** のケースで COBOL がバックグラウンド処理を担っていました。",
                    "2006 年と 2012 年の Computerworld 調査：**60%** を超える組織が COBOL を使い続け、その約半数では社内ソフトの大半を占めていました。",
                    "2016 年の米下院監督・政府改革委員会の証言：米農務省、国土安全保障省、保健福祉省、司法省、財務省、退役軍人省、国税庁などが COBOL を使用していました。",
                ],
                "after": [
                    "**Y2K（2000 年問題）**は COBOL が最後に一般の注目を集めた出来事です。業務システムは日付を多用し固定長項目を使うため修正作業が集中し、Y2K 修正費用の最大 **24%** を COBOL に帰する研究もあります。対応後、2003 年の調査でも多くのプログラムが現役でした。",
                    "**人材不足**が現在の実際的な課題です。2019 年までに COBOL プログラマーは退職により急速に減少し、一方で既存システムの書き換えは高コストでリスクも大きく、一部の銀行の複数年にわたる移行はサービス障害と制裁金を招きました。COVID-19 期には、米国の複数州が失業給付システムで COBOL プログラマー不足を公表しています。",
                    "したがって本コースの価値は「新しさ」ではなく、**数十年本番稼働してきたバッチ処理プログラムを読み、安全に変更できるようになること**にあります。コンパイラ診断、構造ナビゲーション、テストといった現代の道具で保守できる状態を目指します。",
                ],
            },
            {
                "id": "shape",
                "title": "実際のコード",
                "kind": "code",
                "intro": "最小の実行可能な固定形式プログラムです。先頭 7 列は空け、8 列目から本文を書きます。",
                "code": """       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLO.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-NAME PIC X(10) VALUE "COBOL".
       PROCEDURE DIVISION.
           DISPLAY "HELLO, " WS-NAME.
           STOP RUN.""",
                "after": [
                    "4 つの DIVISION が役割を分担します。`IDENTIFICATION` はプログラムの身元、`DATA` はデータ、`PROCEDURE` は実行手順です。`01` はレコードや項目の定義、`PIC X(10)` は 10 文字分を意味します。",
                    "実際に動かすには[第 01 課](lessons/01_hello-cobol/README.html)から始め、文やデータ定義の規則を調べるには[クイックリファレンス](reference.html)を使ってください。",
                ],
            },
        ],
    },
}
