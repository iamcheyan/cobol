      *論理テーブル9 control_total：db/control_total.dat。
      *形式：date|run_id|K=V|K=V|...。収支一致の証跡。
       01 DB-CONTROL-TOTAL-ROW.
          05 DBCT-DATE            PIC X(8).
          05 DBCT-RUN-ID          PIC X(40).
          05 DBCT-PAIRS           PIC X(200).
