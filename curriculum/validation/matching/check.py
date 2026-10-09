"""Micro-fixtures computed from the three-way comparison contract."""
from pathlib import Path
import subprocess
import tempfile
HERE = Path(__file__).resolve().parent
CASES = [
    ('mixed', b'0011000\n0033000\n0055000\n0088000\n',
     b'0010500\n0020200\n0050300\n0070900\n', 0,
     b'MATCH|001|1000|0500\nTX-ONLY|002|0200\nMASTER-ONLY|003|3000\n'
     b'MATCH|005|5000|0300\nTX-ONLY|007|0900\nMASTER-ONLY|008|8000\n'),
    ('both-empty', b'', b'', 0, b''),
    ('master-empty', b'', b'0010500\n', 0, b'TX-ONLY|001|0500\n'),
    ('tx-empty', b'0011000\n', b'', 0, b'MASTER-ONLY|001|1000\n'),
    ('last-match', b'0011000\n', b'0010500\n', 0, b'MATCH|001|1000|0500\n'),
    ('master-first-eof', b'0011000\n', b'0020500\n', 0,
     b'MASTER-ONLY|001|1000\nTX-ONLY|002|0500\n'),
    ('tx-first-eof', b'0021000\n', b'0010500\n', 0,
     b'TX-ONLY|001|0500\nMASTER-ONLY|002|1000\n'),
    ('no-final-lf', b'0011000', b'0010500', 0, b'MATCH|001|1000|0500\n'),
]
INVALID = {
    'duplicate': b'0011000\n0012000\n',
    'reverse': b'0021000\n0012000\n',
    'bad-key': b'00A1000\n',
    'bad-amount': b'0011A00\n',
    'short': b'001100\n',
    'long': b'00110000\n',
    'blank': b'\n',
}
with tempfile.TemporaryDirectory(prefix='cobol-matching-') as tmp:
    tmp = Path(tmp)
    exe = tmp / 'match'
    assert (HERE / 'MATCH.COB').exists(), 'Missing sequential COBOL matcher'
    subprocess.run(['cobc', '-Wall', '-x', '-o', str(exe), str(HERE / 'MATCH.COB')], check=True)
    for name, master, tx, rc, expected in CASES:
        (tmp / 'master.dat').write_bytes(master)
        (tmp / 'transaction.dat').write_bytes(tx)
        result = subprocess.run([str(exe)], cwd=tmp, capture_output=True)
        assert result.returncode == rc, (name, result)
        assert result.stdout == expected, (name, result.stdout, expected)
    count = len(CASES)
    for side in ('master.dat', 'transaction.dat'):
        for name, data in INVALID.items():
            (tmp / 'master.dat').write_bytes(b'0011000\n')
            (tmp / 'transaction.dat').write_bytes(b'0010500\n')
            (tmp / side).write_bytes(data)
            result = subprocess.run([str(exe)], cwd=tmp, capture_output=True)
            assert result.returncode == 8, (side, name, result)
            count += 1
    for side in ('master.dat', 'transaction.dat'):
        (tmp / 'master.dat').write_bytes(b'0011000\n')
        (tmp / 'transaction.dat').write_bytes(b'0010500\n')
        (tmp / side).unlink()
        result = subprocess.run([str(exe)], cwd=tmp, capture_output=True)
        assert result.returncode == 12, (side, result)
        count += 1
    print(f'PASS: {count} sequential matching cases')
