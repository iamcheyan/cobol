"""Business acceptance. Python creates/checks fixtures, never matches files."""
from pathlib import Path
import subprocess
import tempfile
import unittest

LAB = Path(__file__).resolve().parents[1]
RUN = LAB / 'scripts/run.sh'

class MatchingContract(unittest.TestCase):
    def run_case(self, master, tx, rc, expected=None, date='20261009'):
        with tempfile.TemporaryDirectory(prefix='bank-l1-') as folder:
            root = Path(folder)
            for name, value in [('account.dat', master), ('transaction.dat', tx)]:
                if value is not None:
                    (root / name).write_bytes(value)
            self.assertTrue(RUN.exists(), 'Missing runnable L1 lesson')
            result = subprocess.run([str(RUN), str(root / 'account.dat'),
                str(root / 'transaction.dat'), str(root / 'published'), date],
                capture_output=True)
            self.assertEqual(result.returncode, rc, result.stderr.decode(errors='replace'))
            if rc:
                self.assertFalse((root / 'published').exists(), 'Failure published results')
            else:
                report = (root / 'published/report.txt').read_bytes()
                self.assertEqual(report, expected)
                self.assertEqual((root/'published/account.input.dat').read_bytes(), master)
                self.assertEqual((root/'published/transaction.input.dat').read_bytes(), tx)
                m_amounts = {line[:10]: int(line[22:35]) *
                    (-1 if line[21:22] == b'-' else 1) for line in master.splitlines()}
                t_amounts = {line[:10]: int(line[41:54]) for line in tx.splitlines()}
                rows = [line.split(b'|') for line in report.splitlines()
                    if not line.startswith(b'COUNTS|')]
                self.assertEqual(sum(m_amounts.values()), sum(m_amounts[key]
                    for kind, key in rows if kind in (b'MATCH',b'MASTER-ONLY')))
                self.assertEqual(sum(t_amounts.values()), sum(t_amounts[key]
                    for kind, key in rows if kind in (b'MATCH',b'TX-ONLY')))
            return result

    def test_normal_three_way(self):
        self.run_case((LAB / 'fixtures/normal/account.dat').read_bytes(),
            (LAB / 'fixtures/normal/transaction.dat').read_bytes(), 0,
            (LAB / 'expected/normal.txt').read_bytes())

    def test_eof_matrix(self):
        m = (LAB / 'fixtures/normal/account.dat').read_bytes().splitlines(keepends=True)
        t = (LAB / 'fixtures/normal/transaction.dat').read_bytes().splitlines(keepends=True)
        cases = [
            (b'', b'', b'', (0,0,0,0,0)),
            (m[0], b'', b'MASTER-ONLY|0000000001\n', (1,0,0,1,0)),
            (b'', t[0], b'TX-ONLY|0000000001\n', (0,1,0,0,1)),
            (m[0], t[0], b'MATCH|0000000001\n', (1,1,1,0,0)),
            (m[0], t[1], b'MASTER-ONLY|0000000001\nTX-ONLY|0000000002\n', (1,1,0,1,1)),
            (m[1], t[0], b'TX-ONLY|0000000001\nMASTER-ONLY|0000000003\n', (1,1,0,1,1)),
        ]
        for master, tx, rows, counts in cases:
            with self.subTest(counts=counts):
                tail = ('COUNTS|' + '|'.join(f'{x:012d}' for x in counts) + '\n').encode()
                self.run_case(master, tx, 0, rows + tail)

    def test_bad_bytes_and_missing_input(self):
        m = (LAB / 'fixtures/normal/account.dat').read_bytes().splitlines(keepends=True)[0]
        t = (LAB / 'fixtures/normal/transaction.dat').read_bytes().splitlines(keepends=True)[0]
        for side, valid in [('master', m), ('tx', t)]:
            variants = [None, valid[:-2]+b'\n', valid[:-1]+b'X\n',
                valid[:-1], b'\n', valid.replace(b'JPY', b'USD') if side == 'master'
                else valid[:10]+b'\x00'+valid[11:], valid.replace(b'20261009', b'20261008'),
                b'X'+valid[1:], valid+valid]
            for bad in variants:
                with self.subTest(side=side, bad=bad):
                    self.run_case(bad if side == 'master' else m,
                        bad if side == 'tx' else t, 12 if bad is None else 8)

    def test_reverse_order(self):
        m = (LAB / 'fixtures/normal/account.dat').read_bytes().splitlines(keepends=True)
        t = (LAB / 'fixtures/normal/transaction.dat').read_bytes().splitlines(keepends=True)
        self.run_case(m[1]+m[0], t[0], 8)
        self.run_case(m[0], t[1]+t[0], 8)

    def test_invalid_calendar_date(self):
        self.run_case(b'', b'', 8, date='20260230')

    def test_output_protection(self):
        with tempfile.TemporaryDirectory(prefix='bank-publish-') as folder:
            root = Path(folder)
            (root/'a').write_bytes(b'')
            (root/'t').write_bytes(b'')
            (root/'published.lock').mkdir()
            result = subprocess.run([str(RUN), str(root/'a'), str(root/'t'),
                str(root/'published'), '20261009'], capture_output=True)
            self.assertEqual(result.returncode, 12)
            self.assertFalse((root/'published').exists())
            self.assertTrue((root/'published.lock').exists())
            (root/'published.lock').rmdir()
            (root/'published').mkdir()
            (root/'published/sentinel').write_text('keep')
            result = subprocess.run([str(RUN), str(root/'a'), str(root/'t'),
                str(root/'published'), '20261009'], capture_output=True)
            self.assertEqual(result.returncode, 12)
            self.assertEqual((root/'published/sentinel').read_text(), 'keep')

    def test_unexpected_program_exit_is_system_failure(self):
        with tempfile.TemporaryDirectory(prefix='bank-rc-') as folder:
            root = Path(folder)
            (root/'a').write_bytes(b'')
            (root/'t').write_bytes(b'')
            source = root/'FAIL.COB'
            source.write_text("       identification division.\n"
                "       program-id. FAIL-RC.\n       procedure division.\n"
                "           move 3 to return-code\n           goback.\n")
            import os
            result = subprocess.run([str(RUN), str(root/'a'), str(root/'t'),
                str(root/'published'), '20261009'], capture_output=True,
                env=dict(os.environ, COURSE_SOURCE=str(source)))
            self.assertEqual(result.returncode, 12)
            self.assertFalse((root/'published').exists())

    def test_committed_invalid_fixtures(self):
        m = (LAB/'fixtures/normal/account.dat').read_bytes()
        t = (LAB/'fixtures/normal/transaction.dat').read_bytes()
        for path in (LAB/'fixtures/invalid').glob('*.dat'):
            with self.subTest(fixture=path.name):
                if path.name.startswith('account-'):
                    self.run_case(path.read_bytes(), t, 8)
                else:
                    self.run_case(m, path.read_bytes(), 8)

    def test_extreme_keys_are_not_eof(self):
        m = (LAB/'fixtures/normal/account.dat').read_bytes().splitlines(keepends=True)[0]
        t = (LAB/'fixtures/normal/transaction.dat').read_bytes().splitlines(keepends=True)[0]
        master = b'0000000000'+m[10:]+b'9999999999'+m[10:]
        tx = b'0000000000'+t[10:]+b'9999999999T999999999999999'+t[26:]
        self.run_case(master, tx, 0, b'MATCH|0000000000\nMATCH|9999999999\n'
            b'COUNTS|000000000002|000000000002|000000000002|000000000000|000000000000\n')

    def test_uncooperative_publication_collision(self):
        with tempfile.TemporaryDirectory(prefix='bank-collision-') as folder:
            root = Path(folder)
            (root/'a').write_bytes(b'')
            (root/'t').write_bytes(b'')
            source = root/'COLLISION.COB'
            source.write_text("       identification division.\n"
                "       program-id. COLLISION.\n       data division.\n"
                "       working-storage section.\n       01 CMD pic x(4096).\n"
                "       procedure division.\n"
                "           accept CMD from environment 'COLLISION_COMMAND'\n"
                "           call 'SYSTEM' using function trim(CMD)\n"
                "           move 0 to return-code\n           goback.\n")
            import os
            import shlex
            result = subprocess.run([str(RUN), str(root/'a'), str(root/'t'),
                str(root/'published'), '20261009'], capture_output=True,
                env=dict(os.environ, COURSE_SOURCE=str(source),
                    COLLISION_COMMAND='mkdir -- '+shlex.quote(str(root/'published'))))
            self.assertEqual(result.returncode, 12)
            self.assertTrue((root/'published').is_dir())
            self.assertEqual(list((root/'published').iterdir()), [])
            self.assertFalse(list(root.glob('.bank-l1.*')))

if __name__ == '__main__':
    unittest.main(verbosity=2)
