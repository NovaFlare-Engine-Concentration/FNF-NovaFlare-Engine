"""Inspect raw x64 exception-stack words in a Windows minidump.

Addresses in the output are candidates, not a verified stack unwind. Optional
MSVC map symbols must come from the exact executable used to create the dump.
This tool does not load or execute any module from the dump.
"""
import argparse
import bisect
import json
import mmap
import re
import struct
from pathlib import Path


def inspect(path, map_path, scan_bytes):
    if scan_bytes < 8 or scan_bytes > 65536:
        raise ValueError('scan bytes must be between 8 and 65536')
    with open(path, 'rb') as source, mmap.mmap(source.fileno(), 0, access=mmap.ACCESS_READ) as data:
        def unpack(fmt, offset):
            size = struct.calcsize(fmt)
            if offset < 0 or offset + size > len(data):
                raise ValueError('structure outside minidump')
            return struct.unpack_from(fmt, data, offset)

        sig, _, count, directory = unpack('<4sIII', 0)
        if sig != b'MDMP' or count > 65536 or directory + count * 12 > len(data):
            raise ValueError('invalid minidump directory')
        streams = {}
        for i in range(count):
            kind, size, offset = unpack('<III', directory + i * 12)
            if offset + size > len(data):
                raise ValueError('stream outside minidump')
            if kind in (4, 5, 6, 7, 9) and kind in streams:
                raise ValueError('duplicate required stream')
            streams[kind] = (offset, size)
        if 4 not in streams or 6 not in streams or 7 not in streams:
            raise ValueError('module, exception or system-info stream missing')
        system_at, system_size = streams[7]
        if system_size < 2 or unpack('<H', system_at)[0] != 9:
            raise ValueError('only AMD64 minidumps are supported')
        exc, length = streams[6]
        if length < 168:
            raise ValueError('short exception stream')
        tid = unpack('<I', exc)[0]
        context_size, context = unpack('<II', exc + 160)
        if context_size < 256 or context + context_size > len(data):
            raise ValueError('missing x64 context')
        rsp, rip = unpack('<Q', context + 152)[0], unpack('<Q', context + 248)[0]
        modules_at, modules_size = streams[4]
        count_modules = unpack('<I', modules_at)[0]
        if 4 + count_modules * 108 > modules_size:
            raise ValueError('invalid module list')
        modules = []
        for i in range(count_modules):
            pos = modules_at + 4 + i * 108
            base, image_size, _, _, name = unpack('<QIIII', pos)
            name_len = unpack('<I', name)[0]
            if name_len % 2 or name + 4 + name_len > len(data):
                raise ValueError('invalid module name')
            module_name = data[name + 4:name + 4 + name_len].decode('utf-16-le')
            modules.append((base, base + image_size, module_name))
        exception_module = next((x for x in modules if x[0] <= rip < x[1]), None)
        if exception_module is None:
            raise ValueError('exception module absent')
        ranges = []
        if 5 in streams:
            pos, length = streams[5]
            count_ranges = unpack('<I', pos)[0]
            if 4 + count_ranges * 16 > length:
                raise ValueError('invalid memory list')
            for i in range(count_ranges):
                address, size, offset = unpack('<QII', pos + 4 + i * 16)
                if offset + size > len(data):
                    raise ValueError('memory range outside dump')
                ranges.append((address, size, offset))
        if 9 in streams:
            pos, length = streams[9]
            count_ranges, offset = unpack('<QQ', pos)
            if 16 + count_ranges * 16 > length:
                raise ValueError('invalid memory64 list')
            for i in range(count_ranges):
                address, size = unpack('<QQ', pos + 16 + i * 16)
                if offset + size > len(data):
                    raise ValueError('memory64 range outside dump')
                ranges.append((address, size, offset))
                offset += size
        stack = next((x for x in ranges if x[0] <= rsp < x[0] + x[1]), None)
        if stack is None:
            raise ValueError('exception stack not present in memory streams')
        symbols = []
        if map_path:
            pattern = re.compile(r'^\s*[0-9a-fA-F]{4}:[0-9a-fA-F]{8}\s+(\S+)\s+([0-9a-fA-F]{16})\s+')
            preferred = None
            with open(map_path, encoding='utf-8', errors='replace') as map_file:
                for line in map_file:
                    header = re.search(r'Preferred load address is\s+([0-9a-fA-F]+)', line)
                    if header:
                        preferred = int(header.group(1), 16)
                    match = pattern.match(line)
                    if match:
                        if preferred is None:
                            raise ValueError('MSVC map preferred load address missing')
                        absolute = int(match.group(2), 16)
                        if absolute >= preferred:
                            symbols.append((absolute - preferred, match.group(1)))
            if preferred is None or not symbols:
                raise ValueError('MSVC map has no preferred address or symbols')
            symbols.sort()
        addresses = [x[0] for x in symbols]
        count_bytes = min(scan_bytes, stack[0] + stack[1] - rsp)
        rows = []
        for delta in range(0, count_bytes - 7, 8):
            value = unpack('<Q', stack[2] + rsp - stack[0] + delta)[0]
            module = next((x for x in modules if x[0] <= value < x[1]), None)
            if module is None:
                continue
            row = {'stackOffset': hex(delta), 'address': hex(value),
                   'module': module[2], 'rva': hex(value - module[0])}
            if map_path and module == exception_module:
                index = bisect.bisect_right(addresses, value - module[0]) - 1
                if index >= 0:
                    row['nearestSymbol'] = symbols[index][1]
                    row['symbolOffset'] = hex(value - module[0] - symbols[index][0])
            rows.append(row)
        return {'dump': str(path), 'exceptionThread': hex(tid), 'rsp': hex(rsp),
                'rip': hex(rip), 'scanBytes': count_bytes, 'candidates': rows,
                'caveat': 'Raw stack words in module address ranges are candidates, not verified frames; map identity must be verified separately.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('dump', type=Path)
    parser.add_argument('--msvc-map', type=Path)
    parser.add_argument('--bytes', type=int, default=2048)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    try:
        result = inspect(args.dump, args.msvc_map, args.bytes)
    except (ValueError, OSError, struct.error) as error:
        parser.exit(1, f'error: {error}\n')
    text = json.dumps(result, indent=2, ensure_ascii=False) + '\n'
    if args.output:
        with args.output.open('x', encoding='utf-8') as output:
            output.write(text)
    else:
        print(text, end='')


if __name__ == '__main__':
    main()
