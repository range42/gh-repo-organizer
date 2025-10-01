#!/usr/bin/env python3
"""
make_for_ai_contexts.py
Reads analysis/files/* and analysis/metadata/*.yaml and creates analysis/for_ai/<repo>_context.txt
"""

import os, json, yaml, re, datetime, textwrap

BASE = "analysis"
FILES_DIR = os.path.join(BASE, "files")
META_DIR = os.path.join(BASE, "metadata")
OUT_DIR = os.path.join(BASE, "for_ai")
os.makedirs(OUT_DIR, exist_ok=True)

MAX_CHARS = 16000
README_SNIPPET = 3500
FILE_LIST_LINES = 200
BANDIT_TOP = 5

# simple sanitizer
SECRET_RE = re.compile(r'(?i)(aws[_-]?secret[_-]?access[_-]?key|aws[_-]?secret|api[_-]?key|token|password|secret|private_key)\s*[:=]\s*("?)[^\s"]+("? )?')

def redact(text):
    redactions = []
    def _repl(m):
        redactions.append(m.group(0))
        return m.group(0).split('=')[0] + "= [REDACTED]"
    out = SECRET_RE.sub(_repl, text)
    return out, redactions

def safe_read(path, max_chars=None):
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            s = f.read()
            if max_chars and len(s) > max_chars:
                return s[:max_chars] + "\n...[truncated]"
            return s
    except Exception:
        return ""

def summarize_pip_audit(path):
    try:
        j = json.load(open(path, 'r'))
    except Exception:
        return ""
    # flexible shape
    if isinstance(j, dict):
        # pip-audit style: list of vulnerabilities maybe under 'vulnerabilities' or just list
        vulns = j.get("vulnerabilities") or j.get("vulns") or j.get("results") or []
        if isinstance(vulns, dict):
            # fallback
            total = len(vulns)
            return f"pip-audit: {total} findings (raw format)."
        # compute counts by severity if present
        counts = {"HIGH":0,"MEDIUM":0,"LOW":0}
        top = []
        for v in vulns[:10]:
            pkg = v.get("package") or v.get("name") or v.get("dependency") or {}
            name = pkg.get("name") if isinstance(pkg, dict) else pkg
            sev = v.get("severity","UNKNOWN").upper()
            counts.setdefault(sev,0)
            if sev in counts:
                counts[sev]+=1
            top.append(f"{name} ({sev})")
        return f"Total findings: {len(vulns)}; counts={counts}; top_examples={top[:3]}"
    return ""

def summarize_npm_audit(path):
    try:
        j = json.load(open(path, 'r'))
    except Exception:
        return ""
    # npm audit v2 format includes metadata.vulnerabilities counts
    meta = j.get("metadata") or j.get("advisories") or {}
    counts = {}
    if "vulnerabilities" in meta:
        counts = meta["vulnerabilities"]
    elif isinstance(meta, dict):
        # older
        counts = {k:str(v) for k,v in meta.items() if k in ("critical","high","moderate","low")}
    # try to list top advisories
    advs = []
    if "advisories" in j and isinstance(j["advisories"], dict):
        for aid, adv in list(j["advisories"].items())[:3]:
            advs.append(f"{adv.get('module_name')} ({adv.get('severity')})")
    return f"npm audit counts={counts}; top_advisories={advs}"

def summarize_bandit(path):
    try:
        j = json.load(open(path, 'r'))
    except Exception:
        return ""
    results = j.get("results", [])
    total = len(results)
    # sort by severity mapping
    sev_order = {"HIGH":3,"MEDIUM":2,"LOW":1}
    def score(it):
        s = it.get("issue_severity","LOW").upper()
        return sev_order.get(s,0), it.get("issue_confidence",0)
    results_sorted = sorted(results, key=score, reverse=True)
    top = []
    for r in results_sorted[:BANDIT_TOP]:
        top.append(f"{r.get('filename')}:{r.get('line_number')} {r.get('test_name')} [{r.get('issue_severity')}] - {r.get('issue_text')[:200]}")
    return f"bandit_total={total}; top_issues={top}"

