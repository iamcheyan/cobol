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
    "zh-cn": {'eyebrow': 'BACKGROUND',
     'title': 'COBOL 是什么',
     'lead': 'COBOL 是一门为**商业数据处理**而生的语言：它用接近英语的句子描述记录、文件和整批作业，写给要长期维护的账务系统看。1959 '
             '年由美国国防部牵头、多家厂商与政府机构共同设计；六十多年后，银行、保险、政务系统的日终批处理里仍有大量程序是它写的。下面按时间讲清楚它为什么长成这样，以及今天的 GnuCOBOL 又是从哪儿来的。',
     'source_note': '本页史实依据 COBOL 的公开历史资料、ISO 标准编号，以及 GnuCOBOL 源码仓库中的 AUTHORS / THANKS / ChangeLog 整理。',
     'sections': [{'id': 'what',
                   'title': '它是什么',
                   'kind': 'prose',
                   'body': ['COBOL 是 **Common Business-Oriented Language** '
                            '的缩写。它的定位从名字就写死了：处理商业数据，不是科学计算，也不是写操作系统。',
                            '要理解它为什么长得跟现代语言不一样，得先知道它面向的活儿是什么样：**每天夜里，把成千上万条交易记录逐条过一遍账**。这种活儿的特点不是算得复杂，而是量极大、规则几十年不变、出错就是真金白银的账目错误。所以它的设计处处优先「稳」和「读得懂」：'],
                   'bullets': ['**数据描述与执行步骤分开写**：先在一处声明「一条记录有多宽、每个字段多少位」，再在另一处写「怎么处理」。这个分离是为了让程序能跨机器移植——当年每台机器的数据表示都不一样。',
                               '**代码写得像英语**：`ADD 1 TO WS-COUNT`、`IF WS-STATUS = '
                               "'A'`。刻意的啰嗦，为了业务人员能看懂、为了让二十年后接手的人不必猜。",
                               '**定长记录、顺序文件、排序对账是主场**：这门课的全部示例都建立在这套模型上。',
                               '**它是编译型语言**：源码经 `cobc` 编译成原生可执行程序，不是脚本。'],
                   'after': ['一句话概括：COBOL 把业务规则写成接近英语的固定格式文本，交给编译器变成能在大型机或 Linux 上连续跑几十年的批处理程序。']},
                  {'id': 'origin',
                   'title': '它从何而来：一场被逼出来的联合行动',
                   'kind': 'timeline',
                   'intro': 'COBOL 不是谁一拍脑袋发明的。它诞生于一个很具体的问题：**美国政府买了太多不同牌子的计算机，程序却没法互相搬。**',
                   'items': [('1959-04-08',
                              '先有人提议',
                              'Burroughs 的计算机科学家 **Mary K. Hawes** '
                              '在宾夕法尼亚大学召集学界、用户与厂商代表开会，议题只有一个：要不要搞一门通用的商业语言。与会者里有 Grace Hopper、Jean Sammet 和 Saul '
                              'Gorn。'),
                             ('1959-05-28',
                              '五角大楼拍板',
                              '一个月后，美国国防部出资在五角大楼开会，41 人参加，由 Charles A. Phillips 主持。**为什么军方这么急**：当时国防部自己有 225 '
                              '台计算机，还有 175 台正在订购，型号各不相同。每换一次机器就要重写一遍程序，采购和迁移成本高得离谱。统一语言直接等于省钱。'),
                             ('1959-06-04',
                              '成立组织',
                              '指导委员会把这项活动命名为 **CODASYL**（Committee on Data Systems '
                              'Languages），并成立执行委员会。短期委员会被要求三个月内交出临时语言规范——这个死线逼出了后来 COBOL 60 的雏形。'),
                             ('1960-04',
                              'COBOL 60 问世',
                              '第一版规范提交给 CODASYL。它主要吸收了三门语言的经验：Grace Hopper 的 '
                              '**FLOW-MATIC**（长变量名、英语命令、数据与指令分离——COBOL 最核心的两个特征都来自这里）、IBM 的 **COMTRAN**，以及 '
                              'AIMACO。'),
                             ('1963',
                              '把语法理清楚',
                              'COBOL 60 被发现存在歧义，委员会做了系统性清理。到 1963 年，其语法的可定义程度已与 ALGOL 相当。早期编译器非常慢：1962 '
                              '年一次美国海军评测记录的速度是**每分钟 3–11 条语句**——一条几百行的程序要编译十几分钟。'),
                             ('1968-08',
                              '成为国家标准',
                              'ANSI 发布 USA Standard COBOL X3.23（即 ANS COBOL），成为后续各版的基石；ISO 于 1972 '
                              '年采纳。从这一刻起，COBOL 不再是某家厂商的方言，而是有正式标准约束的语言。'),
                             ('1974',
                              'COBOL-74',
                              'ANSI 发布修订版。此前 CODASYL 在 1968–1973 年间持续改进语言，加入程序间通信、调试、文件合并、字符串处理与库引入等能力。'),
                             ('1985',
                              'COBOL-85：最大的一次争议',
                              '这次修订动静很大：草案与 COBOL-74 **不向上兼容**，保险公司一个 4000 万行的代码库面临迁移，被公开形容为「非生产性工作」。第一轮公开评审收到 '
                              '2200 份意见，其中 **1700 份是反对**。但标准最终还是推行了——而「改语言要小心别把存量代码搞死」也从此成了 COBOL 演进的第一原则。'),
                             ('2002',
                              '面向对象',
                              'ISO 发布 COBOL 2002，加入面向对象、自由格式源码、用户自定义函数、递归、区域设置与扩展字符集。有意思的是，这些特性多数在 CODASYL 1978 '
                              '年的开发期刊里就已经提过，只是错过了 COBOL-85 那一班车。'),
                             ('2014', 'COBOL 2014', '把部分设施改为可选（如 VALIDATE、报表写出器、屏幕处理），引入 IEEE 754 数据类型与方法重载。'),
                             ('2023',
                              'COBOL 2023',
                              '最新标准：异步消息（`SEND`/`RECEIVE`）、事务处理（`COMMIT`/`ROLLBACK`）、`XOR`、`PERFORM UNTIL '
                              'EXIT`、`SUBSTITUTE`、`CONVERT` 等。GCC 15.1 起自带的 `gcobol` 即基于此标准。')],
                   'after': ['当前标准编号是 **ISO/IEC 1989:2023**。六十四年、十来个版本，主线始终是同一句话：**在不破坏既有代码的前提下增加能力**。这也解释了为什么一段 '
                             '1980 年代的 COBOL 程序，今天还能原样编译、原样运行。']},
                  {'id': 'gnucobol',
                   'title': 'GnuCOBOL 又是从哪儿来的',
                   'kind': 'prose',
                   'body': ['上面讲的是**语言标准**。标准只是纸面规范，真正把 `.cob` '
                            '文件变成能跑的程序，需要一个**编译器**。过去这类编译器都是商业软件，装在昂贵的大型机上，个人和小团队根本碰不到。GnuCOBOL 就是把这个门槛拆掉的那个项目。',
                            '它的路走得挺绕：'],
                   'bullets': ['**2002 年 1 月**，日本开发者 **西田圭介（Keisuke Nishida）** 发布了 **OpenCOBOL** 0.9：一个用 C '
                               '语言写的自由 COBOL 编译器。它的做法很聪明——不直接生成机器码，而是**把 COBOL 翻译成 C**，再交给系统上的 C 编译器编译。于是只要有 '
                               'gcc，任何平台都能跑 COBOL。',
                               '**2009 年** OpenCOBOL 1.1 发布。之后项目一度缺少维护者。',
                               '**2013 年**，OpenCOBOL 被接纳为 GNU 项目并改名为 **GnuCOBOL**，2014 年 1 月发布 GnuCOBOL '
                               '1.1。改名的同时，社区开始接手长期维护——其中出力最多的是 **Roger While**（1950–2015）和德国的 **Simon Sobisch**。',
                               '**今天**，GnuCOBOL 的 THANKS 文件里列出的维护者是 **Keisuke Nishida**（原始作者）、**Roger '
                               'While**（2015 年去世）和 **Simon Sobisch**；活跃开发在 GNU 与 SourceForge 上进行，当前稳定版是 3.2（2023 '
                               '年 7 月），4.0 正在开发。'],
                   'after': ['**为什么这件事重要**：GnuCOBOL 让 COBOL 从「只有大机构才玩得起」变成了「`apt install gnucobol` 就能学」。它实现了 '
                             'COBOL 85、2002、2014 标准的很大一部分，还支持 JD Edwards、Micro Focus、IBM 等厂商的扩展方言。',
                             '在 Debian 或 Ubuntu 上运行 `sudo apt install gnucobol`，就能在家用 Linux 安装编译器，编译和运行本课程的固定格式代码，不需要大型机。GnuCOBOL 将 COBOL 源码翻译成 C，再调用系统的 C 编译器生成程序；它适合学习和验证代码，但不代表主机编译器方言、数据表示和生产行为完全一致。',
                             '这门课用的就是它。你在[第 01 课](lessons/01_hello-cobol/README.html)里敲的第一个 `cobc` 命令，编译的就是 '
                             'GnuCOBOL。']},

                              {'id': 'japan',
             'title': '它在日本仍然是现役语言',
             'kind': 'prose',
             'body': ['这也是用中文读这门课的实际理由：COBOL 不是“国外的老故事”，而是**日本基干系（基幹系）系统里的现役语言**。',
                      '大型银行、地方银行、信用金库、保险、信用卡、证券，以及地方政府的住民记录与年金——这些“不能停”的系统，很多今天仍在跑 COBOL '
                      '批处理。原因很朴素：**让正在运行的系统停下来重写，比维护它更危险**。'],
             'bullets': ['**日本厂商提供的 COBOL 环境**：富士通 NetCOBOL 等产品，为把大型机上的 COBOL 资产迁移到开放平台继续运行提供了路线。2025 年 1 '
                         '月，高知信用金库宣布将勘定系系统从大型机迁往 NetCOBOL，目标于 2030 年 1 月完成。',
                         '**“2025 年的悬崖”与人才短缺**：日本经济产业省提出的“2025 年の崖”使遗留系统维护与迁移人才不足成为社会议题。2024 年 10 月，SCSK 与 FPT Japan '
                         '宣布开始协商设立合资公司 COBOL PARK，计划为金融机构提供维护既有系统和迁移等方案。',
                         '**GnuCOBOL 与日本开发者**：GnuCOBOL 的前身 OpenCOBOL 由日本开发者**西田圭介（Keisuke Nishida）**于 2002 年发布。项目如今在 GNU 项目下由 Simon Sobisch 等人持续开发。Debian/Ubuntu 用户可运行 `sudo apt install gnucobol`，在家用 Linux 编译并运行课程中的固定格式程序；GnuCOBOL 会先把 COBOL 源码翻译成 C，再调用系统 C 编译器，因此学习不需要大型机。它提供可用的学习环境，但与大型机编译器的方言、数据表示和生产行为不保证完全一致。',
                         '**日本现场用语**：常见词包括“勘定系”“基幹系”“日中バッチ”“夜間バッチ”“突合（とつごう）”“項目（字段）”“桁（位数）”。本课程程序输出也采用日文业务标签，并在讲义中解释含义。'],

             'after': ['所以这门课的重点不是背语法，而是**能在现场读懂**：固定格式的列位置、`FILE STATUS` 的判定、对账的计数不变量、异常时的退出码。这些知识在日本现场同样通用。',
                       '从[第 01 课](lessons/01_hello-cobol/README.html)开始，动手验证一遍。']},
{'id': 'industries',
                   'title': '它今天还在哪些地方跑',
                   'kind': 'table',
                   'intro': 'COBOL 的存量集中在一类场景：**交易量大、规则稳定、错一笔都是钱**。这些系统换掉的成本极高，所以它们一直在跑。',
                   'head': ['行业', '典型用途'],
                   'rows': [('银行与金融', '账户与账务、日终批处理、对账、清算、利息与费用计算'),
                            ('保险', '保单、理赔、保费计算与批量结算'),
                            ('零售与流通', '库存、结算、供应链批处理'),
                            ('航空与旅行', '订座与运价等长期运行的交易系统'),
                            ('医疗与公共事业', '理赔与缴费等批量处理'),
                            ('政府机构', '税务、福利、社保等大型事务处理系统')],
                   'after': ['运行平台同样很广：z/OS、z/VSE、VME、Unix、NonStop OS、OpenVMS、Windows 等。']},
                  {'id': 'legacy',
                   'title': '为什么它还没被替换掉',
                   'kind': 'prose',
                   'body': ['常有人问：这么老的语言，为什么不重写？答案不是「懒」，而是**重写的风险比维护更大**。下面这组数字说明存量有多大：'],
                   'bullets': ['1997 年 Gartner Group 的估算：全世界约有 **2000 亿行** COBOL 代码，承载了商业程序中的 '
                               '**80%**。这个数字流传很广，也要打折看——它的统计口径一直有争议，但量级是公认的。',
                               '2020 年前后：**95%** 的信用卡/借记卡刷卡交易，后台处理都经过 COBOL 程序。也就是说你每天刷卡，几乎必然碰到它。',
                               '2006 与 2012 年 Computerworld 的调查：超过 **60%** 的组织仍在使用 COBOL，其中约一半把它用于大部分内部软件。',
                               '2016 年美国众议院监督与政府改革委员会听证会记录：美国农业部、国土安全部、卫生与公众服务部、司法部、财政部、退伍军人事务部、国税局等机构仍在使用 '
                               'COBOL。'],
                   'after': ['**千年虫（Y2K）**是 COBOL 最近一次被大众注意到。为什么偏偏是它？因为商业系统大量用日期做键、数据又是定长字段，存两位年份的地方全要改。有研究把高达 '
                             '**24%** 的 Y2K 修复成本归因于 COBOL。而清理完之后，2003 年的一次调查发现这些程序大多仍在服役——修完继续用，而不是趁机重写。',
                             '**人才缺口**是当下更实在的问题：到 2019 年，COBOL '
                             '程序员因退休而快速减少，而重写既有系统的成本高、风险大——一些银行的多年度迁移项目曾造成服务中断并招致罚款。COVID-19 期间，美国多个州的失业救济系统出现 '
                             'COBOL 程序员短缺，还上了新闻。',
                             '所以这门课的价值不在「追新」，而在于：**能读懂并安全修改已经在生产环境里跑了几十年的批处理程序**，同时用现代工具（编译器诊断、结构导航、测试）把它维护好。']},
                  {'id': 'shape',
                   'title': '它长什么样',
                   'kind': 'code',
                   'intro': '一个最小可运行的固定格式程序。前七列留空，第 8 列起写程序正文——第 01 课有一张列布局图专门解释这件事：',
                   'code': '       IDENTIFICATION DIVISION.\n'
                           '       PROGRAM-ID. HELLO.\n'
                           '       DATA DIVISION.\n'
                           '       WORKING-STORAGE SECTION.\n'
                           '       01 WS-NAME PIC X(10) VALUE "COBOL".\n'
                           '       PROCEDURE DIVISION.\n'
                           '           DISPLAY "HELLO, " WS-NAME.\n'
                           '           STOP RUN.',
                   'after': ['四个 Division 各司其职：`IDENTIFICATION` 说明程序身份，`DATA` 描述数据，`PROCEDURE` 写执行步骤。`01` '
                             '定义记录或字段，`PIC X(10)` 表示 10 个字符位置。',
                             '想动手跑起来，从[第 01 '
                             '课](lessons/01_hello-cobol/README.html)开始；想查语句与字段定义规则，用[速查手册](reference.html)。想了解标准演进的细节，看[COBOL '
                             '简史](history.html)。']}]},
    "en": {'eyebrow': 'BACKGROUND',
     'title': 'What is COBOL',
     'lead': 'COBOL is a language built for **business data processing**: it describes records, files and whole '
             'batch runs in sentences that read like English, written to be maintained for decades. The US '
             'Department of Defense pressed for it in 1959, with manufacturers and government agencies designing '
             'it together; sixty-odd years later, a large share of nightly batch work in banking, insurance and '
             'government is still written in it. What follows is the story of why it looks the way it does — and '
             "where today's GnuCOBOL came from.",
     'source_note': "Facts here follow COBOL's public history, the ISO standard numbers, and the AUTHORS / "
                    'THANKS / ChangeLog files in the GnuCOBOL source tree.',
     'sections': [{'id': 'what',
                   'title': 'What it is',
                   'kind': 'prose',
                   'body': ['COBOL stands for **Common Business-Oriented Language**. The name pins down its '
                            'purpose: business data, not scientific computing, not operating systems.',
                            'To see why it looks unlike modern languages, first look at the work it was built '
                            'for: **every night, walk tens of thousands of transaction records through an '
                            'accounting pass.** The difficulty is not cleverness — it is volume, rules that hold '
                            'for decades, and errors that become real money. So everything in the design favours '
                            '*stability* and *legibility*:'],
                   'bullets': ['**Data description is separate from the procedure**: declare once how wide a '
                               'record is and how many positions each field has, then write elsewhere what to do '
                               'with it. That split is what made programs portable — every machine represented '
                               'data differently at the time.',
                               "**Code reads like English**: `ADD 1 TO WS-COUNT`, `IF WS-STATUS = 'A'`. The "
                               'verbosity is deliberate, so business staff can read it and whoever inherits it '
                               'in twenty years does not have to guess.',
                               '**Fixed-length records, sequential files, sorting and reconciliation are its '
                               'home ground**: every example in this course uses that model.',
                               '**It is compiled**: source goes through `cobc` into a native executable, not a '
                               'script.'],
                   'after': ['In one line: COBOL writes business rules as near-English fixed-format text, and a '
                             'compiler turns them into batch programs that run for decades on a mainframe or on '
                             'Linux.']},
                  {'id': 'origin',
                   'title': 'Where it came from: a forced collaboration',
                   'kind': 'timeline',
                   'intro': 'COBOL was not invented in a flash. It came out of one concrete problem: **the US '
                            'government had bought too many incompatible computers, and programs could not move '
                            'between them.**',
                   'items': [('1959-04-08',
                              'Someone proposes it',
                              '**Mary K. Hawes**, a computer scientist at Burroughs, gathered academics, users '
                              'and manufacturers at the University of Pennsylvania with one question: do we need '
                              'a common business language? Attendees included Grace Hopper, Jean Sammet and Saul '
                              'Gorn.'),
                             ('1959-05-28',
                              'The Pentagon commits',
                              'A month later the US Department of Defense funded a meeting at the Pentagon: 41 '
                              'people, chaired by Charles A. Phillips. **Why the urgency**: the department '
                              'already ran 225 computers and had another 175 on order, all different models. '
                              'Every machine change meant rewriting the software, so procurement and migration '
                              'costs were spiralling. One common language was, quite literally, a cost saving.'),
                             ('1959-06-04',
                              'An organisation forms',
                              'The steering committee named the effort **CODASYL** (Committee on Data Systems '
                              'Languages) and set up an executive committee. A short-range committee was given '
                              'three months to produce an interim language specification — that deadline '
                              'produced the draft that became COBOL 60.'),
                             ('1960-04',
                              'COBOL 60 arrives',
                              'The first specification went to CODASYL. It drew mainly on three languages: Grace '
                              "Hopper's **FLOW-MATIC** (long names, English verbs, data separated from "
                              "instructions — COBOL's two defining traits come from here), IBM's **COMTRAN**, "
                              'and AIMACO.'),
                             ('1963',
                              'Clearing up the grammar',
                              'COBOL 60 turned out to be ambiguous, and the committee cleaned it up '
                              "systematically. By 1963 its grammar was about as definable as ALGOL's. Early "
                              'compilers were painfully slow: a 1962 US Navy evaluation recorded **3–11 '
                              'statements per minute** — a few hundred lines took a quarter of an hour to '
                              'compile.'),
                             ('1968-08',
                              'A national standard',
                              'ANSI published USA Standard COBOL X3.23 (ANS COBOL), the basis for every later '
                              'edition; ISO adopted it in 1972. From then on COBOL was no longer a vendor '
                              'dialect but a language governed by a formal standard.'),
                             ('1974',
                              'COBOL-74',
                              'ANSI published a revision. CODASYL had spent 1968–1973 adding inter-program '
                              'communication, debugging, file merge, string handling and library facilities.'),
                             ('1985',
                              'COBOL-85: the loudest fight',
                              'This revision was disruptive: the draft was **not upward compatible** with '
                              'COBOL-74, and one insurer faced migrating a 40-million-line codebase, publicly '
                              'called unproductive work. The first public review drew 2,200 comments, **1,700 of '
                              'them objections**. The standard went ahead anyway — and "do not break existing '
                              'code" became COBOL\'s first rule of evolution.'),
                             ('2002',
                              'Object orientation',
                              'ISO published COBOL 2002: object orientation, free-format source, user-defined '
                              'functions, recursion, locale handling and extended character sets. Most of these '
                              "had already appeared in CODASYL's 1978 development journal, and simply missed the "
                              'COBOL-85 train.'),
                             ('2014',
                              'COBOL 2014',
                              'Made some facilities optional (VALIDATE, the report writer, screen handling) and '
                              'added IEEE 754 data types and method overloading.'),
                             ('2023',
                              'COBOL 2023',
                              'The current standard: asynchronous messaging (`SEND`/`RECEIVE`), transaction '
                              'processing (`COMMIT`/`ROLLBACK`), `XOR`, `PERFORM UNTIL EXIT`, `SUBSTITUTE`, '
                              '`CONVERT` and more. The `gcobol` front end shipped with GCC 15.1 follows this '
                              'standard.')],
                   'after': ['The current standard is **ISO/IEC 1989:2023**. Sixty-four years and a dozen '
                             'editions, with one constant theme: **add capability without breaking existing '
                             'code**. Which is why a 1980s COBOL program can still compile and run unchanged '
                             'today.']},
                  {'id': 'gnucobol',
                   'title': 'Where GnuCOBOL came from',
                   'kind': 'prose',
                   'body': ['All of that is the **language standard**. A standard is only paper; turning a '
                            '`.cob` file into a running program needs a **compiler**. Those used to be '
                            'commercial products installed on expensive mainframes, out of reach for individuals '
                            'and small teams. GnuCOBOL is the project that removed that barrier.',
                            'Its path was indirect:'],
                   'bullets': ['**January 2002**: Japanese developer **Keisuke Nishida** released **OpenCOBOL** '
                               '0.9, a free COBOL compiler written in C. The trick was clever — it does not emit '
                               'machine code directly but **translates COBOL into C** and hands that to the '
                               'system C compiler. Anywhere a C compiler exists, COBOL runs.',
                               '**2009**: OpenCOBOL 1.1 shipped. Afterwards the project went through a period '
                               'without a maintainer.',
                               '**2013**: OpenCOBOL was accepted as a GNU project and renamed **GnuCOBOL**; '
                               'version 1.1 followed in January 2014. With the rename, the community took over '
                               "long-term maintenance — **Roger While** (1950–2015) and Germany's **Simon "
                               'Sobisch** contributing most.',
                               '**Today** the GnuCOBOL THANKS file lists **Keisuke Nishida** (original author), '
                               '**Roger While** (died 2015) and **Simon Sobisch** as past and present '
                               'maintainers. Development runs on GNU and SourceForge infrastructure; the current '
                               'stable release is 3.2 (July 2023), with 4.0 in development.'],
                   'after': ['**Why this matters**: GnuCOBOL turned COBOL from something only large institutions '
                             'could afford into something you install with `apt install gnucobol`. It implements '
                             'a large part of COBOL 85, 2002 and 2014, and supports vendor extensions such as JD '
                             'Edwards, Micro Focus and IBM dialects.',
                             'On Debian or Ubuntu, `sudo apt install gnucobol` installs the compiler so you can build and run this course’s fixed-format examples on Linux at home, without a mainframe. GnuCOBOL translates COBOL source into C and invokes the system C compiler; it is useful for learning and checking code, though mainframe dialects, data representations and production behavior may differ.',
                             'It is what this course uses. The first `cobc` command you type in [Lesson '
                             '01](lessons/01_hello-cobol/README.html) is GnuCOBOL.']},

                  {'id': 'japan',
             'title': 'Still in production in Japan',
             'kind': 'prose',
             'body': ['This is the practical reason the course is also worth reading outside Japan: COBOL is not a '
                      "foreign relic — it is **the working language of Japan's core banking and administrative "
                      'systems**.',
                      'Megabanks, regional banks, shinkin credit unions, insurers, card processors, securities firms, '
                      'and municipal resident and pension systems: many of the systems that must never stop still run '
                      'COBOL batch jobs. The reason is simple — **stopping a running system to rewrite it is riskier '
                      'than maintaining it**.'],
             'bullets': ['**Japanese vendors provide migration options**: products such as Fujitsu NetCOBOL can help organizations move COBOL assets from mainframes to open systems. In January 2025, Kochi Shinkin Bank announced plans to migrate its core accounting system to NetCOBOL, targeting completion in January 2030.',
                         '**The “2025 cliff” and skills shortage**: Japan’s Ministry of Economy, Trade and Industry raised concerns about legacy-system risks around 2025, including a shortage of engineers able to maintain and migrate those systems. In October 2024, SCSK and FPT Japan announced discussions about forming a joint venture called COBOL PARK to support financial institutions with legacy-system maintenance and migration options.',
                         '**GnuCOBOL and a Japanese developer**: **Keisuke Nishida**, a Japanese developer, released OpenCOBOL—the predecessor of GnuCOBOL—in 2002. Development now continues under the GNU Project with Simon Sobisch and others. On Debian or Ubuntu, `sudo apt install gnucobol` provides a practical way to compile and run this course’s fixed-format examples on Linux at home, without a mainframe. GnuCOBOL translates COBOL source into C and invokes the system C compiler. It is a useful learning environment, though mainframe dialects, data representations and production behavior may differ.',
                         '**Japanese workplace vocabulary**: common terms include 勘定系 (core accounting systems), 基幹系 (core systems), 日中バッチ / 夜間バッチ (daytime / overnight batch), 突合 (reconciliation), 項目 (field) and 桁 (digit positions). The programs in this course print Japanese business labels, explained in the lessons.'],

             'after': ['So the course is about **being able to read code in production**, not memorising syntax: '
                       'fixed-format column positions, `FILE STATUS` checks, the count invariants of reconciliation, and '
                       'exit codes on failure. That knowledge transfers directly to Japanese sites.',
                       'Start with [Lesson 01](lessons/01_hello-cobol/README.html) and verify it by hand.']},
{'id': 'industries',
                   'title': 'Where it still runs',
                   'kind': 'table',
                   'intro': "COBOL's installed base sits where **volume is high, rules are stable, and one wrong "
                            'entry costs money**. Replacing those systems is expensive, so they keep running.',
                   'head': ['Industry', 'Typical use'],
                   'rows': [('Banking and finance',
                             'Accounts and ledgers, end-of-day batch, reconciliation, clearing, interest and '
                             'fees'),
                            ('Insurance', 'Policies, claims, premium calculation and batch settlement'),
                            ('Retail and distribution', 'Inventory, settlement, supply-chain batch'),
                            ('Airline and travel', 'Reservation and fare systems that run for decades'),
                            ('Healthcare and utilities', 'Claims and billing batch processing'),
                            ('Government', 'Tax, benefits and social-security transaction systems')],
                   'after': ['The platforms are just as broad: z/OS, z/VSE, VME, Unix, NonStop OS, OpenVMS, '
                             'Windows and more.']},
                  {'id': 'legacy',
                   'title': 'Why it has not been replaced',
                   'kind': 'prose',
                   'body': ['People ask why such an old language is not simply rewritten. The answer is not '
                            'laziness: **rewriting carries more risk than maintaining**. These numbers show the '
                            'size of the estate:'],
                   'bullets': ["Gartner Group's 1997 estimate: about **200 billion lines** of COBOL worldwide, "
                               'carrying **80%** of business programs. The figure is widely quoted and should be '
                               'read with care — its methodology has always been disputed — but the order of '
                               'magnitude is not.',
                               'Around 2020: **95%** of credit and debit card swipes are processed by COBOL on '
                               'the back end. Every card you tap almost certainly touches it.',
                               'Computerworld surveys in 2006 and 2012: over **60%** of organisations still used '
                               'COBOL, about half of them for most of their internal software.',
                               'A 2016 US House Committee on Oversight and Government Reform hearing recorded '
                               'COBOL still in use at the Departments of Agriculture, Homeland Security, Health '
                               'and Human Services, Justice, Treasury, Veterans Affairs and the IRS.'],
                   'after': ['**Y2K** was the last time the public noticed. Why COBOL specifically? Business '
                             'systems keyed on dates and stored fixed-length fields, so every two-digit year had '
                             'to be changed. One study attributed up to **24%** of Y2K remediation cost to '
                             'COBOL. And after the cleanup, a 2003 survey found most of those programs still in '
                             'service — repaired and kept, not replaced.',
                             '**The skills gap** is the more practical problem now: by 2019 COBOL programmers '
                             'were retiring faster than they could be replaced, while rewriting carried high '
                             "cost and risk — several banks' multi-year migrations caused outages and fines. "
                             'During COVID-19, unemployment-benefit systems in several US states ran short of '
                             'COBOL programmers, and it made the news.',
                             'So the value of this course is not novelty. It is being able to **read and safely '
                             'change batch programs that have run in production for decades**, and to maintain '
                             'them with modern tools: compiler diagnostics, structural navigation, tests.']},
                  {'id': 'shape',
                   'title': 'What it looks like',
                   'kind': 'code',
                   'intro': 'A minimal runnable fixed-format program. The first seven columns stay blank; the '
                            'body starts in column 8 — Lesson 01 has a column map that explains exactly why:',
                   'code': '       IDENTIFICATION DIVISION.\n'
                           '       PROGRAM-ID. HELLO.\n'
                           '       DATA DIVISION.\n'
                           '       WORKING-STORAGE SECTION.\n'
                           '       01 WS-NAME PIC X(10) VALUE "COBOL".\n'
                           '       PROCEDURE DIVISION.\n'
                           '           DISPLAY "HELLO, " WS-NAME.\n'
                           '           STOP RUN.',
                   'after': ['Each Division has one job: `IDENTIFICATION` identifies the program, `DATA` '
                             'describes the data, `PROCEDURE` holds the steps. `01` defines a record or field, '
                             'and `PIC X(10)` means ten character positions.',
                             'To run something, start with [Lesson 01](lessons/01_hello-cobol/README.html); for '
                             'statement and field rules use the [reference sheet](reference.html). For the '
                             "standard's evolution in detail, see the [COBOL history](history.html)."]}]},
    "ja": {'eyebrow': 'BACKGROUND',
     'title': 'COBOL とは',
     'lead': 'COBOL は**業務データ処理**のために作られた言語です。レコード、ファイル、バッチ全体を英語に近い文で記述し、何十年も保守されることを前提に書きます。1959 '
             '年に米国防総省が主導し、メーカーと政府機関が共同で設計しました。60 余年たった今も、銀行・保険・行政の夜間バッチの多くは COBOL '
             'で書かれています。ここでは、なぜ今の形になったのか、そして現在の GnuCOBOL がどこから来たのかを順に説明します。',
     'source_note': '本ページの史実は COBOL の公開された歴史資料、ISO 標準番号、および GnuCOBOL ソースツリーの AUTHORS / THANKS / ChangeLog '
                    'に基づきます。',
     'sections': [{'id': 'what',
                   'title': 'どんな言語か',
                   'kind': 'prose',
                   'body': ['COBOL は **Common Business-Oriented Language** の略です。名前がそのまま目的を示しています。科学技術計算でも OS '
                            'でもなく、業務データを扱う言語です。',
                            '現代の言語と見た目が違う理由を知るには、まず想定された仕事を見る必要があります。**毎晩、何万件もの取引レコードを 1 '
                            '件ずつ会計処理に通す**。難しいのは計算ではなく、量が膨大で、規則が何十年も変わらず、1 '
                            '件の誤りがそのまま金額の誤りになることです。だから設計は「安定」と「読めること」を優先します：'],
                   'bullets': ['**データ定義と手続きを分ける**：レコードの幅と各項目の桁数を一箇所で宣言し、別の場所に処理を書く。この分離が移植性を生みました。当時は機械ごとにデータ表現が違ったからです。',
                               "**英語のように読める**：`ADD 1 TO WS-COUNT`、`IF WS-STATUS = 'A'`。冗長なのは意図的で、業務担当者が読め、20 "
                               '年後に引き継ぐ人が推測しなくて済むようにするためです。',
                               '**固定長レコード、順次ファイル、ソートと突合が主戦場**：本コースの例はすべてこのモデルに乗っています。',
                               '**コンパイル型**：ソースは `cobc` でネイティブな実行ファイルになります。スクリプトではありません。'],
                   'after': ['一行でいえば、COBOL は業務規則を英語に近い固定形式テキストで書き、コンパイラがそれをメインフレームや Linux '
                             'で何十年も動くバッチプログラムに変えます。']},
                  {'id': 'origin',
                   'title': '成り立ち：押し付けられた協同作業',
                   'kind': 'timeline',
                   'intro': 'COBOL は誰かが一夜で作ったものではありません。**米政府が互換性のない計算機を買いすぎて、プログラムが持ち運べなくなった**という具体的な問題から生まれました。',
                   'items': [('1959-04-08',
                              '発案',
                              'Burroughs の計算機科学者 **Mary K. Hawes** '
                              'がペンシルベニア大学で学界・利用者・メーカーの代表を集め、「共通の業務言語は必要か」を議題にしました。参加者には Grace Hopper、Jean '
                              'Sammet、Saul Gorn がいました。'),
                             ('1959-05-28',
                              '国防総省が動く',
                              '1 か月後、米国防総省の資金でペンタゴンに 41 人が集まり、Charles A. Phillips が議長を務めました。**なぜ急いだのか**：当時すでに '
                              '225 台の計算機を運用し、さらに 175 '
                              '台を発注中で、機種はばらばらでした。機種を変えるたびにソフトを書き直すため、調達と移行の費用が膨らんでいたのです。共通言語はそのままコスト削減でした。'),
                             ('1959-06-04',
                              '組織づくり',
                              ' steering committee はこの活動を **CODASYL**（Committee on Data Systems '
                              'Languages）と名づけ、実行委員会を設置。短期委員会には 3 か月で暫定仕様を出す期限が課され、それが COBOL 60 の原型になりました。'),
                             ('1960-04',
                              'COBOL 60 の登場',
                              '最初の仕様が CODASYL に提出されました。主に 3 つの言語の経験を取り入れています。Grace Hopper の '
                              '**FLOW-MATIC**（長い名前、英語の動詞、データと命令の分離 — COBOL の中心的な特徴はここから来ています）、IBM の '
                              '**COMTRAN**、そして AIMACO です。'),
                             ('1963',
                              '文法の整理',
                              'COBOL 60 には曖昧さが見つかり、委員会が体系的に整理しました。1963 年までに文法の定義可能度は ALGOL '
                              'と同程度になっています。初期のコンパイラは非常に遅く、1962 年の米海軍による評価では**毎分 3〜11 '
                              '文**でした。数百行のプログラムのコンパイルに十数分かかった計算です。'),
                             ('1968-08',
                              '国家標準に',
                              'ANSI が USA Standard COBOL X3.23（ANS COBOL）を発行し、以降の版の基礎になりました。ISO は 1972 '
                              '年に採用しています。これ以降 COBOL は特定ベンダーの方言ではなく、正式な標準に従う言語になりました。'),
                             ('1974',
                              'COBOL-74',
                              'ANSI が改訂版を発行。CODASYL は 1968〜1973 '
                              '年にプログラム間通信、デバッグ、ファイル併合、文字列処理、ライブラリ導入などを追加していました。'),
                             ('1985',
                              'COBOL-85：最大の論争',
                              'この改訂は大きな波紋を呼びました。草案は COBOL-74 と**上方互換がなく**、保険会社の 4,000 '
                              '万行のコードベースが移行を迫られ、「非生産的」と評されました。最初の公開レビューには 2,200 件の意見が寄せられ、うち **1,700 '
                              '件が反対**でした。それでも標準は進み、「既存コードを壊さない」が COBOL 進化の第一原則になりました。'),
                             ('2002',
                              'オブジェクト指向',
                              'ISO が COBOL 2002 を発行。オブジェクト指向、自由形式ソース、ユーザー定義関数、再帰、ロケール、拡張文字集合が入りました。多くは CODASYL の '
                              '1978 年の開発誌ですでに提案されていたもので、COBOL-85 に間に合わなかっただけでした。'),
                             ('2014',
                              'COBOL 2014',
                              '一部の機能を任意化し（VALIDATE、帳票作成、画面処理）、IEEE 754 データ型とメソッドの多重定義を追加しました。'),
                             ('2023',
                              'COBOL 2023',
                              '最新標準。非同期メッセージ（`SEND`/`RECEIVE`）、トランザクション処理（`COMMIT`/`ROLLBACK`）、`XOR`、`PERFORM '
                              'UNTIL EXIT`、`SUBSTITUTE`、`CONVERT` など。GCC 15.1 付属の `gcobol` はこの標準に基づきます。')],
                   'after': ['現在の標準番号は **ISO/IEC 1989:2023**。64 年で十数版、一貫しているのは**既存コードを壊さずに能力を増やす**こと。1980 年代の '
                             'COBOL プログラムが今もそのままコンパイルして動く理由がここにあります。']},
                  {'id': 'gnucobol',
                   'title': 'GnuCOBOL はどこから来たか',
                   'kind': 'prose',
                   'body': ['ここまでは**言語標準**の話です。標準は紙の上の仕様で、`.cob` '
                            'を動くプログラムにするには**コンパイラ**が要ります。以前は商用製品で高価なメインフレームに載るものばかりで、個人や小さなチームには手が届きませんでした。その壁を壊したのが '
                            'GnuCOBOL です。',
                            '道のりはやや込み入っています：'],
                   'bullets': ['**2002 年 1 月**、日本の開発者 **西田圭介（Keisuke Nishida）** が **OpenCOBOL** 0.9 を公開しました。C '
                               'で書かれた自由な COBOL コンパイラです。賢いのは、機械語を直接出さず **COBOL を C に変換**し、システムの C コンパイラに渡す方式。C '
                               'コンパイラがある環境ならどこでも COBOL が動きます。',
                               '**2009 年**に OpenCOBOL 1.1 が公開。その後、しばらく保守者が不在の時期がありました。',
                               '**2013 年**に OpenCOBOL は GNU プロジェクトとして受け入れられ、**GnuCOBOL** に改名。2014 年 1 月に '
                               'GnuCOBOL 1.1 が出ました。改名と同時にコミュニティが長期保守を引き受け、特に **Roger While**（1950–2015）とドイツの '
                               '**Simon Sobisch** が大きく貢献しています。',
                               '**現在**、GnuCOBOL の THANKS ファイルには **Keisuke Nishida**（原作者）、**Roger While**（2015 '
                               '年没）、**Simon Sobisch** が過去および現行の保守者として挙げられています。開発は GNU と SourceForge 上で続き、安定版は '
                               '3.2（2023 年 7 月）、4.0 が開発中です。'],
                   'after': ['**なぜ重要か**：GnuCOBOL は COBOL を「大組織だけのもの」から「`apt install gnucobol` '
                             'で学べるもの」に変えました。COBOL 85・2002・2014 の大部分を実装し、JD Edwards、Micro Focus、IBM などの拡張方言も扱えます。',
                             'Debian/Ubuntu なら `sudo apt install gnucobol` で導入でき、自宅の Linux で本コースの固定形式コードをコンパイル・実行できます。COBOL ソースを C に変換してシステムの C コンパイラーに渡す方式なので、メインフレームは不要です。ただし、メインフレームの方言・データ表現・本番環境での動作がすべて同じになるわけではありません。',
                             '本コースが使っているのもこれです。[第 01 課](lessons/01_hello-cobol/README.html)で最初に打つ `cobc` は '
                             'GnuCOBOL です。']},

                  {'id': 'japan',
             'title': '日本では今も現役です',
             'kind': 'prose',
             'body': ['ここが、このコースを日本語で読む意味です。COBOL は「海外の古い話」ではなく、**日本の基幹系システムの現役の言語**です。',
                      'メガバンク、地方銀行、信用金庫、保険、クレジットカード、証券、そして自治体の住民記録や年金。こうした「止まってはいけない」システムの多くが、いまも COBOL '
                      'のバッチで動いています。理由は単純で、**動いているものを止めずに作り直すほうが難しい**からです。'],
             'bullets': ['**国内ベンダーの COBOL と移行**：富士通の NetCOBOL など、メインフレームからオープン環境へ移して COBOL 資産を活かす選択肢があります。2025 年 1 月、高知信用金庫は勘定系をメインフレームから NetCOBOL へ移行すると発表し、2030 年 1 月の完了を目指しています。',
                         '**「2025 年の崖」と人材不足**：経済産業省が指摘したレガシーシステムの課題には、保守・移行を担う人材不足も含まれます。2024 年 10 月、SCSK と FPT ジャパンは、金融機関などのシステム保守・移行を支援する合弁会社「COBOL PARK」の設立に向けた協議開始を発表しました。',
                         '**GnuCOBOL と日本人開発者**：GnuCOBOL の前身 OpenCOBOL は、日本の開発者 **西田圭介（Keisuke Nishida）** 氏が 2002 年に公開しました。現在は GNU プロジェクトの下で Simon Sobisch 氏らが開発を続けています。Debian/Ubuntu なら `sudo apt install gnucobol` で導入でき、自宅の Linux で本コースの固定形式コードをコンパイル・実行できます。COBOL ソースを C に変換してシステムの C コンパイラーでビルドするため、学習にメインフレームは必要ありません。ただし、メインフレームの方言・データ表現・本番環境での動作がすべて同じになるわけではありません。',
                         '**日本の現場用語**：「勘定系」「基幹系」「日中バッチ」「夜間バッチ」「突合（とつごう）」「項目」「桁」などが使われます。本コースの実行結果も日本語の業務ラベルで表示し、講義で意味を説明します。'],

             'after': ['だから本コースは、文法の暗記ではなく**現場で読めること**を重視しています。固定形式の桁位置、`FILE STATUS` '
                       'の判定、突合の数え上げ、異常時の終了コード。これらは日本語の現場でもそのまま通用する知識です。',
                       '[第 01 課](lessons/01_hello-cobol/README.html)から、実際に手を動かして確かめてください。']},
{'id': 'industries',
                   'title': '今どこで動いているか',
                   'kind': 'table',
                   'intro': 'COBOL の既存資産は**取引量が多く、規則が安定し、1 件の誤りが金額になる**領域に集中しています。置き換えの費用が高いため、動き続けています。',
                   'head': ['業界', '代表的な用途'],
                   'rows': [('銀行・金融', '口座と元帳、日次バッチ、照合、決済、利息と手数料'),
                            ('保険', '契約、請求、保険料計算、バッチ決済'),
                            ('小売・流通', '在庫、決済、サプライチェーンのバッチ'),
                            ('航空・旅行', '予約・運賃など長期運用の基幹システム'),
                            ('医療・公益', '請求や料金のバッチ処理'),
                            ('政府機関', '税務、給付、社会保障などの大規模処理')],
                   'after': ['実行環境も広範です：z/OS、z/VSE、VME、Unix、NonStop OS、OpenVMS、Windows など。']},
                  {'id': 'legacy',
                   'title': 'なぜ置き換えられないのか',
                   'kind': 'prose',
                   'body': ['これほど古い言語をなぜ書き直さないのか。答えは怠慢ではなく、**書き直しのほうが保守より危険**だからです。規模を示す数字を挙げます：'],
                   'bullets': ['1997 年の Gartner Group の推計：世界に約 **2,000 億行**の COBOL があり、業務プログラムの **80%** '
                               'を担う。広く引用される数字ですが、算出方法には議論があり、桁感として読むべきです。',
                               '2020 年前後：クレジット／デビットカード決済の **95%** がバックエンドで COBOL を通ります。毎日の支払いがほぼ確実に触れている計算です。',
                               '2006 年と 2012 年の Computerworld 調査：**60%** 超の組織が COBOL '
                               'を継続利用し、約半数が社内ソフトの大半に使っていました。',
                               '2016 年の米下院監督政府改革委員会の公聴会記録：農務省、国土安全保障省、保健福祉省、司法省、財務省、退役軍人省、国税庁などが COBOL を現役で使用。'],
                   'after': ['**2000 年問題（Y2K）**は COBOL が最後に世間の注目を浴びた出来事です。なぜ COBOL だったのか。業務システムが日付をキーにし、固定長項目に 2 '
                             '桁の年を保存していたからです。Y2K 対応費用の最大 **24%** が COBOL 由来とする研究もあります。対応後、2003 '
                             '年の調査ではそれらのプログラムの多くが現役のままでした。直して使い続けたのであり、書き直したのではありません。',
                             '**人材不足**が今はより現実的な問題です。2019 年までに COBOL '
                             '技術者は引退で急速に減り、書き直しは費用もリスクも大きいままでした。複数年の移行計画がサービス障害と制裁金につながった銀行もあります。COVID-19 '
                             'の際には米国複数州の失業給付システムで COBOL 技術者不足が報じられました。',
                             'したがって本コースの価値は新しさではなく、**何十年も本番で動いてきたバッチプログラムを読み、安全に変更できる**ようになること、そしてコンパイラ診断・構造ナビゲーション・テストといった現代の道具で保守できるようになることです。']},
                  {'id': 'shape',
                   'title': '実際のコード',
                   'kind': 'code',
                   'intro': '最小の実行可能な固定形式プログラムです。先頭 7 列は空け、8 列目から本文を書きます。理由は第 01 課の列レイアウト図で説明しています：',
                   'code': '       IDENTIFICATION DIVISION.\n'
                           '       PROGRAM-ID. HELLO.\n'
                           '       DATA DIVISION.\n'
                           '       WORKING-STORAGE SECTION.\n'
                           '       01 WS-NAME PIC X(10) VALUE "COBOL".\n'
                           '       PROCEDURE DIVISION.\n'
                           '           DISPLAY "HELLO, " WS-NAME.\n'
                           '           STOP RUN.',
                   'after': ['各 Division の役割は 1 つずつです。`IDENTIFICATION` はプログラムの身元、`DATA` はデータの記述、`PROCEDURE` '
                             'は実行手順。`01` はレコードや項目の定義、`PIC X(10)` は 10 文字分を意味します。',
                             '実際に動かすなら[第 01 '
                             '課](lessons/01_hello-cobol/README.html)から。文と項目の規則は[リファレンス](reference.html)、標準の変遷の詳細は[COBOL '
                             '小史](history.html)を見てください。']}]},

}
