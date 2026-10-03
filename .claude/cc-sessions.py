#!/usr/bin/env python3
"""Liste les sessions Claude Code d'un projet : UUID, nom, branche, date, taille.

Usage:
  cc-sessions.py                 # projet = dossier courant
  cc-sessions.py /chemin/projet  # projet explicite
  cc-sessions.py --all           # tous les projets
  cc-sessions.py --json          # sortie JSON
"""
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

CONFIG_DIR = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude"))
PROJECTS = CONFIG_DIR / "projects"
UUID_RE = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.I)
NAME_KEYS = ("sessionName", "customName", "name", "title", "sessionTitle", "summary")


def slug(path: str) -> str:
    return re.sub(r"[^a-zA-Z0-9]", "-", str(Path(path).resolve()))


def flatten(content):
    """Le contenu d'un message peut être une string ou une liste de blocs."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(b.get("text", "") for b in content if isinstance(b, dict))
    return ""


def read_meta(jsonl: Path) -> dict:
    """Le format JSONL est interne à Claude Code : on cherche plusieurs clés
    et on retombe sur le premier prompt utilisateur si rien n'est trouvé."""
    name, branch, first_prompt = None, None, None
    with jsonl.open(encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not isinstance(rec, dict):
                continue
            for key in NAME_KEYS:
                val = rec.get(key)
                if isinstance(val, str) and val.strip():
                    name = val.strip()  # la dernière valeur gagne (/rename tardif)
                    break
            branch = rec.get("gitBranch") or branch
            if first_prompt is None and rec.get("type") == "user":
                msg = rec.get("message") or {}
                text = flatten(msg.get("content")).strip()
                if text and not text.startswith("<"):
                    first_prompt = text
    return {
        "session_id": jsonl.stem,
        "label": name or first_prompt or "—",
        "branch": branch or "",
        "mtime": jsonl.stat().st_mtime,
        "size_kb": round(jsonl.stat().st_size / 1024, 1),
        "path": str(jsonl),
    }


def collect(project_dirs):
    out = []
    for d in project_dirs:
        for f in d.glob("*.jsonl"):
            if UUID_RE.match(f.stem):
                meta = read_meta(f)
                meta["project"] = d.name
                out.append(meta)
    return sorted(out, key=lambda m: m["mtime"], reverse=True)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = {a for a in sys.argv[1:] if a.startswith("--")}

    if not PROJECTS.is_dir():
        sys.exit(f"Introuvable : {PROJECTS} (vérifie CLAUDE_CONFIG_DIR)")

    if "--all" in flags:
        dirs = [d for d in PROJECTS.iterdir() if d.is_dir()]
    else:
        target = PROJECTS / slug(args[0] if args else os.getcwd())
        if not target.is_dir():
            sys.exit(f"Aucune session pour ce projet ({target.name})")
        dirs = [target]

    rows = collect(dirs)
    if "--json" in flags:
        print(json.dumps(rows, indent=2, ensure_ascii=False))
        return

    if not rows:
        print("Aucune session trouvée.")
        return

    width = 58
    print(f"{'SESSION ID':38} {'NOM / TITRE':{width}} {'BRANCHE':18} {'MODIFIÉ':16} TAILLE")
    print("-" * (38 + width + 45))
    for r in rows:
        label = " ".join(r["label"].split())
        if len(label) > width:
            label = label[: width - 1] + "…"
        when = datetime.fromtimestamp(r["mtime"]).strftime("%Y-%m-%d %H:%M")
        print(f"{r['session_id']:38} {label:{width}} {r['branch'][:18]:18} {when:16} {r['size_kb']} Ko")
    print(f"\n{len(rows)} session(s) — reprise : claude --resume <SESSION ID>")


if __name__ == "__main__":
    main()
