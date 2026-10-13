-- 模块08 课程逻辑表 DDL（schema_version = 001）
-- 目标 DB：PostgreSQL 17（P1 已锁定镜像 digest）。
-- 金额一律为最小单位整数（JPY=1 円），使用 NUMERIC(13,0)，绝不用浮点。
-- 本文件可重复执行：先 DROP 再 CREATE，仅用于课程一次性/沙箱数据库。

DROP TABLE IF EXISTS batch_commit;
DROP TABLE IF EXISTS transaction_ledger;
DROP TABLE IF EXISTS batch_run;
DROP TABLE IF EXISTS account_balance;
DROP TABLE IF EXISTS account;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS probe_null;
DROP TABLE IF EXISTS schema_version;

-- schema 版本表：抽取快照时连同版本一起记录。
CREATE TABLE schema_version (
    schema_version VARCHAR(3) PRIMARY KEY,
    applied_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
INSERT INTO schema_version (schema_version) VALUES ('001');

-- CUSTOMER v1（27B）映射；business_date 为快照业务日维度，不进入 27B 文件。
-- customer_name 空字符串合法（空串），NULL 单独用 contact_note 演示。
CREATE TABLE customer (
    customer_id    CHAR(8)      PRIMARY KEY,
    customer_name  VARCHAR(10)  NOT NULL,
    balance_demo   NUMERIC(8,0) NOT NULL,
    status         CHAR(1)      NOT NULL,
    contact_note   VARCHAR(20),
    business_date  CHAR(8)      NOT NULL,
    layout_version VARCHAR(3)   NOT NULL DEFAULT '001',
    CONSTRAINT customer_status_chk   CHECK (status IN ('A','D')),
    CONSTRAINT customer_balance_chk  CHECK (balance_demo >= 0),
    CONSTRAINT customer_layout_chk   CHECK (layout_version = '001')
);

-- ACCOUNT v1（47B）映射；opening_balance 为作业期初，closing_balance 为期末候选。
CREATE TABLE account (
    account_id      CHAR(10)      PRIMARY KEY,
    customer_id     CHAR(8)       NOT NULL REFERENCES customer(customer_id),
    currency        CHAR(3)       NOT NULL,
    balance_sign    CHAR(1)       NOT NULL,
    opening_balance NUMERIC(13,0) NOT NULL,
    closing_balance NUMERIC(13,0) NOT NULL,
    account_status  CHAR(1)       NOT NULL,
    business_date   CHAR(8)       NOT NULL,
    layout_version  CHAR(3)       NOT NULL DEFAULT '001',
    CONSTRAINT account_sign_chk    CHECK (balance_sign IN ('+','-')),
    CONSTRAINT account_status_chk  CHECK (account_status IN ('A','F','C')),
    CONSTRAINT account_layout_chk  CHECK (layout_version = '001')
);

-- 每账户累计余额（用于“逐账户核对”，与 account.closing_balance 分开，防止被误当明细）。
CREATE TABLE account_balance (
    account_id      CHAR(10)      PRIMARY KEY REFERENCES account(account_id),
    balance         NUMERIC(13,0) NOT NULL
);

-- TRANSACTION v1（55B）映射。唯一业务键 = (business_date, transaction_id)。
-- 幂等账本：同一业务键只能记账一次，重复插入触发 23505。
CREATE TABLE transaction_ledger (
    ledger_seq     BIGSERIAL       PRIMARY KEY,
    transaction_id CHAR(16)        NOT NULL,
    account_id     CHAR(10)        NOT NULL,
    business_date  CHAR(8)         NOT NULL,
    sequence_no    CHAR(6)         NOT NULL,
    direction      CHAR(1)         NOT NULL,
    amount         NUMERIC(13,0)   NOT NULL,
    status         CHAR(1)         NOT NULL,
    applied_run_id VARCHAR(32)     NOT NULL,
    applied_at     TIMESTAMPTZ     NOT NULL DEFAULT now(),
    CONSTRAINT transaction_ledger_bizkey UNIQUE (business_date, transaction_id),
    CONSTRAINT transaction_ledger_dir_chk CHECK (direction IN ('C','D')),
    CONSTRAINT transaction_ledger_amt_chk CHECK (amount >= 0)
);

-- 每次尝试的运行记录（run_id 标识尝试次数）。
CREATE TABLE batch_run (
    run_id        VARCHAR(32) PRIMARY KEY,
    business_date CHAR(8)     NOT NULL,
    started_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    status        VARCHAR(16) NOT NULL
);

-- 业务日提交标记；PK 保证同一业务日只成功提交一次（重复提交触发 23505）。
CREATE TABLE batch_commit (
    business_date  CHAR(8)     PRIMARY KEY,
    run_id         VARCHAR(32) NOT NULL,
    committed_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    applied_count  INTEGER     NOT NULL
);

-- 08.1 教学用：区分 NULL 与空字符串。
CREATE TABLE probe_null (
    id    INTEGER PRIMARY KEY,
    memo  VARCHAR(20)
);
