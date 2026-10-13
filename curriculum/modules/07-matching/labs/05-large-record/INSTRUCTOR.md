# 讲师说明

先要求学员独立用目录算首/中/尾字段offset，再展示实际Copybook。不要把 `LENGTH OF` 总长等同逐字段offset证明。阶梯提示：1) 先验证总输入字节长度；2) 键游标每次只推进较小一侧；3) 匹配键后按catalog的175条规则比较；4) 任何结构错误都丢弃整个stage；5) PII/CONFIDENTIAL只报告字段ID/位置，不输出原值。

评分：布局和offset 20%，双游标/EOF/顺序 15%，field comparison semantics 25%，非法表示与结构拒绝 15%，报告脱敏/控制统计 10%，锁、候选校验、失败不发布 10%，V1→V2影响调查 5%。常见故障：LINE SEQUENTIAL把二进制变成文本；在PIC填充后才测长度；将合法packed高字节当ASCII拒绝；负零误报；重复键漏检；忽略字段误计业务差异；stage rename后才做可失败验收。
