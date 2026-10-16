"""Content for the knowledge pages: COBOL history and a terminology glossary.

Facts on the history page follow COBOL's published historical record (the
Wikipedia "COBOL" article's history, reception and influence sections, which
cite the original sources). Glossary entries were checked against the GnuCOBOL
3.2 compiler in this repository where behaviour could be observed, and against
the official GnuCOBOL Quick Reference for syntax. Nothing here is invented.
"""

HISTORY = {
    "zh-cn": {
        "eyebrow": "HISTORY",
        "title": "COBOL 史话",
        "lead": "标准不是凭空写出来的。它由一群具体的人，在一场关于「谁的语言该胜出」的争执里，用三个月赶出第一版草稿——中间还有人给项目负责人寄了一块刻着 COBOL 的墓碑。",
        "note": "本页史实依据 COBOL 的公开历史资料整理，含具体人物、数字与争议记录。",
        "sections": [
            {
                "id": "people",
                "title": "推动它的人",
                "kind": "table",
                "intro": "COBOL 常被归功于某一个人，但档案显示它是一次集体协作的结果。",
                "head": ["人物", "角色与贡献"],
                "rows": [
                    ("Mary K. Hawes", "Burroughs 的计算机科学家。1959 年 4 月 8 日在宾夕法尼亚大学召集学界、用户与厂商代表，是整件事的发起人。"),
                    ("Grace Hopper", "FLOW-MATIC 的发明者，委员会技术顾问。FLOW-MATIC 给 COBOL 带来长变量名、英语命令词、数据描述与指令分离。她常被称为「COBOL 之母」，但这一说法有争议。"),
                    ("Jean E. Sammet", "COBOL 的主要设计者之一，六人起草小组的成员。她指出 Hopper「不是 COBOL 的母亲、创造者或开发者」；她后来称「没有参数传递」是委员会最大的失误。"),
                    ("Bob Bemer", "IBM COMTRAN 的发明者。他后来声称 COBOL 这个名字是他提议的，但已无法确证。"),
                    ("Howard Bromberg", "RCA 代表。为抗议进度受阻，他买了一块刻着「COBOL」的墓碑寄给国防部的 Charles Phillips（1959 年花 15 美元，约合 2025 年的 170 美元）。"),
                    ("Betty Holberton", "短期委员会成员。她把「三个月交出规范」这个期限形容为「极度乐观」，并怀疑它真能只是一个过渡方案。"),
                    ("Joseph Wegstein", "美国国家标准局（今 NIST）人员，任委员会主席。评审第一版草稿时评价它「仍有粗糙之处，需要补充」。"),
                    ("Charles A. Phillips", "美国国防部数据系统研究部门负责人。他同意资助这项计划，并让代表团起草议程。"),
                    ("Roy Nutt", "FACT 语言的作者。FACT 一度让委员会决议改用它做基础。"),
                ],
                "after": [
                    "实际起草规范的是六人小组：IBM 的 William Selden 与 Gertrude Tierney，RCA 的 Howard Bromberg 与 Howard Discount，Sylvania 的 Vernon Reeves 与 Jean E. Sammet。他们完成初稿后，才交回短期委员会评审修改。",
                ],
            },
            {
                "id": "why",
                "title": "为什么当时非做不可",
                "kind": "prose",
                "body": [
                    "1950 年代末，程序成本已经压过硬件成本。1959 年的一次调查发现：任何一个数据处理部门的程序开发平均花费 **80 万美元**，而把程序迁移到新硬件上还要再花 **60 万美元**。",
                    "美国国防部的处境最能说明问题：当时运行 225 台计算机，另有 175 台在订购中，已在程序实现上投入超过 **2 亿美元**。如果程序不能跨机器移植，每次换机器都要重写一遍。",
                ],
                "after": [
                    "所以 COBOL 的第一目标不是「优雅」，而是**可移植**：让程序在不同厂商的机器上都能跑，让业务人员也能读懂，让新手能上手。",
                ],
            },
            {
                "id": "naming",
                "title": "名字是怎么来的",
                "kind": "prose",
                "body": [
                    "1959 年 9 月的一次会议上，委员会讨论新语言叫什么。候选名字包括：",
                ],
                "bullets": [
                    "**BUSY**（Business System）",
                    "**INFOSYL**（Information System Language）",
                    "**COCOSYL**（Common Computer Systems Language）",
                ],
                "after": [
                    "最后定名为 **COBOL**（Common Business-Oriented Language），但究竟是谁先提出这个名字，档案里并不清楚——Bob Bemer 后来声称是他建议的，却无法证实。",
                ],
            },
            {
                "id": "fact",
                "title": "FACT 之争与那块墓碑",
                "kind": "prose",
                "body": [
                    "第一版草稿交上来后评价并不好。Joseph Wegstein 说它「仍有粗糙之处」，Bob Bemer 后来直接称其为「大杂烩」。委员会给了更多时间修改。",
                    "真正的转折发生在 1959 年 10 月：中间委员会收到了 Roy Nutt 写的 **FACT** 语言规范，其设计水准之高，让委员会通过决议——**改以 FACT 为基础**。这对已经做出成果的短期委员会是一次重击。",
                    "但决议被推翻了。理由很实际：FACT 虽然技术上更强，却**不是为可移植性设计的，也不是厂商与用户协商的产物**，而且没有可演示的实现。RCA 的 Howard Bromberg 也出手阻止——因为 RCA 在 COBOL 实现上的投入不能白费。",
                    "委员会人太多、推进太慢，Bromberg 的挫败感到了极点：他买了一块刻着「COBOL」的墓碑寄给国防部的 Charles Phillips，以示抗议。",
                ],
                "after": [
                    "规范最终在 **1960 年 1 月 8 日** 获执行委员会批准，由政府印刷局印行，这就是 **COBOL 60**。",
                ],
            },
            {
                "id": "adoption",
                "title": "从「过渡方案」到行业标准",
                "kind": "prose",
                "body": [
                    "COBOL 原本只是被当作**过渡方案**，但国防部随即向计算机制造商施压要求提供实现，这直接推动了它的普及。到 1960 年 9 月，又有五家厂商加入 CODASYL（Bendix、Control Data、General Electric、National Cash Register、Philco），所有已加入的厂商都宣布了 COBOL 编译器。",
                    "早期编译器又慢又贵，这在当时是公开记录：",
                ],
                "bullets": [
                    "1962 年美国海军的一次评测：编译速度 **每分钟 3–11 条语句**。",
                    "到 1964 年中：提升到 **每分钟 11–1000 条语句**。",
                    "每条语句的编译成本从 **0.23 美元到 18.91 美元**不等；内存越大，速度越快。",
                ],
                "after": [
                    "COBOL 难写编译器有客观原因：语法庞大、可选元素多，而且要在同一门语言里支持多种数据表示、隐式类型转换和 I/O 准备。",
                ],
            },
            {
                "id": "standards",
                "title": "标准与兼容性之争",
                "kind": "prose",
                "body": [
                    "各版本互不兼容促使标准化提上日程。1962 年底，ISO 与美国标准协会（今 ANSI）分别成立小组；1968 年 8 月 ANSI 发布 **USA Standard COBOL X3.23**，成为后续各版的基石，ISO 于 1972 年采纳。",
                    "**COBOL-85** 的修订过程是公开的争议事件：",
                ],
                "bullets": [
                    "草案（常被称为 COBOL-80）与 COBOL-74 **不向上兼容**。",
                    "1981 年，Travelers Insurance 的高级副总裁 Joseph T. Brophy 威胁起诉标准委员会，并把公司 4000 万行代码库的历次迁移形容为「非生产性」「完全浪费程序员资源」。",
                    "数据管理协会（DPMA）表示「强烈反对」，理由是转换成本「高得离谱」。",
                    "第一轮公开评审收到 **2200 份**意见，其中 **1700 份是反对信**；转换成本估计至少**每行代码 50 美分**。支持的回复不到十几份。",
                ],
                "after": [
                    "这段历史解释了 COBOL 的一条设计主线：**在不破坏既有代码的前提下增加能力**。也解释了为什么今天仍在运行的 COBOL 程序动辄几十年。",
                ],
            },
            {
                "id": "criticism",
                "title": "批评与辩护",
                "kind": "prose",
                "body": [
                    "1970 年代结构化编程兴起，COBOL 成了靶子。1975 年，Edsger Dijkstra 在《Communications of the ACM》上发表读者来信《How do we tell truths that might hurt?》，其中写道「使用 COBOL 会让头脑残废」（\"the use of COBOL cripples the mind\"）。",
                    "计算机科学家 Howard E. Tompkins 发表了不同意见：非结构化的 COBOL 往往出自「从未受过良好结构化 COBOL 训练的程序员」之手，问题主要在训练而非语言。",
                    "当时的具体技术短板也是有据可查的：",
                ],
                "bullets": [
                    "**`GO TO` 与面条代码**：这是 spaghetti code 的一个成因。但强行移除 `GO TO` 反而让程序更绕、质量更差；它后来基本被 `PERFORM` 与过程取代。",
                    "**`PERFORM` 只能作用于过程**：循环体不在使用它的地方，程序更难读。",
                    "**无法限制数据访问**：直到 COBOL-85 之前，任何过程都能读写任意数据项。",
                    "**不能给过程传参数**：Jean Sammet 认为这是委员会最大的失误；COBOL-85 引入嵌套子程序后才解决。",
                ],
                "after": [
                    "`GO TO` 至今保留，是为了向后兼容——很多其他语言也一样。",
                ],
            },
            {
                "id": "influence",
                "title": "它影响了谁",
                "kind": "table",
                "intro": "COBOL 的数据结构设计影响了后来的语言。",
                "head": ["COBOL 的东西", "影响了"],
                "rows": [
                    ("记录与文件结构", "PL/I 与 Pascal"),
                    ("`REDEFINES` 子句", "Pascal 的变体记录（variant records）"),
                    ("`PICTURE` 数据声明", "PL/I（略作修改后采用）"),
                    ("`COPY` 设施", "后来的 include 指令"),
                ],
                "after": [
                    "另外，COBOL 对**可移植性与标准化**的强调，让程序能跨大量硬件平台与操作系统；它把外部引用限制在 `ENVIRONMENT DIVISION` 的分部结构，也简化了平台更换。显式的文件结构定义更早于数据库管理系统出现，而「聚合数据」相对 Fortran 的数组是一大进步。",
                ],
            },
            {
                "id": "shape",
                "title": "语言本身的一些事实",
                "kind": "table",
                "intro": "这些数字与规则来自标准与官方资料，便于建立整体印象。",
                "head": ["项目", "事实"],
                "rows": [
                    ("保留字", "超过 300 个；部分只是同一词的替代或复数写法，便于句子读起来更自然"),
                    ("可互换的关键词", "`IN` 与 `OF`、`TIME` 与 `TIMES`、`VALUE` 与 `VALUES` 可以互换使用"),
                    ("标准规定的规模", "43 条语句、87 个函数、1 个类（缺少大型标准库）"),
                    ("标识符长度", "最多 31 个字符，可含字母、数字、连字符和下划线"),
                    ("四种词法单位", "词（words）、字面量（literals）、PICTURE 字符串、分隔符（separators）"),
                    ("分部结构", "四个 DIVISION：IDENTIFICATION、ENVIRONMENT、DATA、PROCEDURE"),
                    ("层级", "每个 DIVISION 下分 SECTION，SECTION 下分 PARAGRAPH"),
                    ("格式", "固定格式（默认）与自由格式；COBOL 2002 起把 Area A 与 B 合并为程序文本区，并引入自由格式"),
                ],
            },
        ],
    },
    "en": {
        "eyebrow": "HISTORY",
        "title": "A short history of COBOL",
        "lead": "Standards are not written in the abstract. This one was produced by a specific group of people, inside an argument about whose language should win, on a three-month deadline — and at one point someone mailed the project's sponsor a tombstone engraved \"COBOL\".",
        "note": "The facts here follow COBOL's published historical record, including named people, figures and documented disputes.",
        "sections": [
            {
                "id": "people",
                "title": "The people behind it",
                "kind": "table",
                "intro": "COBOL is often credited to one person, but the record shows a committee effort.",
                "head": ["Person", "Role and contribution"],
                "rows": [
                    ("Mary K. Hawes", "A computer scientist at Burroughs who convened representatives from academia, users and manufacturers at the University of Pennsylvania on 8 April 1959 — the meeting that started it all."),
                    ("Grace Hopper", "Inventor of FLOW-MATIC and a technical adviser to the committee. FLOW-MATIC gave COBOL long variable names, English command words, and the separation of data descriptions from instructions. She is often called the 'mother of COBOL', a claim that is disputed."),
                    ("Jean E. Sammet", "One of COBOL's lead designers and a member of the six-person drafting group. She said Hopper 'was not the mother, creator, or developer of COBOL', and later called the absence of parameter passing the committee's biggest mistake."),
                    ("Bob Bemer", "Inventor of IBM's COMTRAN. He later claimed to have suggested the name COBOL, though it cannot be confirmed."),
                    ("Howard Bromberg", "The RCA representative. Frustrated by the lack of progress, he bought a tombstone engraved 'COBOL' for $15 (about $170 in 2025) and sent it to Charles Phillips at the DoD."),
                    ("Betty Holberton", "A member of the short-range committee who called the three-month specification deadline 'gross optimism' and doubted the language would stay a stopgap."),
                    ("Joseph Wegstein", "Of the US National Bureau of Standards (now NIST), who chaired the committee. Reviewing the first draft, he noted it 'contains rough spots and requires some additions'."),
                    ("Charles A. Phillips", "Director of the Data System Research Staff at the DoD, who agreed to sponsor the effort and had the delegation draft the agenda."),
                    ("Roy Nutt", "Author of the FACT language, which the committee once resolved to adopt as COBOL's basis."),
                ],
                "after": [
                    "The specification itself was drafted by a six-person subcommittee: William Selden and Gertrude Tierney of IBM, Howard Bromberg and Howard Discount of RCA, and Vernon Reeves and Jean E. Sammet of Sylvania. The short-range committee then reviewed and revised their work.",
                ],
            },
            {
                "id": "why",
                "title": "Why it had to happen",
                "kind": "prose",
                "body": [
                    "By the late 1950s programming costs had overtaken hardware costs. A 1959 survey found that in any data processing installation, programming cost an average of **$800,000**, and translating those programs to new hardware would cost another **$600,000**.",
                    "The US Department of Defense illustrates the problem: it operated 225 computers with 175 more on order, and had already spent over **$200 million** implementing programs. If programs could not move between machines, every hardware change meant rewriting them.",
                ],
                "after": [
                    "So COBOL's first goal was not elegance but **portability**: programs that ran on machines from different vendors, that business staff could read, and that newcomers could learn.",
                ],
            },
            {
                "id": "naming",
                "title": "How it got its name",
                "kind": "prose",
                "body": [
                    "At a meeting in September 1959 the committee discussed what to call the new language. Suggestions included:",
                ],
                "bullets": [
                    "**BUSY** (Business System)",
                    "**INFOSYL** (Information System Language)",
                    "**COCOSYL** (Common Computer Systems Language)",
                ],
                "after": [
                    "It ended up as **COBOL** (Common Business-Oriented Language), but who first suggested the name is unclear — Bob Bemer later claimed it, without proof.",
                ],
            },
            {
                "id": "fact",
                "title": "The FACT fight and the tombstone",
                "kind": "prose",
                "body": [
                    "The first draft was not well received. Joseph Wegstein said it 'contains rough spots', and Bob Bemer later called it a 'hodgepodge'. The committee was given more time.",
                    "The real turning point came in October 1959, when the intermediate committee received Roy Nutt's **FACT** specification. Its quality impressed them so much that they passed a resolution to **base COBOL on FACT** — a blow to the short-range committee, who had made real progress.",
                    "The resolution was overturned, for practical reasons: FACT, though technically superior, **had not been designed for portability or agreed with manufacturers and users**, and had no demonstrable implementation. RCA's Howard Bromberg also blocked it, so RCA's investment in a COBOL implementation would not be wasted.",
                    "With too many members to move quickly, Bromberg's frustration peaked: he bought a tombstone engraved 'COBOL' and sent it to Charles Phillips at the DoD as a protest.",
                ],
                "after": [
                    "The specification was approved by the executive committee on **8 January 1960** and printed by the government printing office as **COBOL 60**.",
                ],
            },
            {
                "id": "adoption",
                "title": "From stopgap to industry standard",
                "kind": "prose",
                "body": [
                    "COBOL was originally seen as a **stopgap**, but the DoD promptly pressured manufacturers to provide it, which drove adoption. By September 1960 five more manufacturers had joined CODASYL (Bendix, Control Data, General Electric, National Cash Register and Philco), and every represented manufacturer had announced a COBOL compiler.",
                    "Early compilers were slow and expensive, and that is documented:",
                ],
                "bullets": [
                    "A 1962 US Navy evaluation measured **3–11 statements per minute**.",
                    "By mid-1964 this had risen to **11–1000 statements per minute**.",
                    "Compilation cost ranged from **$0.23 to $18.91 per statement**; more memory meant more speed.",
                ],
                "after": [
                    "Writing a COBOL compiler is genuinely hard: the syntax is large, many elements are optional, and one language must support many data representations, implicit conversions and I/O setup.",
                ],
            },
            {
                "id": "standards",
                "title": "Standards and the compatibility fight",
                "kind": "prose",
                "body": [
                    "Incompatibility between versions pushed standardisation forward. In late 1962 both ISO and the US standards body (now ANSI) formed groups; in August 1968 ANSI published **USA Standard COBOL X3.23**, the cornerstone of later versions, adopted by ISO in 1972.",
                    "The **COBOL-85** revision is a documented controversy:",
                ],
                "bullets": [
                    "The draft (often called COBOL-80) was **not upward compatible** with COBOL-74.",
                    "In 1981 Joseph T. Brophy, a senior vice-president at Travelers Insurance, threatened to sue the standards committee and described past migrations of the company's 40-million-line code base as 'non-productive' and 'a complete waste of our programmer resources'.",
                    "The Data Processing Management Association said it was 'strongly opposed', citing 'prohibitive' conversion costs.",
                    "The first public review drew **2200 responses**, of which **1700 were negative form letters**; conversion costs were predicted at **50 cents per line of code** or more. Fewer than a dozen responses were in favour.",
                ],
                "after": [
                    "This history explains one consistent design theme: **add capability without breaking existing code**. It also explains why COBOL programs still in production are often decades old.",
                ],
            },
            {
                "id": "criticism",
                "title": "Criticism and defence",
                "kind": "prose",
                "body": [
                    "When structured programming spread in the 1970s, COBOL became a target. In 1975 Edsger Dijkstra published a letter to the editor of *Communications of the ACM* titled 'How do we tell truths that might hurt?', in which he wrote that 'the use of COBOL cripples the mind'.",
                    "The computer scientist Howard E. Tompkins published a dissent: unstructured COBOL tended to be 'written by programmers that have never had the benefit of structured COBOL taught well', arguing the problem was mainly training, not the language.",
                    "The concrete technical weaknesses of the time are documented too:",
                ],
                "bullets": [
                    "**`GO TO` and spaghetti code**: one cause of tangled control flow. But attempts to remove `GO TO` produced more convoluted, lower-quality programs; it was largely replaced by `PERFORM` and procedures.",
                    "**`PERFORM` only worked with procedures**, so a loop's body was not located where it was used, making programs harder to read.",
                    "**No way to restrict data access**: until COBOL-85, any procedure could read and modify any data item.",
                    "**No parameter passing to a procedure**: Jean Sammet regarded this as the committee's biggest mistake; COBOL-85 fixed it with nested subprograms.",
                ],
                "after": [
                    "`GO TO` remains for backwards compatibility, as it does in many other languages.",
                ],
            },
            {
                "id": "influence",
                "title": "What it influenced",
                "kind": "table",
                "intro": "COBOL's data structures influenced later languages.",
                "head": ["From COBOL", "Influenced"],
                "rows": [
                    ("Record and file structure", "PL/I and Pascal"),
                    ("The `REDEFINES` clause", "Pascal's variant records"),
                    ("`PICTURE` data declarations", "PL/I, adopted with minor changes"),
                    ("The `COPY` facility", "Later include directives"),
                ],
                "after": [
                    "COBOL's emphasis on **portability and standardisation** let programs move across a wide range of hardware and operating systems, and restricting external references to the `ENVIRONMENT DIVISION` simplified platform changes. Explicit file structure definitions predated database management systems, and aggregated data was a significant advance over Fortran's arrays.",
                ],
            },
            {
                "id": "shape",
                "title": "Some facts about the language itself",
                "kind": "table",
                "intro": "These figures and rules come from the standard and official material, and give a sense of the whole.",
                "head": ["Item", "Fact"],
                "rows": [
                    ("Reserved words", "Over 300; some are simple alternative or pluralised spellings so statements read more naturally"),
                    ("Interchangeable keywords", "`IN` and `OF`, `TIME` and `TIMES`, `VALUE` and `VALUES`"),
                    ("Size of the standard", "43 statements, 87 functions and one class (it lacks a large standard library)"),
                    ("Identifier length", "Up to 31 characters, using letters, digits, hyphens and underscores"),
                    ("Four lexical items", "Words, literals, PICTURE character-strings, separators"),
                    ("Division structure", "Four divisions: IDENTIFICATION, ENVIRONMENT, DATA, PROCEDURE"),
                    ("Hierarchy", "Each division splits into sections, and sections into paragraphs"),
                    ("Format", "Fixed (default) and free; COBOL 2002 merged Areas A and B into the program-text area and introduced free format"),
                ],
            },
        ],
    },
    "ja": {
        "eyebrow": "HISTORY",
        "title": "COBOL 史話",
        "lead": "標準は抽象的に生まれるものではありません。これは特定の人々が、どの言語を採用するかをめぐる議論の中で、3 か月という期限のもとに作り上げたものです。途中、ある人物はプロジェクトの後援者に「COBOL」と刻んだ墓石を送りつけました。",
        "note": "本ページの史実は COBOL の公開された歴史資料に基づき、人物名・数字・記録された論争を含みます。",
        "sections": [
            {
                "id": "people",
                "title": "関わった人々",
                "kind": "table",
                "intro": "COBOL はしばしば一人の功績とされますが、記録は委員会による共同作業だったことを示しています。",
                "head": ["人物", "役割と貢献"],
                "rows": [
                    ("Mary K. Hawes", "Burroughs の計算機科学者。1959 年 4 月 8 日、ペンシルバニア大学で学界・利用者・メーカーの代表を招集し、この取り組みを始めました。"),
                    ("Grace Hopper", "FLOW-MATIC の開発者で委員会の技術顧問。FLOW-MATIC は長い変数名、英語の命令語、データ記述と命令の分離を COBOL にもたらしました。しばしば「COBOL の母」と呼ばれますが、この呼称には異論があります。"),
                    ("Jean E. Sammet", "COBOL の主要設計者の一人で、6 名の起草グループの成員。Hopper は「COBOL の母でも創造者でも開発者でもない」と述べ、後に「引数の受け渡しが無いこと」を委員会最大の誤りと評しました。"),
                    ("Bob Bemer", "IBM の COMTRAN の開発者。COBOL という名前を自分が提案したと後に主張しましたが、確認はできません。"),
                    ("Howard Bromberg", "RCA の代表。進行の遅さに苛立ち、15 ドル（2025 年換算で約 170 ドル）で「COBOL」と刻んだ墓石を買い、国防総省の Charles Phillips に送りました。"),
                    ("Betty Holberton", "短期委員会の成員。3 か月で仕様を出すという期限を「極度の楽観」と呼び、暫定言語にとどまるとは考えていませんでした。"),
                    ("Joseph Wegstein", "米国標準局（現 NIST）所属で委員会の議長。最初の草案を「粗い箇所があり追加が必要」と評しました。"),
                    ("Charles A. Phillips", "国防総省データシステム研究部門の責任者。この取り組みの後援を承諾し、代表団に議題の作成を指示しました。"),
                    ("Roy Nutt", "FACT 言語の作者。委員会は一時、COBOL の基礎を FACT に置く決議を可決しました。"),
                ],
                "after": [
                    "仕様の実作業は 6 名の小委員会が担いました。IBM の William Selden と Gertrude Tierney、RCA の Howard Bromberg と Howard Discount、Sylvania の Vernon Reeves と Jean E. Sammet です。その後、短期委員会が検討と修正を行いました。",
                ],
            },
            {
                "id": "why",
                "title": "なぜ必要だったのか",
                "kind": "prose",
                "body": [
                    "1950 年代末、プログラム費用はハードウェア費用を上回っていました。1959 年の調査では、どのデータ処理部門でもプログラム開発に平均 **80 万ドル**、さらに新しいハードウェアへ移行するのに **60 万ドル**かかるとされていました。",
                    "米国防総省の状況が典型的です。当時 225 台の計算機を運用し 175 台を追加発注、プログラム実装に **2 億ドル以上**を投じていました。プログラムが機械をまたげなければ、更新のたびに書き直しが必要でした。",
                ],
                "after": [
                    "したがって COBOL の第一の目標は「美しさ」ではなく**移植性**でした。異なるメーカーの機械で動き、業務担当者が読め、初心者も学べることです。",
                ],
            },
            {
                "id": "naming",
                "title": "名前の由来",
                "kind": "prose",
                "body": [
                    "1959 年 9 月の会合で、委員会は新しい言語の名前を検討しました。候補は次のとおりです。",
                ],
                "bullets": [
                    "**BUSY**（Business System）",
                    "**INFOSYL**（Information System Language）",
                    "**COCOSYL**（Common Computer Systems Language）",
                ],
                "after": [
                    "最終的に **COBOL**（Common Business-Oriented Language）に落ち着きましたが、誰が最初に提案したかは不明です。Bob Bemer が後に自分の提案だと主張しましたが、裏付けはありません。",
                ],
            },
            {
                "id": "fact",
                "title": "FACT 論争と墓石",
                "kind": "prose",
                "body": [
                    "最初の草案の評価は芳しくありませんでした。Joseph Wegstein は「粗い箇所がある」と述べ、Bob Bemer は後に「寄せ集め」と評しました。委員会には修正の時間が与えられます。",
                    "転機は 1959 年 10 月、中間委員会が Roy Nutt の **FACT** 仕様を受け取ったときでした。その完成度に委員は感銘を受け、**COBOL の基礎を FACT に置く**決議を可決します。これは成果を上げていた短期委員会にとって打撃でした。",
                    "しかし決議は覆されます。理由は現実的でした。FACT は技術的に優れていたものの、**移植性を意図しておらず、メーカーと利用者の合意も経ておらず**、実装の実例もありませんでした。RCA の Howard Bromberg も反対しました。RCA の COBOL 実装への投資を無駄にしないためです。",
                    "人数が多く進行が遅いことに苛立った Bromberg は、ついに「COBOL」と刻んだ墓石を買い、抗議として国防総省の Charles Phillips に送りました。",
                ],
                "after": [
                    "仕様は **1960 年 1 月 8 日**に執行委員会で承認され、政府印刷局から **COBOL 60** として刊行されました。",
                ],
            },
            {
                "id": "adoption",
                "title": "暫定案から業界標準へ",
                "kind": "prose",
                "body": [
                    "COBOL は当初**暫定的な言語**と見なされていましたが、国防総省がメーカーに実装を提供するよう圧力をかけたことで普及が進みました。1960 年 9 月までに 5 社（Bendix、Control Data、General Electric、National Cash Register、Philco）が CODASYL に加わり、参加した全メーカーが COBOL コンパイラを発表しています。",
                    "初期のコンパイラが低速で高価だったことは記録に残っています。",
                ],
                "bullets": [
                    "1962 年の米海軍の評価では **毎分 3〜11 文**。",
                    "1964 年半ばには **毎分 11〜1000 文**に向上。",
                    "文あたりのコンパイル費用は **0.23〜18.91 ドル**。メモリが多いほど高速でした。",
                ],
                "after": [
                    "COBOL のコンパイラが難しいのは事実です。文法が大きく任意要素が多く、さらに一つの言語で多様なデータ表現、暗黙の型変換、入出力の準備を支える必要があります。",
                ],
            },
            {
                "id": "standards",
                "title": "標準化と互換性をめぐる争い",
                "kind": "prose",
                "body": [
                    "版ごとの非互換が標準化を促しました。1962 年末に ISO と米国規格協会（現 ANSI）がそれぞれ委員会を作り、1968 年 8 月に ANSI が **USA Standard COBOL X3.23** を発行。これが後の各版の基盤となり、1972 年に ISO が採用しました。",
                    "**COBOL-85** の改訂は記録に残る論争でした。",
                ],
                "bullets": [
                    "草案（一般に COBOL-80 と呼ばれる）は COBOL-74 と**上位互換ではありませんでした**。",
                    "1981 年、Travelers Insurance の上級副社長 Joseph T. Brophy は標準委員会を訴えると脅し、同社の 4000 万行の移行を「非生産的」「プログラマー資源の完全な浪費」と述べました。",
                    "データ処理管理協会（DPMA）は変換費用が「法外」として「強く反対」を表明しました。",
                    "最初の公開審査には **2200 件**の回答があり、うち **1700 件が反対のはんこ書簡**でした。変換費用は**コード 1 行あたり 50 セント以上**と予測されています。賛成は十数件に満たませんでした。",
                ],
                "after": [
                    "この歴史は COBOL の一貫した設計方針を説明します。**既存コードを壊さずに能力を足す**ことです。現在も本番稼働する COBOL プログラムが数十年単位である理由でもあります。",
                ],
            },
            {
                "id": "criticism",
                "title": "批判と擁護",
                "kind": "prose",
                "body": [
                    "1970 年代に構造化プログラミングが広まると、COBOL は標的になりました。1975 年、Edsger Dijkstra は *Communications of the ACM* への投書「How do we tell truths that might hurt?」で「COBOL を使うと頭が駄目になる」（\"the use of COBOL cripples the mind\"）と記しています。",
                    "計算機科学者 Howard E. Tompkins は異論を発表しました。非構造化 COBOL は「構造化 COBOL をきちんと教わったことのないプログラマー」が書いたもので、問題は主に教育にあるという主張です。",
                    "当時の具体的な弱点も記録されています。",
                ],
                "bullets": [
                    "**`GO TO` とスパゲッティコード**：制御が絡む一因でした。ただし `GO TO` を無理に除くとむしろ複雑で品質の低いプログラムになり、後に `PERFORM` と手続きに置き換えられました。",
                    "**`PERFORM` は手続きにしか使えない**：ループ本体が使用箇所になく、可読性を下げました。",
                    "**データアクセスを制限できない**：COBOL-85 まで、どの手続きも任意のデータ項目を読み書きできました。",
                    "**手続きに引数を渡せない**：Jean Sammet はこれを委員会最大の誤りと見なし、COBOL-85 の入れ子副プログラムで解決されました。",
                ],
                "after": [
                    "`GO TO` は後方互換のため今も残っています。他の多くの言語と同じです。",
                ],
            },
            {
                "id": "influence",
                "title": "何に影響したか",
                "kind": "table",
                "intro": "COBOL のデータ構造は後続の言語に影響を与えました。",
                "head": ["COBOL の要素", "影響先"],
                "rows": [
                    ("レコードとファイル構造", "PL/I と Pascal"),
                    ("`REDEFINES` 句", "Pascal の variant record"),
                    ("`PICTURE` データ宣言", "PL/I（小幅な変更を加えて採用）"),
                    ("`COPY` 機能", "後の include 指令"),
                ],
                "after": [
                    "さらに、**移植性と標準化**への注力により、プログラムは多様なハードウェアと OS をまたげるようになりました。外部参照を `ENVIRONMENT DIVISION` に限定する分部構造も、プラットフォーム変更を容易にしました。明示的なファイル構造定義はデータベース管理システムより早く、集約データは Fortran の配列に対する大きな前進でした。",
                ],
            },
            {
                "id": "shape",
                "title": "言語そのものについての事実",
                "kind": "table",
                "intro": "規格と公式資料による数字と規則です。全体像の把握に役立ちます。",
                "head": ["項目", "事実"],
                "rows": [
                    ("予約語", "300 以上。一部は同じ語の別表記や複数形で、文が自然に読めるようにするためです"),
                    ("交換可能なキーワード", "`IN` と `OF`、`TIME` と `TIMES`、`VALUE` と `VALUES`"),
                    ("規格の規模", "43 の文、87 の関数、1 つのクラス（大きな標準ライブラリを持ちません）"),
                    ("識別子の長さ", "最大 31 文字。英字、数字、ハイフン、アンダースコアが使えます"),
                    ("4 つの字句要素", "語（words）、リテラル（literals）、PICTURE 文字列、区切り子（separators）"),
                    ("分部構造", "4 つの DIVISION：IDENTIFICATION、ENVIRONMENT、DATA、PROCEDURE"),
                    ("階層", "各 DIVISION は SECTION に、SECTION は PARAGRAPH に分かれます"),
                    ("形式", "固定形式（既定）と自由形式。COBOL 2002 で Area A と B が統合され、自由形式が導入されました"),
                ],
            },
        ],
    },
}
