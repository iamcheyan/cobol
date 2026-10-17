"""Content for the knowledge pages: COBOL history and a terminology glossary.

Facts on the history page follow COBOL's published historical record (the
Wikipedia "COBOL" article's history, reception and influence sections, which
cite the original sources). Glossary entries were checked against the GnuCOBOL
3.2 compiler in this repository where behaviour could be observed, and against
the official GnuCOBOL Quick Reference for syntax. Nothing here is invented.
"""

HISTORY = {
    "zh-cn": {'eyebrow': 'HISTORY',
     'title': 'COBOL 史话',
     'lead': '标准不是凭空写出来的。COBOL '
             '的诞生过程更像一场拉锯战：一群人被政府召集起来，在“用谁的语言当基础”上吵得不可开交，被逼着三个月交草稿；有人气到买了一块刻着「COBOL」的墓碑寄给项目负责人。下面按时间把这件事从头讲一遍。',
     'note': '本页史实依据 COBOL 的公开历史资料整理，含具体人物、数字与争议记录。',
     'sections': [{'id': 'why',
                   'title': '1959 年之前：程序比机器还贵',
                   'kind': 'prose',
                   'body': ['要理解 COBOL 为什么会长成那样，得先知道 1950 年代末的计算机行业卡在什么地方。',
                            '那时候**写程序的成本已经超过买机器的成本**。1959 年的一次调查记录：任何一个数据处理部门，程序开发的平均花费是 **80 '
                            '万美元**；而把这套程序迁移到新买的机器上，还要再花 **60 万美元**。也就是说，换机器的真实代价里，有一大半是重写代码。',
                            '最难受的是美国国防部：他们当时运行着 225 台计算机，另有一批在订购，已经在程序实现上投入超过 **2 '
                            '亿美元**。型号各不相同，每台机器都有一套自己的汇编语言。**只要程序不能跨机器搬，每次采购新机器就等于把软件资产再买一遍。**',
                            '于是目标被定得很清楚：造一门**可移植**的语言——程序写一次，换个厂商的机器还能跑；顺便让不懂机器的人（业务人员）也读得懂，让新人能上手。'],
                   'after': ['记住这个起点。COBOL 后来被批评的每一个“缺点”——啰嗦、保留字太多、语法庞杂——几乎都是为了这个目标付的代价。']},
                  {'id': 'people',
                   'title': '1959 年 4 月：一场会议，和一群具体的人',
                   'kind': 'prose',
                   'body': ['故事从 **1959 年 4 月 8 日**开始。Burroughs 的计算机科学家 **Mary K. Hawes** '
                            '在宾夕法尼亚大学召集了一次会议，把学界、用户和厂商代表放在同一张桌子前，议题只有一个：**要不要搞一门通用的商业语言？**',
                            '这次会议之所以重要，是因为它凑齐了后来真正干活的人：'],
                   'bullets': ['**Grace Hopper**：FLOW-MATIC 的发明者。她带来的三个想法直接定义了 COBOL '
                               '的样子——**长变量名、英语式的命令词、把数据描述和执行指令分开**。她常被称作「COBOL 之母」，但这个说法在当事人之间是有争议的。',
                               '**Jean E. Sammet**：COBOL 的主要设计者之一，六人起草小组成员。她明确说过 Hopper「不是 COBOL '
                               '的母亲、创造者或开发者」；她晚年还指出，委员会最大的失误是**没有做参数传递**。',
                               '**Betty Holberton**：短期委员会成员。她把「三个月交出规范」形容为「**极度乐观**」，并怀疑这东西真能只是一个过渡方案。',
                               '**Bob Bemer**（IBM，COMTRAN 的作者）与 **Roy Nutt**（FACT 的作者）也在场——他们后来分别代表了两条技术路线的竞争。'],
                   'after': ['真正执笔起草的是**六人小组**：IBM 的 William Selden 与 Gertrude Tierney，RCA 的 Howard Bromberg 与 '
                             'Howard Discount，Sylvania 的 Vernon Reeves 与 Jean E. Sammet。也就是说，COBOL '
                             '最初的规范文本出自两个女性工程师和四位同事之手——在那个年代，这并不常见。']},
                  {'id': 'fact',
                   'title': '1959 年 6–10 月：三个月死线，和那块墓碑',
                   'kind': 'prose',
                   'body': ['1959 年 6 月 4 日，指导委员会把这项活动命名为 **CODASYL**（Committee on Data Systems '
                            'Languages），并成立执行委员会。短期委员会被要求**三个月内交出临时语言规范**——对要设计一门新语言来说，这个期限近乎荒谬，但它逼出了草稿。',
                            '草稿交上来后评价并不好。委员会主席 **Joseph Wegstein**（美国国家标准局，今 NIST）的评价是「仍有粗糙之处，需要补充」；Bob Bemer '
                            '后来更直接，称它是「**大杂烩**」。于是委员会给了更多时间修改。',
                            '真正的转折在 **1959 年 10 月**：中间委员会收到了 Roy Nutt 写的 **FACT** 语言规范，水准明显更高。委员会随即通过决议——**改以 '
                            'FACT 为基础**。这对刚交出成果的短期委员会是一次重击：等于说他们三个月白干了。',
                            '但决议很快被推翻，理由很实际：**FACT 技术上更强，却不是为可移植性设计的，也不是厂商与用户协商的产物，而且没有可演示的实现。** RCA 的 **Howard '
                            'Bromberg** 也从中阻止——RCA 在 COBOL 上的投入不能白费。',
                            '到这里，Bromberg 的挫败感到了顶点。他做了一件后来被反复提起的事：**买了一块刻着「COBOL」的墓碑，寄给国防部负责此事的 Charles A. '
                            'Phillips**，以示抗议。这块墓碑花了 15 美元（约合 2025 年的 170 美元）。'],
                   'after': ['规范最终在 **1960 年 1 月 8 日**获执行委员会批准，由政府印刷局印行——这就是 **COBOL 60**。从第一次会议到规范落地，不到九个月。']},
                  {'id': 'naming',
                   'title': '插曲：名字是怎么定下来的',
                   'kind': 'prose',
                   'body': ['1959 年 9 月的一次会议上，委员会还在为新语言叫什么发愁。候选名单里有一堆今天听起来很陌生的缩写：'],
                   'bullets': ['**BUSY**（Business System）',
                               '**INFOSYL**（Information System Language）',
                               '**COCOSYL**（Common Computer Systems Language）'],
                   'after': ['最后定名为 **COBOL**（Common Business-Oriented Language）。至于究竟是谁先提出这个名字，档案里并不清楚——Bob '
                             'Bemer 晚年声称是他建议的，但已无法证实。']},
                  {'id': 'adoption',
                   'title': '1960 年代：从「过渡方案」变成行业标准',
                   'kind': 'prose',
                   'body': ['有意思的是，COBOL '
                            '一开始只被当作**过渡方案**——先有个统一的东西顶着，等更好的设计出来再换。它之所以没被换掉，是因为**国防部直接向计算机制造商施压，要求他们提供实现**。',
                            '这个压力立刻见效。到 **1960 年 9 月**，又有五家厂商加入 CODASYL（Bendix、Control Data、General '
                            'Electric、National Cash Register、Philco），而已加入的厂商全部宣布了 COBOL 编译器。语言还没成熟，市场先成立了。',
                            '早期编译器又慢又贵，这在当时是公开记录的数字：'],
                   'bullets': ['**1962 年**美国海军的一次评测：编译速度 **每分钟 3–11 条语句**。一条几百行的程序，编译要十几分钟。',
                               '到 **1964 年中**：提升到 **每分钟 11–1000 条语句**。',
                               '**每条语句的编译成本**从 0.23 美元到 18.91 美元不等——内存越大，速度越快，成本越低。'],
                   'after': ['为什么 COBOL 编译器这么难写？因为它语法庞大、可选元素极多，还要在同一门语言里同时支持多种数据表示、隐式类型转换和各式各样的 I/O '
                             '准备。这些都写进了标准，编译器作者只能全部接住。']},
                  {'id': 'standards',
                   'title': '1968–1985：标准化，以及最大的一场冲突',
                   'kind': 'prose',
                   'body': ['各家实现互不兼容，标准化因此被提上日程。**1962 年底**，ISO 与美国标准协会（今 ANSI）分别成立小组；**1968 年 8 月**，ANSI 发布 '
                            '**USA Standard COBOL X3.23**，成为后续各版的基石，ISO 于 1972 年采纳。',
                            '然后是 **COBOL-85**——COBOL 历史上最激烈的一次修订。它几乎演变成一场行业冲突：'],
                   'bullets': ['草案（常被称为 COBOL-80）与 COBOL-74 **不向上兼容**。这意味着存量代码要改。',
                               '**1981 年**，Travelers Insurance 的高级副总裁 **Joseph T. Brophy** 威胁要起诉标准委员会，并把公司 '
                               '**4000 万行**代码库的历次迁移形容为「非生产性」「完全浪费程序员资源」。',
                               '数据管理协会（DPMA）公开表示「强烈反对」，理由是转换成本「高得离谱」。',
                               '第一轮公开评审收到 **2200 份**意见，其中 **1700 份是反对信**；转换成本估计至少**每行代码 50 美分**。支持的回复不到十几份。'],
                   'after': ['标准最终还是推行了。但这场冲突留下了一条铁律，也成了 COBOL 至今的演进原则：**在不破坏既有代码的前提下增加能力**。',
                             '这也解释了一个常被问的问题——为什么一段 1980 年代的 COBOL 程序今天还能原样编译：因为这门语言的每一次修订，都被要求先保证不弄坏它。']},
                  {'id': 'criticism',
                   'title': '1970–1980 年代：被当成靶子',
                   'kind': 'prose',
                   'body': ['结构化编程兴起后，COBOL 成了最方便的批评对象。**1975 年**，Edsger Dijkstra 在《Communications of the '
                            'ACM》上发表读者来信《How do we tell truths that might hurt?》，里面有一句被引用了几十年的话：**「使用 COBOL '
                            '会让头脑残废」**（"the use of COBOL cripples the mind"）。',
                            '也有不同意见。计算机科学家 **Howard E. Tompkins** 反驳说：非结构化的 COBOL 往往出自「从未受过良好结构化 COBOL '
                            '训练的程序员」之手，问题在训练，不在语言。',
                            '把情绪放一边，当时 COBOL 的技术短板确实有据可查，而且相当具体：'],
                   'bullets': ['**`GO TO` 与面条代码**：它确实是 spaghetti code 的一个成因。但后来经验也表明，强行移除 `GO TO` '
                               '反而让程序更绕、质量更差；它最终基本被 `PERFORM` 与过程取代。',
                               '**`PERFORM` 只能作用于过程**：循环体不在使用它的地方，读起来必须来回跳。',
                               '**无法限制数据访问**：直到 COBOL-85 之前，任何过程都能读写任意数据项——这在大系统里是灾难。',
                               '**不能给过程传参数**：Jean Sammet 认为这是委员会最大的失误；直到 COBOL-85 引入嵌套子程序才解决。'],
                   'after': ['`GO TO` 至今仍然保留，理由和很多语言一样：**向后兼容**。删掉它，存量代码就编不过了。']},
                  {'id': 'influence',
                   'title': '它留下的东西',
                   'kind': 'table',
                   'intro': 'COBOL 的很多设计后来被别的语言拿走了。这张表是它的“遗产清单”：',
                   'head': ['COBOL 的东西', '影响了'],
                   'rows': [('记录与文件结构', 'PL/I 与 Pascal'),
                            ('`REDEFINES` 子句', 'Pascal 的变体记录（variant records）'),
                            ('`PICTURE` 数据声明', 'PL/I（略作修改后采用）'),
                            ('`COPY` 设施', '后来的 include 指令')],
                   'after': ['更隐性的影响在**工程观念**上：COBOL 对可移植性与标准化的强调，让程序能跨大量硬件平台运行；它把外部引用限制在 `ENVIRONMENT DIVISION` '
                             '的分部结构，也简化了平台更换。它比数据库管理系统更早地显式定义了文件结构，而「聚合数据」相对 Fortran 的数组是一大进步。',
                             '还有一个常被忽略的事实：COBOL 早期的大量工作由女性程序员完成——Grace Hopper、Jean Sammet、Betty '
                             'Holberton、Gertrude Tierney 都是核心角色。这在 1959 年是非常少见的分工。']},
                  {'id': 'later',
                   'title': '2000 年前后：千年虫，和它为什么砸在 COBOL 上',
                   'kind': 'prose',
                   'body': ['COBOL 最近一次被大众注意到，是 **千年虫（Y2K）**。全世界都在讨论「2000 年会不会让老系统崩溃」，而讨论的焦点几乎总是 COBOL。为什么偏偏是它？',
                            '原因有三个，都跟它的设计直接相关：'],
                   'bullets': ['**商业系统大量用日期做键**——账户流水、保单、账单，几乎每条记录都有日期。',
                               '**数据是定长字段**，为了省存储，年份普遍只存两位（`PIC 99`）。1959 年的存储很贵，没人会为 2000 年预留空间。',
                               '**这些程序运行得太久**，久到当初「省两位」的决定，要由四十年后的人来收拾。'],
                   'after': ['有研究把高达 **24%** 的 Y2K 修复成本归因于 COBOL。而清理完之后，**2003 '
                             '年的一次调查发现这些程序大多仍在服役**——修完继续用，而不是趁机重写。这件事本身就是 COBOL 命运的一个缩影：它总被宣布要死，然后又活过一个十年。']},
                  {'id': 'shape',
                   'title': '语言本身：一些值得知道的数字',
                   'kind': 'table',
                   'intro': '最后补充一组事实，便于建立对这门语言的整体印象。',
                   'head': ['项目', '事实'],
                   'rows': [('保留字', '超过 300 个；部分只是同一词的替代或复数写法，为的是让句子读起来更自然'),
                            ('可互换的关键词', '`IN` 与 `OF`、`TIME` 与 `TIMES`、`VALUE` 与 `VALUES` 可以互换使用'),
                            ('标准规定的规模', '43 条语句、87 个函数、1 个类（缺少大型标准库）'),
                            ('标识符长度', '最多 31 个字符，可含字母、数字、连字符和下划线'),
                            ('四种词法单位', '词（words）、字面量（literals）、PICTURE 字符串、分隔符（separators）'),
                            ('分部结构', '四个 DIVISION：IDENTIFICATION、ENVIRONMENT、DATA、PROCEDURE'),
                            ('层级', '每个 DIVISION 下分 SECTION，SECTION 下分 PARAGRAPH'),
                            ('格式', '固定格式（默认）与自由格式；COBOL 2002 起把 Area A 与 B 合并为程序文本区，并引入自由格式')]}]},
    "en": {'eyebrow': 'HISTORY',
     'title': 'A short history of COBOL',
     'lead': "Standards are not written in the abstract. COBOL's birth was closer to a tug of war: a group "
             'convened by the government, arguing over whose language should be the basis, pushed to deliver a '
             "draft in three months — and at one point someone was angry enough to mail the project's sponsor a "
             'tombstone engraved "COBOL". Here it is in order.',
     'note': "The facts here follow COBOL's published historical record, including named people, figures and "
             'documented disputes.',
     'sections': [{'id': 'why',
                   'title': 'Before 1959: software cost more than the hardware',
                   'kind': 'prose',
                   'body': ['To see why COBOL looks the way it does, start with what the computer industry was '
                            'stuck on at the end of the 1950s.',
                            '**Writing software had become more expensive than buying the machine.** A 1959 '
                            'survey recorded that the average data-processing department spent **$800,000** on '
                            'program development, and another **$600,000** moving that software onto new '
                            'hardware. Most of the real cost of changing machines was rewriting the code.',
                            'The US Department of Defense felt it worst: it ran 225 computers, had more on '
                            'order, and had already spent over **$200 million** on program implementation. Every '
                            'model had its own assembly language. **As long as programs could not move between '
                            'machines, every new purchase meant buying the software again.**',
                            'So the goal was set plainly: a **portable** language — write once, run on another '
                            "vendor's machine — that business staff could also read and newcomers could pick "
                            'up.'],
                   'after': ['Hold on to that starting point. Nearly every COBOL trait later criticised — '
                             'verbosity, too many reserved words, a sprawling grammar — was the price paid for '
                             'that goal.']},
                  {'id': 'people',
                   'title': 'April 1959: one meeting, and a room of specific people',
                   'kind': 'prose',
                   'body': ['The story starts on **8 April 1959**. **Mary K. Hawes**, a computer scientist at '
                            'Burroughs, convened academics, users and manufacturers at the University of '
                            'Pennsylvania with a single question: **do we need a common business language?**',
                            'That meeting matters because it put the people who would actually do the work in '
                            'one room:'],
                   'bullets': ["**Grace Hopper**: inventor of FLOW-MATIC, whose three ideas defined COBOL's "
                               'shape — **long variable names, English command words, and data descriptions '
                               'separated from instructions**. She is often called the "mother of COBOL", a '
                               'claim disputed among the participants themselves.',
                               "**Jean E. Sammet**: one of COBOL's lead designers and a member of the six-person "
                               'drafting group. She stated plainly that Hopper "was not the mother, creator, or '
                               'developer of COBOL", and later named the absence of parameter passing as the '
                               "committee's biggest mistake.",
                               '**Betty Holberton**: a short-range committee member who called the three-month '
                               'specification deadline "**gross optimism**" and doubted the language would stay '
                               'a stopgap.',
                               '**Bob Bemer** (IBM, author of COMTRAN) and **Roy Nutt** (author of FACT) were '
                               'there too — they came to represent the two competing technical routes.'],
                   'after': ['The actual drafting was done by a **six-person group**: William Selden and '
                             'Gertrude Tierney of IBM, Howard Bromberg and Howard Discount of RCA, and Vernon '
                             'Reeves and Jean E. Sammet of Sylvania. The first COBOL specification was therefore '
                             'written by two women engineers and four colleagues — unusual for 1959.']},
                  {'id': 'fact',
                   'title': 'June–October 1959: a three-month deadline and a tombstone',
                   'kind': 'prose',
                   'body': ['On **4 June 1959** the steering committee named the effort **CODASYL** (Committee '
                            'on Data Systems Languages) and formed an executive committee. The short-range '
                            'committee was given **three months to produce an interim specification** — an '
                            'almost absurd deadline for designing a language, but it forced a draft into '
                            'existence.',
                            'The draft was not well received. Committee chair **Joseph Wegstein** (US National '
                            'Bureau of Standards, now NIST) judged that it "contains rough spots and requires '
                            'some additions"; Bob Bemer was blunter later, calling it a "**hodgepodge**". The '
                            'committee granted more time.',
                            'The real turning point came in **October 1959**: the intermediate committee '
                            "received Roy Nutt's **FACT** specification, which was clearly better engineered. "
                            'The committee promptly resolved to **rebuild COBOL on FACT** — a blow to the '
                            'short-range committee, whose three months of work now looked wasted.',
                            'The resolution was overturned, for practical reasons: **FACT was technically '
                            'stronger but not designed for portability, was not a negotiated product of vendors '
                            "and users, and had no demonstrable implementation.** RCA's **Howard Bromberg** also "
                            "blocked it — RCA's investment in COBOL could not be written off.",
                            "By then Bromberg's frustration had peaked, and he did the thing that gets retold: "
                            '**he bought a tombstone engraved "COBOL" and mailed it to Charles A. Phillips at '
                            'the DoD** in protest. It cost $15, about $170 in 2025 money.'],
                   'after': ['The specification was approved by the executive committee on **8 January 1960** '
                             'and printed by the Government Printing Office — that is **COBOL 60**. Less than '
                             'nine months from first meeting to published specification.']},
                  {'id': 'naming',
                   'title': 'Interlude: how it got its name',
                   'kind': 'prose',
                   'body': ['At a September 1959 meeting the committee was still stuck on what to call the '
                            'language. The shortlist was full of acronyms that sound strange today:'],
                   'bullets': ['**BUSY** (Business System)',
                               '**INFOSYL** (Information System Language)',
                               '**COCOSYL** (Common Computer Systems Language)'],
                   'after': ['It ended up as **COBOL** (Common Business-Oriented Language). Who first proposed '
                             'the name is not clear from the record — Bob Bemer claimed late in life that it was '
                             'his, but it cannot be confirmed.']},
                  {'id': 'adoption',
                   'title': 'The 1960s: from stopgap to industry standard',
                   'kind': 'prose',
                   'body': ['Oddly, COBOL began as an intended **stopgap** — something common to hold the line '
                            'until a better design arrived. What stopped it being replaced was that **the DoD '
                            'leaned on computer manufacturers to ship implementations**.',
                            'The pressure worked immediately. By **September 1960** five more manufacturers '
                            'joined CODASYL (Bendix, Control Data, General Electric, National Cash Register, '
                            'Philco), and every member had announced a COBOL compiler. The market arrived before '
                            'the language matured.',
                            'Early compilers were slow and expensive, and this was publicly recorded:'],
                   'bullets': ['A **1962** US Navy evaluation measured **3–11 statements per minute** — a few '
                               'hundred lines took a quarter of an hour to compile.',
                               'By **mid-1964** this had risen to **11–1,000 statements per minute**.',
                               '**Compilation cost per statement** ranged from $0.23 to $18.91 — more memory '
                               'meant more speed and lower cost.'],
                   'after': ['Why were COBOL compilers so hard to write? A large grammar, many optional '
                             'elements, and one language that had to support several data representations, '
                             'implicit conversions and every kind of I/O preparation. All of it was in the '
                             'standard, so compiler authors had to absorb all of it.']},
                  {'id': 'standards',
                   'title': '1968–1985: standardisation, and the biggest fight',
                   'kind': 'prose',
                   'body': ['Mutually incompatible implementations pushed standardisation forward. At the **end '
                            'of 1962**, ISO and the US standards body (now ANSI) each formed groups; in **August '
                            '1968** ANSI published **USA Standard COBOL X3.23**, the basis for later editions, '
                            'adopted by ISO in 1972.',
                            "Then came **COBOL-85** — the most heated revision in COBOL's history, which nearly "
                            'became an industry confrontation:'],
                   'bullets': ['The draft (often called COBOL-80) was **not upward compatible** with COBOL-74. '
                               'Existing code would have to change.',
                               'In **1981**, **Joseph T. Brophy**, a senior vice president at Travelers '
                               'Insurance, threatened to sue the standards committee and described migrating the '
                               'company\'s **40 million lines** as "unproductive" and "a total waste of '
                               'programmer resources".',
                               'The Data Processing Management Association (DPMA) said it was "strongly '
                               'opposed", because conversion costs were "unreasonably high".',
                               'The first public review drew **2,200 comments, 1,700 of them objections**; '
                               'conversion was estimated at **at least $0.50 per line**. Fewer than a dozen '
                               'replies supported it.'],
                   'after': ['The standard went ahead anyway. But the fight left a rule that still governs '
                             'COBOL: **add capability without breaking existing code.**',
                             'It also answers a question people keep asking — why a 1980s COBOL program still '
                             'compiles unchanged today: because every revision was required, first of all, not '
                             'to break it.']},
                  {'id': 'criticism',
                   'title': 'The 1970s–80s: becoming the target',
                   'kind': 'prose',
                   'body': ['When structured programming arrived, COBOL became the easiest thing to attack. In '
                            '**1975**, Edsger Dijkstra published a letter in *Communications of the ACM* titled '
                            '*How do we tell truths that might hurt?*, containing a line quoted for decades: '
                            '**"the use of COBOL cripples the mind"**.',
                            'Others disagreed. The computer scientist **Howard E. Tompkins** argued that '
                            'unstructured COBOL usually came from "programmers who have never been properly '
                            'trained in structured COBOL", so the problem was training, not the language.',
                            'Setting rhetoric aside, the technical shortfalls of the time were real and '
                            'specific:'],
                   'bullets': ['**`GO TO` and spaghetti code**: it was one cause of tangled programs. Experience '
                               'later showed that forcibly removing `GO TO` made programs more convoluted and '
                               'lower quality; it was ultimately displaced by `PERFORM` and procedures.',
                               '**`PERFORM` could only target a procedure**: the loop body lived elsewhere, so '
                               'reading meant jumping back and forth.',
                               '**No way to restrict data access**: before COBOL-85 any procedure could read or '
                               'write any data item — disastrous in a large system.',
                               '**No parameter passing to procedures**: Jean Sammet considered this the '
                               "committee's biggest mistake; COBOL-85's nested subprograms finally fixed it."],
                   'after': ['`GO TO` is still in the language for the same reason many languages keep old '
                             'features: **backward compatibility**. Remove it and existing code stops '
                             'compiling.']},
                  {'id': 'influence',
                   'title': 'What it left behind',
                   'kind': 'table',
                   'intro': "Much of COBOL's design was later taken up by other languages. This is the "
                            'inheritance list:',
                   'head': ['From COBOL', 'Influenced'],
                   'rows': [('Record and file structures', 'PL/I and Pascal'),
                            ('The `REDEFINES` clause', "Pascal's variant records"),
                            ('`PICTURE` data declarations', 'PL/I (adopted with small changes)'),
                            ('The `COPY` facility', 'Later include directives')],
                   'after': ["The quieter influence is in engineering practice: COBOL's insistence on "
                             'portability and standardisation let programs move across a wide range of hardware, '
                             'and confining external references to `ENVIRONMENT DIVISION` made platform changes '
                             'simpler. It defined file structures explicitly before database management systems '
                             'existed, and "aggregate data" was a real step beyond Fortran\'s arrays.',
                             'One more fact that gets overlooked: a great deal of the early COBOL work was done '
                             'by women — Grace Hopper, Jean Sammet, Betty Holberton and Gertrude Tierney were '
                             'all central. That division of labour was very unusual for 1959.']},
                  {'id': 'later',
                   'title': 'Around 2000: Y2K, and why it landed on COBOL',
                   'kind': 'prose',
                   'body': ['The last time the general public noticed COBOL was **Y2K**. The world debated '
                            'whether old systems would break in the year 2000, and the discussion kept coming '
                            'back to COBOL. Why COBOL specifically? Three reasons, all rooted in its design:'],
                   'bullets': ['**Business systems key on dates** — account movements, policies, invoices, '
                               'almost every record carries one.',
                               '**Data lives in fixed-length fields**, and to save storage the year was usually '
                               'stored as two digits (`PIC 99`). Storage was expensive in 1959; nobody reserved '
                               'room for the year 2000.',
                               '**These programs ran for so long** that a decision to save two digits had to be '
                               'paid for by people forty years later.'],
                   'after': ['One study attributed up to **24%** of Y2K remediation cost to COBOL. And once the '
                             'cleanup finished, **a 2003 survey found most of those programs still in service** '
                             "— repaired and kept, not replaced. That is COBOL's fate in miniature: pronounced "
                             'dead, then surviving another decade.']},
                  {'id': 'shape',
                   'title': 'The language itself: a few facts worth knowing',
                   'kind': 'table',
                   'intro': "A final set of facts, to give a sense of the language's shape.",
                   'head': ['Item', 'Fact'],
                   'rows': [('Reserved words',
                             'Over 300; some are only alternative or plural forms so sentences read more '
                             'naturally'),
                            ('Interchangeable keywords',
                             '`IN` and `OF`, `TIME` and `TIMES`, `VALUE` and `VALUES` can be used '
                             'interchangeably'),
                            ('Size defined by the standard',
                             '43 statements, 87 functions, 1 class (no large standard library)'),
                            ('Identifier length',
                             'Up to 31 characters, using letters, digits, hyphens and underscores'),
                            ('Four lexical units', 'Words, literals, PICTURE strings and separators'),
                            ('Division structure',
                             'Four DIVISIONs: IDENTIFICATION, ENVIRONMENT, DATA, PROCEDURE'),
                            ('Hierarchy', 'Each DIVISION contains SECTIONs; each SECTION contains PARAGRAPHs'),
                            ('Format',
                             'Fixed format (the default) and free format; COBOL 2002 merged Areas A and B into a '
                             'program-text area and introduced free format')]}]},
    "ja": {'eyebrow': 'HISTORY',
     'title': 'COBOL 小史',
     'lead': '標準は机の上で書かれるものではありません。COBOL の誕生はむしろ綱引きに近く、政府が集めた人々が「どの言語を土台にするか」で激しく争い、3 '
             'か月で草案を出すよう迫られ、ある人物は腹の虫が治まらず「COBOL」と刻んだ墓石をスポンサーに送りつけました。以下、順を追って説明します。',
     'note': '本ページの史実は COBOL の公開された歴史資料に基づき、人物名・数値・記録された論争を含みます。',
     'sections': [{'id': 'why',
                   'title': '1959 年以前：ソフトがハードより高くついた',
                   'kind': 'prose',
                   'body': ['COBOL がなぜあの形なのかを知るには、1950 年代末に業界が何で詰まっていたかを見る必要があります。',
                            '**プログラムを書く費用が、機械を買う費用を上回っていました。** 1959 年の調査では、データ処理部門がプログラム開発に平均 **80 '
                            '万ドル**、そのソフトを新しいハードへ移すのにさらに **60 万ドル**を使っていました。機械を替える本当のコストの大半は、コードの書き直しだったのです。',
                            '最も苦しんでいたのが米国防総省でした。225 台の計算機を運用し、さらに発注中、プログラム実装に **2 '
                            '億ドル**超を投じていました。機種ごとにアセンブリ言語が違います。**プログラムが機械をまたげない限り、新しい機械を買うたびにソフトを買い直すのと同じ**でした。',
                            'そこで目標は明快に定まります。**移植可能**な言語——一度書けば他社の機械でも動き、業務担当者にも読め、新人も使えるもの。'],
                   'after': ['この出発点を覚えておいてください。後に批判された COBOL の特徴——冗長さ、予約語の多さ、肥大した文法——は、ほぼすべてこの目標の代償です。']},
                  {'id': 'people',
                   'title': '1959 年 4 月：ひとつの会議と、具体的な人々',
                   'kind': 'prose',
                   'body': ['物語は **1959 年 4 月 8 日**に始まります。Burroughs の計算機科学者 **Mary K. Hawes** '
                            'がペンシルベニア大学で学界・利用者・メーカーの代表を集め、議題はひとつでした。**共通の業務言語は必要か。**',
                            'この会議が重要だったのは、実際に作業する人たちが同じ部屋にそろったからです：'],
                   'bullets': ['**Grace Hopper**：FLOW-MATIC の考案者。彼女の 3 つの考えが COBOL '
                               'の形を決めました——**長い変数名、英語の命令語、データ定義と命令の分離**。「COBOL の母」と呼ばれますが、当事者の間では議論があります。',
                               '**Jean E. Sammet**：COBOL の主要設計者の一人で、6 人起草グループのメンバー。Hopper は「COBOL '
                               'の母でも創造者でも開発者でもない」と明言し、後に「引数渡しが無いこと」を委員会最大の誤りと述べています。',
                               '**Betty Holberton**：短期委員会のメンバー。3 '
                               'か月で仕様を出す期限を「**極度に楽観的**」と評し、過渡的な案で終わるとは思えないと述べました。',
                               '**Bob Bemer**（IBM、COMTRAN の作者）と **Roy Nutt**（FACT の作者）も同席しており、後に 2 '
                               'つの技術路線の対立を代表することになります。'],
                   'after': ['実際の起草は **6 人グループ**が行いました。IBM の William Selden と Gertrude Tierney、RCA の Howard '
                             'Bromberg と Howard Discount、Sylvania の Vernon Reeves と Jean E. Sammet です。つまり最初の '
                             'COBOL 仕様は 2 人の女性技術者と 4 人の同僚の手で書かれました。1959 年としては異例のことです。']},
                  {'id': 'fact',
                   'title': '1959 年 6〜10 月：3 か月の期限と、あの墓石',
                   'kind': 'prose',
                   'body': ['**1959 年 6 月 4 日**、 steering committee はこの活動を **CODASYL**（Committee on Data Systems '
                            'Languages）と名づけ、実行委員会を設置しました。短期委員会には**3 '
                            'か月で暫定仕様を出す**ことが課されます。言語を設計するには無茶な期限ですが、草案は確かに生まれました。',
                            '草案の評価は芳しくありません。委員長 **Joseph Wegstein**（米国家标准局、現 NIST）は「まだ粗い箇所があり、補足が必要」と評し、Bob '
                            'Bemer は後に「**寄せ集め**」と言い切りました。委員会は追い時間を与えます。',
                            '転機は **1959 年 10 月**。中間委員会に Roy Nutt の **FACT** 仕様が届き、出来が明らかに上でした。委員会はすぐに**FACT '
                            'を土台に作り直す**決議をします。3 か月を費やした短期委員会には大打撃で、作業が無駄になったかに見えました。',
                            'しかし決議は覆ります。理由は現実的でした。**FACT '
                            'は技術的に優れていても、移植性のために設計されておらず、ベンダーと利用者の交渉の産物でもなく、動く実装もなかった**のです。RCA の **Howard '
                            'Bromberg** も阻止に動きました。RCA の COBOL への投資を無駄にできないからです。',
                            'ここで Bromberg の不満は頂点に達し、後に語り継がれる行動に出ます。**「COBOL」と刻んだ墓石を買い、国防総省の Charles A. Phillips '
                            'に送りつけた**のです。15 ドル、2025 年の価値で約 170 ドルでした。'],
                   'after': ['仕様は **1960 年 1 月 8 日**に実行委員会で承認され、政府印刷局から刊行されました。これが **COBOL 60** です。最初の会議から刊行まで 9 '
                             'か月弱でした。']},
                  {'id': 'naming',
                   'title': '余談：名前はどう決まったか',
                   'kind': 'prose',
                   'body': ['1959 年 9 月の会議でも、名前はまだ決まっていませんでした。候補には今では聞き慣れない略語が並びます：'],
                   'bullets': ['**BUSY**（Business System）',
                               '**INFOSYL**（Information System Language）',
                               '**COCOSYL**（Common Computer Systems Language）'],
                   'after': ['最終的に **COBOL**（Common Business-Oriented '
                             'Language）に決まりました。誰が最初に提案したかは記録上はっきりしません。Bob Bemer は晩年に自分だと主張しましたが、確認できていません。']},
                  {'id': 'adoption',
                   'title': '1960 年代：過渡案から業界標準へ',
                   'kind': 'prose',
                   'body': ['意外なことに、COBOL '
                            'は当初**つなぎの案**にすぎませんでした。より良い設計ができるまでの暫定版という位置づけです。それが置き換えられずに残ったのは、**国防総省が計算機メーカーに実装の提供を迫った**からでした。',
                            '効果はすぐに出ます。**1960 年 9 月**までに 5 社（Bendix、Control Data、General Electric、National Cash '
                            'Register、Philco）が CODASYL に加わり、既存の加盟社はすべて COBOL コンパイラを発表しました。言語が成熟する前に市場ができたのです。',
                            '初期のコンパイラは遅く高価で、その数字は公開記録に残っています：'],
                   'bullets': ['**1962 年**の米海軍による評価では **毎分 3〜11 文**。数百行のプログラムのコンパイルに十数分かかりました。',
                               '**1964 年半ば**には **毎分 11〜1,000 文**に向上。',
                               '**1 文あたりのコンパイル費用**は 0.23〜18.91 ドル。記憶域が多いほど速く安くなりました。'],
                   'after': ['なぜ COBOL のコンパイラは難しいのか。文法が大きく任意要素が多く、しかも 1 つの言語で複数のデータ表現、暗黙の型変換、各種の I/O '
                             '準備を支える必要がありました。すべて標準に入っているため、コンパイラ作者は全部を受け止めるしかありませんでした。']},
                  {'id': 'standards',
                   'title': '1968〜1985：標準化と、最大の衝突',
                   'kind': 'prose',
                   'body': ['相互に互換性のない実装が標準化を後押ししました。**1962 年末**に ISO と米国標準協会（現 ANSI）がそれぞれ委員会を作り、**1968 年 8 月**に '
                            'ANSI が **USA Standard COBOL X3.23** を発行、以降の版の基礎となり、ISO は 1972 年に採用しました。',
                            'そして **COBOL-85**。COBOL 史上最も激しい改訂で、業界の対立に近い状況になりました：'],
                   'bullets': ['草案（しばしば COBOL-80 と呼ばれる）は COBOL-74 と**上方互換がなく**、既存コードの変更が必要でした。',
                               '**1981 年**、Travelers Insurance の上級副社長 **Joseph T. Brophy** が標準委員会を訴えると脅し、自社の '
                               '**4,000 万行**の移行を「非生産的」「プログラマ資源の完全な浪費」と評しました。',
                               'データ処理管理協会（DPMA）は「**強く反対**」を表明し、変換費用が「不当に高い」としました。',
                               '最初の公開レビューには **2,200 件**の意見が寄せられ、うち **1,700 件が反対**。変換費用は**1 行あたり最低 50 '
                               'セント**と見積もられ、賛成は十数件にとどまりました。'],
                   'after': ['それでも標準は施行されました。ただしこの衝突は 1 つの鉄則を残します。**既存コードを壊さずに能力を増やす**こと。',
                             '「1980 年代の COBOL '
                             'プログラムが今もそのままコンパイルできるのはなぜか」という問いへの答えもここにあります。改訂のたびに、まず壊さないことが求められてきたからです。']},
                  {'id': 'criticism',
                   'title': '1970〜80 年代：標的にされる',
                   'kind': 'prose',
                   'body': ['構造化プログラミングが広まると、COBOL は最も叩きやすい対象になりました。**1975 年**、Edsger Dijkstra は *Communications '
                            'of the ACM* に *How do we tell truths that might hurt?* '
                            'と題する投書を寄せ、その中に何十年も引用される一節があります。**「COBOL を使うと頭が駄目になる」**（"the use of COBOL cripples '
                            'the mind"）。',
                            '異論もありました。計算機科学者 **Howard E. Tompkins** は、非構造的な COBOL は「構造化 COBOL '
                            'をきちんと訓練されていないプログラマ」の産物であり、問題は言語ではなく訓練にあると反論しています。',
                            '感情を脇に置けば、当時の技術的な弱点は具体的で、記録にも残っています：'],
                   'bullets': ['**`GO TO` とスパゲッティコード**：絡んだプログラムの一因でした。ただし後に、`GO TO` '
                               'を無理に排除するとかえって複雑で質の低いコードになることが分かり、最終的には `PERFORM` と手続きに置き換えられました。',
                               '**`PERFORM` は手続きしか対象にできない**：ループ本体が別の場所にあり、読むときに往復が必要でした。',
                               '**データアクセスを制限できない**：COBOL-85 以前は、どの手続きも任意のデータ項目を読み書きできました。大規模システムでは深刻です。',
                               '**手続きに引数を渡せない**：Jean Sammet はこれを委員会最大の誤りと考え、COBOL-85 の入れ子サブプログラムでようやく解決しました。'],
                   'after': ['`GO TO` が今も残る理由は多くの言語と同じです。**後方互換**。削除すれば既存コードはコンパイルできません。']},
                  {'id': 'influence',
                   'title': '残したもの',
                   'kind': 'table',
                   'intro': 'COBOL の設計の多くは後に他の言語へ取り入れられました。いわば遺産の一覧です：',
                   'head': ['COBOL の要素', '影響を与えた先'],
                   'rows': [('レコードとファイル構造', 'PL/I と Pascal'),
                            ('`REDEFINES` 句', 'Pascal の variant record'),
                            ('`PICTURE` データ宣言', 'PL/I（多少の変更を経て採用）'),
                            ('`COPY` 機能', '後の include 指令')],
                   'after': ['より静かな影響は**工学の姿勢**にあります。可搬性と標準化へのこだわりがプログラムを多様なハードへ移せるようにし、外部参照を `ENVIRONMENT '
                             'DIVISION` に閉じ込めた構造が機種変更を容易にしました。データベース管理システムより早くファイル構造を明示的に定義し、「集約データ」は Fortran '
                             'の配列に対する大きな前進でした。',
                             '見落とされがちな事実をもう 1 つ。初期 COBOL の仕事の多くは女性が担いました。Grace Hopper、Jean Sammet、Betty '
                             'Holberton、Gertrude Tierney はいずれも中心的な役割です。1959 年としては極めて異例の分業でした。']},
                  {'id': 'later',
                   'title': '2000 年前后：2000 年問題と、なぜ COBOL だったのか',
                   'kind': 'prose',
                   'body': ['COBOL が最後に世間の注目を集めたのは **2000 年問題（Y2K）** でした。古いシステムが 2000 年に壊れるのではないかと議論され、その話題はいつも '
                            'COBOL に戻ってきました。なぜ COBOL だったのか。理由は 3 つあり、いずれも設計に由来します：'],
                   'bullets': ['**業務システムは日付をキーにする** — 入出金、契約、請求、ほぼすべてのレコードに日付があります。',
                               '**データは固定長項目**で、記憶域を節約するために年は 2 桁（`PIC 99`）で持つのが普通でした。1959 年当時、記憶域は高価で、2000 '
                               '年の分を予約する余裕はなかったのです。',
                               '**プログラムが長く動きすぎた** — 「2 桁で済ませる」決定のツケを、40 年後の人が払うことになりました。'],
                   'after': ['Y2K 対応費用の最大 **24%** が COBOL 由来とする研究もあります。そして対応が終わった後、**2003 '
                             '年の調査ではそれらのプログラムの多くが現役のまま**でした。直して使い続けたのであり、書き直したのではありません。COBOL '
                             'の運命を縮図にしたような話です。何度も「終わった」と言われ、そのたびに 10 年を生き延びてきました。']},
                  {'id': 'shape',
                   'title': '言語そのもの：知っておきたい数字',
                   'kind': 'table',
                   'intro': '最後に、言語の全体像をつかむための事実をまとめます。',
                   'head': ['項目', '事実'],
                   'rows': [('予約語', '300 以上。一部は文を自然に読ませるための別表記や複数形'),
                            ('交換可能なキーワード', '`IN` と `OF`、`TIME` と `TIMES`、`VALUE` と `VALUES` は相互に使える'),
                            ('標準が定める規模', '43 文、87 関数、1 クラス（大規模な標準ライブラリは無い）'),
                            ('識別子の長さ', '最大 31 文字。英字、数字、ハイフン、下線が使える'),
                            ('4 つの字句単位', '語（words）、リテラル、PICTURE 文字列、区切り子（separators）'),
                            ('Division 構造', 'IDENTIFICATION、ENVIRONMENT、DATA、PROCEDURE の 4 つ'),
                            ('階層', '各 DIVISION の下に SECTION、SECTION の下に PARAGRAPH'),
                            ('形式', '固定形式（既定）と自由形式。COBOL 2002 で Area A/B が統合され自由形式が導入された')]}]},

}
