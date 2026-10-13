# 独立预期与人工核算（模块 01）

本目录的预期由 ACCOUNT v1 契约和人工逐条核算得出，不是程序输出的复制。
`check.py` 逐字节比对控制报告，并从原始夹具独立推导 `accepted.dat` 与
`rejected.dat`，不做整文件 `trim`。

## 契约规则

一条 ACCOUNT v1 记录在其 47 字节内满足：账号 1–10 全数字；币种 19–21 为 `JPY`；
符号 22 为 `+`/`-`；金额 23–35 全数字；状态 36 为 `A`/`F`/`C`；日期 37–44 等于作业
营业日；布局版本 45–47 为 `001`。文件按账号严格升序。

- 结构契约违反（长度、LF、CR、账号字符、布局、日期、排序/重复键）：RC8，整批失败，
  不发布任何输出目录。
- 字段业务规则（未知状态）：RC4，该条进 `rejected.dat`，其余进 `accepted.dat`，
  仍发布已核对结果。
- 读取总数守恒：`READ = ACCEPTED + REJECTED`。

## 逐夹具核算

**normal**：3 条记录，账号 1/2/3 严格升序，状态 A/F/C 均合法 → 接收 3、拒绝 0。

```text
READ=000000000003  ACCEPTED=000000000003  REJECTED=000000000000
```

**empty**：0 字节文件，允许为空 → 读入 0 条。

```text
READ=000000000000  ACCEPTED=000000000000  REJECTED=000000000000
```

**single**：1 条账号 42、状态 A → 接收 1。

```text
READ=000000000001  ACCEPTED=000000000001  REJECTED=000000000000
```

**unknown-status**：1 条账号 7、状态 `Z`（不在 `A/F/C`）→ 拒绝 1，原因 `UNKNOWN-STATUS`。

```text
READ=000000000001  ACCEPTED=000000000000  REJECTED=000000000001
```

拒绝记录格式为原始 47 字节 + `|` + 原因，故 `rejected.dat` 中该行 62 字节（不含 LF）：

```text
000000000700000003JPY+0000000000000Z20261009001|UNKNOWN-STATUS
```

## 发布条件

控制列 `CONTROL|READ=..|ACCEPTED=..|REJECTED=..` 与上方核算一致，且
`accepted.dat`/`rejected.dat` 逐字节匹配时才算通过。RC8 夹具的通过条件是
**没有**输出目录产生，且源夹具 SHA256 不变。
