"""Regression tests for both Windows minidump memory stream formats."""
import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest

TOOL = Path(__file__).resolve().parents[1] / 'analyze-novaflare-raw-stack.py'
spec = importlib.util.spec_from_file_location('raw_stack', TOOL)
raw_stack = importlib.util.module_from_spec(spec)
spec.loader.exec_module(raw_stack)


def fixture(kind, architecture=9):
    data = bytearray(832)
    base, stack = 0x140000000, 0x200000000
    struct.pack_into('<4sIII', data, 0, b'MDMP', 0, 4, 32)
    entries = [(4, 112, 80), (6, 168, 192), (7, 56, 360),
               (kind, 20 if kind == 5 else 32, 416)]
    for i, entry in enumerate(entries):
        struct.pack_into('<III', data, 32 + 12 * i, *entry)
    struct.pack_into('<I', data, 80, 1)
    struct.pack_into('<QIIII', data, 84, base, 0x1000, 0, 0, 704)
    struct.pack_into('<I', data, 192, 0x1234)
    struct.pack_into('<II', data, 192 + 160, 256, 448)
    struct.pack_into('<H', data, 360, architecture)
    if kind == 5:
        struct.pack_into('<IQII', data, 416, 1, stack, 64, 768)
    else:
        struct.pack_into('<QQQQ', data, 416, 1, 768, stack, 64)
    struct.pack_into('<Q', data, 448 + 152, stack)
    struct.pack_into('<Q', data, 448 + 248, base + 0x100)
    name = 'fixture.exe'.encode('utf-16-le')
    struct.pack_into('<I', data, 704, len(name))
    data[708:708 + len(name)] = name
    struct.pack_into('<Q', data, 768 + 8, base + 0x200)
    return data


class RawStackTests(unittest.TestCase):
    def run_fixture(self, data):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / 'test.dmp'
            path.write_bytes(data)
            return raw_stack.inspect(path, None, 64)

    def test_both_memory_streams(self):
        for kind in (5, 9):
            with self.subTest(kind=kind):
                result = self.run_fixture(fixture(kind))
                self.assertEqual(result['exceptionThread'], '0x1234')
                self.assertEqual(result['candidates'][0]['stackOffset'], '0x8')
                self.assertEqual(result['candidates'][0]['rva'], '0x200')

    def test_non_amd64_and_truncated_rejected(self):
        with self.assertRaises(ValueError):
            self.run_fixture(fixture(5, architecture=0))
        with self.assertRaises(ValueError):
            self.run_fixture(fixture(9)[:500])


if __name__ == '__main__':
    unittest.main()
