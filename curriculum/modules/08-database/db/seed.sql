-- 模块08 合成种子数据（无真实客户，无生产凭据）。
-- 全部金额为最小单位整数。business_date 唯一定义快照业务日。
-- 预期（独立核算见 expected/README.md）：
--   20261009 客户：C1,C2,C3,C5；20261010 客户：C4。
--   账户 20261009：A1(cust1)=100, A2(cust1)=200, A3(cust2)=300。
--   应用 fixtures/transactions-20261009.dat 后：A1=130, A2=270, A3=300。

INSERT INTO customer
    (customer_id, customer_name, balance_demo, status, contact_note, business_date)
VALUES
    ('00000001', 'ACME CORP ', 100, 'A', NULL,  '20261009'),
    ('00000002', 'BETA LLC  ', 250, 'A', 'VIP', '20261009'),
    ('00000003', 'GAMMA LTD ', 300, 'D', NULL,  '20261009'),
    ('00000005', 'ECHO CO   ', 500, 'A', '',    '20261009'),
    ('00000004', 'DELTA INC ', 400, 'A', NULL,  '20261010');

INSERT INTO account
    (account_id, customer_id, currency, balance_sign, opening_balance,
     closing_balance, account_status, business_date)
VALUES
    ('0000000001', '00000001', 'JPY', '+', 100, 100, 'A', '20261009'),
    ('0000000002', '00000001', 'JPY', '+', 200, 200, 'A', '20261009'),
    ('0000000003', '00000002', 'JPY', '+', 300, 300, 'A', '20261009');

INSERT INTO account_balance (account_id, balance)
VALUES
    ('0000000001', 100), ('0000000002', 200), ('0000000003', 300);

INSERT INTO probe_null (id, memo) VALUES (1, NULL), (2, ''), (3, 'x');
