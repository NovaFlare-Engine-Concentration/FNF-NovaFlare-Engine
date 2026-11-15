"""Group existing Origin history evidence by release transition for review.

Run from the engine root. This is an inventory, not a compatibility verdict.
"""
import argparse
import json
from collections import Counter
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--audit', default='_build/origin-complete-version-audit-233')
parser.add_argument('--output', default='_build/origin-release-batches/review.json')
args = parser.parse_args()
root = Path(args.audit)
load = lambda n: json.loads((root / n).read_text(encoding='utf-8-sig'))
transitions = load('tree-deltas.json')['transitions']
content = {(x['from'], x['to']): x for x in load('content-diff-manifest.json')['transitions']}
refs = load('historical-script-api-references.json')['references']
signatures = load('unique-signature-change-candidates.json')['candidates']
removed = load('unique-removed-api-candidates.json')['candidates']
domains = {
    'scripts': ('/modding/', '/hscript/', 'polymod', 'example_mods/'),
    'chart_events': ('/data/song/', '/play/song/', '/play/event/', '/conductor'),
    'notes': ('/play/notes/', '/notestyle/'),
    'characters_stage': ('/character/', '/stage/', '/animation/'),
    'assets': ('/paths.hx', '/assets.hx', '/asset'),
    'results_death': ('resultstate', 'gameoversubstate'),
}
results=[]
for t in transitions:
    counts=Counter()
    changed_paths = [item['path'].lower() for item in t['changes']]
    for item in t['changes']:
        path=item['path'].lower()
        if not path.startswith(('source/', 'example_mods/')): continue
        for domain, fragments in domains.items():
            if any(x in path for x in fragments): counts[domain]+=1
    meta=content.get((t['from'],t['to']))
    patch=root/meta['patch'] if meta else None
    candidates=[]
    for c in removed+signatures:
        if t['from'] not in c.get('refs',[]): continue
        module = (c.get('module') or '').lower().replace('\\', '/')
        if not module or not any(path == module or path.endswith('/' + module) for path in changed_paths): continue
        member=c.get('member')
        uses=len(refs.get(member,[])) if member else 0
        candidates.append({'module':c.get('module'),'class':c.get('class'),'member':member,
                           'historical_script_mentions':uses,'status':'unreviewed_candidate'})
    candidates.sort(key=lambda x:(-x['historical_script_mentions'],str(x['module']),str(x['member'])))
    results.append({'from':t['from'],'to':t['to'],'source_path_counts':dict(counts),
                    'content_patch':str(patch) if patch else None,
                    'patch_present':patch.is_file() if patch else False,
                    'candidate_count':len(candidates),'candidates':candidates})
out=Path(args.output); out.parent.mkdir(parents=True,exist_ok=True)
out.write_text(json.dumps({'scope':'Changed modules intersected with historical-vs-imported lexical candidates and script mentions; this does not prove the candidate changed in the transition or that it breaks compatibility.',
                           'transitions':results},ensure_ascii=False,indent=2),encoding='utf-8')
print(f'Wrote {len(results)} transition inventories to {out}')
print(f"Available content patches: {sum(x['patch_present'] for x in results)}/{len(results)}")