def make_one(repo):
    repo_files_dir = os.path.join(FILES_DIR, repo)
    meta_path = os.path.join(META_DIR, f"{repo}.yaml")
    out_path = os.path.join(OUT_DIR, f"{repo}_context.txt")
    parts = []
    # header
    header = {"repo_name": repo}
    if os.path.exists(meta_path):
        try:
            with open(meta_path,'r') as f:
                my = yaml.safe_load(f)
            # select up to 8 useful keys
            keep = {k: my.get(k) for k in ("last_commit","commits","main_branch","owner","description") if k in my}
            header.update(keep)
        except Exception:
            pass
    parts.append("--- REPO HEADER ---\n" + yaml.safe_dump(header, default_flow_style=False))
    # one-line summary (autogen)
    one_line = f"{repo} — files: {len(os.listdir(repo_files_dir)) if os.path.isdir(repo_files_dir) else 0}; generated: {datetime.datetime.utcnow().isoformat()}Z"
    parts.append("--- ONE-LINE SUMMARY (AUTOGEN) ---\n" + one_line)
    # README
    readme_path = None
    for possible in ("README.md","README.rst","readme.md"):
        p = os.path.join(repo_files_dir, possible)
        if os.path.exists(p):
            readme_path = p
            break
    if readme_path:
        rd = safe_read(readme_path, README_SNIPPET)
        rd_s, red = redact(rd)
        parts.append(f"--- README (first {README_SNIPPET} chars) ---\n{rd_s}")
    else:
        parts.append("--- README (first 3500 chars) ---\n[NO README FOUND]")
    # file_list
    fl = safe_read(os.path.join(repo_files_dir,"file_list.txt"))
    if fl:
        lines = fl.splitlines()[:FILE_LIST_LINES]
        parts.append(f"--- FILE LIST (first {FILE_LIST_LINES} lines) ---\n" + "\n".join(lines))
    # important files present
    found = []
    for fn in os.listdir(repo_files_dir):
        found.append(fn)
    parts.append("--- IMPORTANT FILES FOUND ---\n" + "\n".join(sorted(found)[:50]))
    # dependency scan summaries
    pip_path = os.path.join(repo_files_dir,"pip_audit.json")
    if os.path.exists(pip_path):
        parts.append("--- DEPENDENCY / SCA SCANS SUMMARY (pip_audit) ---\n" + summarize_pip_audit(pip_path))
    safety_path = os.path.join(repo_files_dir,"safety.json")
    if os.path.exists(safety_path):
        parts.append("--- DEPENDENCY / SCA SCANS SUMMARY (safety) ---\n" + summarize_pip_audit(safety_path))
    npm_path = os.path.join(repo_files_dir,"npm_audit.json")
    if os.path.exists(npm_path):
        parts.append("--- DEPENDENCY / SCA SCANS SUMMARY (npm_audit) ---\n" + summarize_npm_audit(npm_path))
    # bandit
    bandit_path = os.path.join(repo_files_dir,"bandit_report.json")
    if os.path.exists(bandit_path):
        parts.append("--- BANDIT SUMMARY ---\n" + summarize_bandit(bandit_path))
    # CI / workflows
    workfiles = [f for f in os.listdir(repo_files_dir) if f.startswith(".github") or f.endswith(".yml") or f.endswith(".yaml")]
    if workfiles:
        parts.append("--- CI / WORKFLOWS ---\n" + "\n".join(workfiles))
    # sanitization log (minimal)
    parts.append("--- SANITIZATION LOG ---\n" + "Redaction performed for common secret patterns (see script).")
    # footer
    parts.append("--- CONTEXT FOOTER ---\nGenerated at: " + datetime.datetime.utcnow().isoformat() + "Z\nEstimated_chars_limit=" + str(MAX_CHARS))
    content = "\n\n".join(parts)
    # final truncation
    if len(content) > MAX_CHARS:
        content = content[:MAX_CHARS-200] + "\n\n...[TRUNCATED for token budget]"
    with open(out_path,'w',encoding='utf-8') as f:
        f.write(content)
    print("Wrote", out_path)

if __name__ == "__main__":
    repos = sorted([d for d in os.listdir(FILES_DIR) if os.path.isdir(os.path.join(FILES_DIR,d))])
    for r in repos:
        try:
            make_one(r)
        except Exception as e:
            print("ERR", r, e)
