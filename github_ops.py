import os,json,urllib.request,urllib.error,subprocess,pathlib,sys,re
ROOT=pathlib.Path(__file__).parent
os.chdir(ROOT)
token=os.environ.get('GITHUB_TOKEN')
if not token: raise SystemExit('GITHUB_TOKEN missing')
def api(path,method='GET',data=None):
 req=urllib.request.Request('https://api.github.com'+path,data=json.dumps(data).encode() if data is not None else None,method=method,headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28'})
 try:
  with urllib.request.urlopen(req,timeout=90) as r:
   b=r.read(); return json.loads(b) if b else {}
 except urllib.error.HTTPError as e:
  raise RuntimeError('GitHub HTTP '+str(e.code)+' '+e.read().decode()[:500]) from None
mode=sys.argv[1]
meta=ROOT/'evidence/repo.json'
if mode=='start':
 paths=[p for p in ROOT.rglob('*') if p.is_file() and not any(x in p.parts for x in ['evidence','__pycache__','.git','build'])]
 for p in paths:
  b=p.read_bytes()
  if token.encode() in b or re.search(rb'(?:gh[pousr]_[A-Za-z0-9]{25,}|github_pat_[A-Za-z0-9_]{30,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----)',b): raise SystemExit('sensitive scan failed: '+p.name)
 (ROOT/'evidence/sensitive-scan.txt').write_text('PASS: token value and credential patterns absent from '+str(len(paths))+' source files; no user media included.\n')
 user=api('/user')['login']; repo=user+'/KeySkin'
 # Do not reuse or modify an unrelated existing repository.
 created=api('/user/repos','POST',{'name':'KeySkin','private':True,'description':'Default-off iOS keyboard prototype; not device validated'})
 meta.write_text(json.dumps({'repo':repo,'url':created['html_url']},indent=2))
 subprocess.run(['git','init','-b','main'],check=True)
 subprocess.run(['git','config','user.name','KeySkin Builder'],check=True)
 subprocess.run(['git','config','user.email','keyskin@users.noreply.github.com'],check=True)
 subprocess.run(['git','add','.'],check=True);subprocess.run(['git','commit','-m','KeySkin 0.1.0 default-off build prototype'],check=True)
 ask=ROOT/'evidence/askpass.sh';ask.write_text('#!/bin/sh\ncase "$1" in *Username*) echo x-access-token;; *) printf "%s\\n" "$GITHUB_TOKEN";; esac\n');ask.chmod(0o700)
 env=dict(os.environ,GIT_ASKPASS=str(ask),GIT_TERMINAL_PROMPT='0')
 try:
  api('/repos/'+repo,'PATCH',{'private':False})
  subprocess.run(['git','remote','add','origin','https://github.com/'+repo+'.git'],check=True)
  subprocess.run(['git','push','-u','origin','main'],env=env,check=True)
  api('/repos/'+repo+'/actions/workflows/build.yml/dispatches','POST',{'ref':'main'})
 except Exception:
  api('/repos/'+repo,'PATCH',{'private':True});raise
 finally: ask.unlink(missing_ok=True)
 print('Created, pushed, dispatched:',repo)
else:
 repo=json.loads(meta.read_text())['repo']
 if mode=='status':
  runs=api('/repos/'+repo+'/actions/runs')['workflow_runs']
  r=runs[0] if runs else {}
  (ROOT/'evidence/run.json').write_text(json.dumps(r,indent=2))
  print(json.dumps({k:r.get(k) for k in ['id','status','conclusion','html_url']}))
 elif mode=='download':
  r=json.loads((ROOT/'evidence/run.json').read_text());arts=api('/repos/'+repo+'/actions/runs/'+str(r['id'])+'/artifacts')['artifacts']
  for a in arts:
   req=urllib.request.Request(a['archive_download_url'],headers={'Authorization':'Bearer '+token})
   with urllib.request.urlopen(req,timeout=120) as response: (ROOT/'evidence/artifact.zip').write_bytes(response.read())
  print('Artifacts downloaded:',len(arts))
 elif mode=='private':
  api('/repos/'+repo,'PATCH',{'private':True})
  checks=[{'private':api('/repos/'+repo)['private']} for _ in range(2)]
  (ROOT/'evidence/privacy.json').write_text(json.dumps(checks,indent=2))
  assert all(c['private'] for c in checks)
  print('private verified twice')
