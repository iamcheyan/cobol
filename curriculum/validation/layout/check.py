"""Independent byte contract for the default GnuCOBOL/x86-64 profile."""
from pathlib import Path
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
with tempfile.TemporaryDirectory(prefix='cobol-layout-') as tmp:
    exe = Path(tmp) / 'layout'
    assert (HERE / 'LAYOUT.COB').exists(), 'Missing real byte-layout experiment'
    subprocess.run(['cobc', '-Wall', '-x', '-o', str(exe), str(HERE / 'LAYOUT.COB')], check=True)
    result = subprocess.run([str(exe)], cwd=tmp, check=True, capture_output=True)
    expected = bytes.fromhex('30303132333435 0012345c 0012345d 0001e240 40e20100')
    actual = (Path(tmp) / 'layout.bin').read_bytes()
    assert actual == expected, f'byte mismatch: {actual.hex()} != {expected.hex()}'
    assert result.stdout == b'LENGTHS=07,04,04,04,04\n'
    print('PASS: DISPLAY, positive/negative COMP-3, COMP and COMP-5; 23 bytes')
    print('HEX=' + actual.hex(' '))
