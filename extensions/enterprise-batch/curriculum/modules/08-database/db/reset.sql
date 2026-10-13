-- 模块08 复位：清空业务表并仅重新载入种子（保留表结构）。
-- 用法（需要目标库可写）：
--   psql "$PGHOST" -v ON_ERROR_STOP=1 -f db/reset.sql
-- 说明：本模块的自动化实验使用一次性容器，容器销毁即复位；
-- 此脚本用于对“已存在的运行中课程库”做可重复复位，不触碰其他数据库。
TRUNCATE TABLE transaction_ledger, batch_commit, batch_run,
    account_balance, account, customer, probe_null RESTART IDENTITY;
DELETE FROM schema_version WHERE schema_version <> '001';
INSERT INTO schema_version (schema_version) VALUES ('001')
    ON CONFLICT (schema_version) DO NOTHING;
