#!/usr/bin/env python3
"""Primary-authored B03 acceptance cases, independent of lesson fixtures."""
from collections import Counter
from pathlib import Path
import hashlib
import json
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[2]
FIXTURES = Path(__file__).resolve().parent / 'fixtures/b03-customer-order'
RUNNER = REPO / 'curriculum/modules/07-matching/labs/04-many-to-many/scripts/run.sh'
EVIDENCE = Path(__file__).resolve().parent / 'evidence/B03-primary-independent.json'


def records(path):
    data = path.read_bytes()
    assert not data or data.endswith(b'\n'), path
    return data.splitlines()


def run_case(case, output):
    names = ['account.dat', 'transaction.dat', 'reversal-link.dat',
             'customer-snapshot.dat', 'previous-day.dat']
    if case.get('override_stream'):
        names[3 if case['override_stream'] == 'snapshot' else 4] = case['override_file']
    inputs = [FIXTURES / name for name in names]
    before = [hashlib.sha256(path.read_bytes()).hexdigest() for path in inputs]
    result = subprocess.run(['bash', str(RUNNER), *(str(p) for p in inputs),
                             str(output), '20261009'], capture_output=True, text=True,
                            timeout=120)
    observation = {'case': case['case'], 'raw_rc': result.returncode,
                   'expected_rc': case['expected_rc'], 'published': output.exists(),
                   'stdout': result.stdout, 'stderr': result.stderr}
    assert result.returncode == case['expected_rc'], observation
    assert before == [hashlib.sha256(path.read_bytes()).hexdigest() for path in inputs]
    assert not Path(str(output) + '.lock').exists(), 'own lock leaked'
    if case['expected_rc'] == 8:
        assert not output.exists(), 'fatal data error published'
        return observation
    masters = records(FIXTURES / 'expected-master.dat')
    accounts = records(FIXTURES / 'account.dat')
    transactions = records(FIXTURES / 'transaction.dat')
    eligible_accounts = set(case['eligible_account_ids'])
    eligible_tx = set(case['eligible_transaction_ordinals'])
    expected_master = [row for row in masters if int(row[:10]) in eligible_accounts]
    expected_tx = [row for index, row in enumerate(transactions, 1) if index in eligible_tx]
    assert records(output / 'eligible-master.dat') == expected_master, observation
    assert records(output / 'eligible-transaction.dat') == expected_tx, observation
    assert (output / 'customer-totals.csv').read_bytes() == (
        FIXTURES / 'expected-customer-totals.csv').read_bytes(), observation
    assert (output / 'rejected-l2.dat').read_bytes() == b'', observation
    isolated_account = []
    isolated_tx = []
    for line in records(output / 'isolation.txt'):
        fields = line.rstrip(b' ').split(b'|')
        assert len(fields) == 4 and fields[3], line
        if fields[0] == b'ACCOUNT':
            assert len(fields[2]) == 47 and fields[1] == fields[2][10:18], line
            isolated_account.append(fields[2])
        elif fields[0] == b'TRANSACTION':
            assert len(fields[2]) == 55, line
            owner = next(a[10:18] for a in accounts if a[:10] == fields[2][:10])
            assert fields[1] == owner, line
            isolated_tx.append(fields[2])
        else:
            raise AssertionError(('unexpected isolation source in these cases', line))
    assert Counter(isolated_account) == Counter(
        row for row in accounts if int(row[:10]) not in eligible_accounts), observation
    assert Counter(isolated_tx) == Counter(
        row for index, row in enumerate(transactions, 1) if index not in eligible_tx), observation
    statuses = {}
    for line in records(output / 'customer-status.txt'):
        fields = line.rstrip(b' ').split(b'|')
        key = int(fields[0])
        assert key not in statuses, line
        statuses[key] = fields[1] == b'ELIGIBLE'
    assert set(statuses) == {1, 2}, statuses
    assert {key for key, eligible in statuses.items() if eligible} == set(
        case['eligible_customer_ids']), observation
    observation['byte_exact_outputs_and_source_partition'] = True
    return observation


def main():
    cases = [{'case': 'normal-nonmonotone-customer', 'expected_rc': 0,
              'eligible_customer_ids': [1, 2], 'eligible_account_ids': [1, 2, 3],
              'eligible_transaction_ordinals': [1, 2, 3, 4]}]
    cases += json.loads((FIXTURES / 'case-expectations.json').read_text())['cases']
    evidence = {'status': 'RUNNING', 'scope': 'primary independent small byte-exact cases',
                'fixture_sha256': {
                    path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                    for path in sorted(FIXTURES.iterdir()) if path.is_file()},
                'results': []}
    try:
        with tempfile.TemporaryDirectory(prefix='primary-b03-independent-') as temp:
            for index, case in enumerate(cases):
                observation = run_case(case, Path(temp) / str(index))
                evidence['results'].append(observation)
                print(f"PASS: {case['case']} RC={observation['raw_rc']}", flush=True)
        evidence['status'] = 'PASS'
    except BaseException as error:
        evidence['status'] = 'FAIL'
        evidence['failure'] = repr(error)
        raise
    finally:
        evidence['source_sha256'] = hashlib.sha256((REPO /
            'instructor/modules/07/04-many-to-many/BATCHL3.COB').read_bytes()).hexdigest()
        evidence['supporting_source_sha256'] = {
            str(path.relative_to(REPO)): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in [RUNNER, RUNNER.parent / 'verify.py',
                         RUNNER.parent / 'build.sh']}
        EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
        EVIDENCE.write_text(json.dumps(evidence, indent=2) + '\n')


if __name__ == '__main__':
    main()
