"""Generate data, execute COBOL, stream-verify output, measure matcher only."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import tempfile
import time

REPO = Path(__file__).resolve().parents[6]
results = []


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


with tempfile.TemporaryDirectory(prefix='bank-memory-') as tmp:
    tmp = Path(tmp)
    source = REPO/'instructor/modules/07/01-one-to-one/MATCH.COB'
    subprocess.run(['cobc', '-Wall', '-I', str(REPO/'curriculum/bank/copybooks'),
        '-x', '-o', str(tmp/'match'), str(source)], check=True)
    for size in (10_000, 100_000, 1_000_000):
        with (tmp/'account').open('w') as master, (tmp/'transaction').open('w') as tx:
            for key in range(size):
                master.write(f'{key:010d}{key%100000000:08d}JPY+{1000:013d}A20261009001\n')
                tx.write(f'{key:010d}T{key:015d}20261009000001C{500:013d}N\n')
        env = dict(os.environ, ACCOUNT_FILE=str(tmp/'account'),
            TRANSACTION_FILE=str(tmp/'transaction'), BUSINESS_DATE='20261009')
        start = time.monotonic()
        with (tmp/'report').open('wb') as report:
            process = subprocess.Popen([str(tmp/'match')], stdout=report, env=env)
            _, status, usage = os.wait4(process.pid, 0)
            process.returncode = os.waitstatus_to_exitcode(status)
            assert process.returncode == 0, process.returncode
        elapsed = time.monotonic() - start
        with (tmp/'report').open('rb') as report:
            for key in range(size):
                assert report.readline() == f'MATCH|{key:010d}\n'.encode(), key
            assert report.readline() == ('COUNTS|'+ '|'.join(f'{x:012d}'
                for x in (size,size,size,0,0))+'\n').encode()
            assert report.read() == b''
        results.append(dict(records_per_side=size, seconds=round(elapsed,3),
            max_rss_kib=usage.ru_maxrss,
            account_sha256=sha256(tmp/'account'),
            transaction_sha256=sha256(tmp/'transaction'),
            report_sha256=sha256(tmp/'report')))
    # A coarse regression bound, not a production capacity promise.
    assert max(x['max_rss_kib'] for x in results) <= results[0]['max_rss_kib'] + 16_384
print(json.dumps(dict(source_sha256=sha256(source), runs=results), indent=2))
