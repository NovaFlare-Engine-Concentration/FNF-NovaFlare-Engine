"""Extract changed public declarations from actual successive release patches.

Candidates are lexical, not proof of a breaking change; inspect source and calls.
"""
import argparse
import gzip
import hashlib
import json
import re
from collections import defaultdict
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--audit', default='_build/origin-complete-version-audit-233')
parser.add_argument('--output', default='_build/origin-release-batches/declaration-deltas.json')
args = parser.parse_args()
root = Path(args.audit)
manifest = json.loads((root/'content-diff-manifest.json').read_text(encoding='utf-8-sig'))
references = json.loads((root/'historical-script-api-references.json').read_text(encoding='utf-8-sig'))['references']
decl = re.compile(r'\bpublic\s+(?:(?:static|inline|override|final|extern|dynamic|macro)\s+)*(?:function|var|final)\s+(\w+)\b')
def normalize_declaration(text):
    # A changed one-line function body is not a changed API signature.
    if re.search(r'\bfunction\s+\w+\s*\(', text):
        text = text.split('{', 1)[0].rstrip().rstrip(';').rstrip()
    return re.sub(r'\s+', ' ', text)

results=[]
for transition in manifest['transitions']:
    patch = root/transition['patch']
    if hashlib.sha256(patch.read_bytes()).hexdigest() != transition['sha256']:
        raise ValueError(f'Patch hash mismatch: {patch}')
    removed=defaultdict(set); added=defaultdict(set); path=None; old_path=None
    with gzip.open(patch,'rt',encoding='utf-8',errors='replace',newline='') as stream:
        for line in stream:
            if line.startswith('--- '):
                raw=line[4:].strip().replace('\\','/')
                old_path=raw.split('/',1)[1] if raw != '/dev/null' and '/' in raw else raw
            elif line.startswith('+++ '):
                raw=line[4:].strip().replace('\\','/')
                path=old_path if raw == '/dev/null' else (raw.split('/',1)[1] if '/' in raw else raw)
            elif line.startswith(('@@', '\\')) or not path:
                continue
            elif line[:1] in ('-', '+') and path.startswith('source/') and path.endswith('.hx'):
                text=line[1:].strip()
                # A commented-out declaration is not part of the public API.
                if text.startswith(('//', '/*', '*')):
                    continue
                match=decl.search(text)
                if match:
                    key=(path,match.group(1))
                    (removed if line[0]=='-' else added)[key].add(normalize_declaration(text))
    entries=[]
    for key in sorted(removed):
        old=removed[key]; new=added.get(key,set())
        old=old-new; new=new-removed[key]
        if not old: continue
        entries.append({'path':key[0], 'member':key[1], 'removed':sorted(old), 'added':sorted(new),
                        'historical_script_mentions':len(references.get(key[1],[])),
                        'status':'requires_semantic_review'})
    entries.sort(key=lambda e:(-e['historical_script_mentions'],e['path'],e['member']))
    results.append({'from':transition['from'],'to':transition['to'],'patch':str(patch),'candidates':entries})
out=Path(args.output); out.parent.mkdir(parents=True,exist_ok=True)
out.write_text(json.dumps({'scope':'Public declaration lines removed or changed in successive official source patches; lexical evidence only.',
                           'transitions':results},ensure_ascii=False,indent=2),encoding='utf-8')
print(f'{len(results)} transitions, {sum(len(t["candidates"]) for t in results)} declaration candidates; {out}')
