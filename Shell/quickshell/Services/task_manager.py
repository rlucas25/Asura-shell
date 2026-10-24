#!/usr/bin/env python3
"""
Task Manager for Quickshell
Handles atomic persistence of tasks, two-way synchronization with TODO.md
inside ~/.config/asura/data/, and external editor integration.
"""

import sys
import os
import json
import re
import time
import random
import hashlib
import subprocess
from datetime import datetime

CONFIG_DIR = os.path.expanduser("~/.config/asura/data")
TASKS_JSON = os.path.join(CONFIG_DIR, "tasks.json")
TODO_MD = os.path.join(CONFIG_DIR, "TODO.md")
HASH_FILE = os.path.join(CONFIG_DIR, ".todo_md_hash")

PRIORITY_WEIGHTS = {
    "high": 3,
    "medium": 2,
    "low": 1,
    "none": 0
}

MAIN_TASK_RE = re.compile(
    r"^[ \t]{0,1}[-*+]\s*\[([ xX])\]\s*(.*?)$"
)
SUBTASK_RE = re.compile(
    r"^[ \t]{2,}[-*+]\s*\[([ xX])\]\s*(.*?)$"
)
ID_COMMENT_RE = re.compile(r"<!--\s*id:\s*([^\s>]+)\s*-->")
META_PAREN_RE = re.compile(r"\*\((.*?)\)\*")


def ensure_dirs():
    os.makedirs(CONFIG_DIR, exist_ok=True)


def atomic_write(filepath: str, content: str):
    try:
        dir_name = os.path.dirname(filepath)
        os.makedirs(dir_name, exist_ok=True)
        tmp_file = filepath + ".tmp"
        with open(tmp_file, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(tmp_file, filepath)
    except Exception as e:
        sys.stderr.write(f"Error writing {filepath}: {e}\n")


def get_file_hash(filepath: str) -> str:
    if not os.path.exists(filepath):
        return ""
    try:
        with open(filepath, "rb") as f:
            return hashlib.sha256(f.read()).hexdigest()
    except Exception:
        return ""


def set_saved_hash(h: str):
    try:
        atomic_write(HASH_FILE, h)
    except Exception:
        pass


def get_saved_hash() -> str:
    if not os.path.exists(HASH_FILE):
        return ""
    try:
        with open(HASH_FILE, "r", encoding="utf-8") as f:
            return f.read().strip()
    except Exception:
        return ""


def generate_markdown(tasks: list) -> str:
    todo_list = []
    ongoing_list = []
    completed_list = []

    for t in tasks:
        is_done = t.get("done", False)
        col = t.get("column", "done" if is_done else "todo")
        if is_done or col == "done":
            completed_list.append(t)
        elif col == "ongoing":
            ongoing_list.append(t)
        else:
            todo_list.append(t)

    sort_key = lambda x: (
        -PRIORITY_WEIGHTS.get(x.get("priority", "none"), 0),
        x.get("date") or "9999-99-99",
        x.get("startTime") or "99:99"
    )
    todo_list.sort(key=sort_key)
    ongoing_list.sort(key=sort_key)

    now_str = datetime.now().strftime("%Y-%m-%d %H:%M")
    lines = [
        "# Asura Tasks & TODO",
        f"\n*Auto-synced with Asura Shell • Last updated: {now_str}*\n",
    ]

    def render_section(title, emoji, items, empty_msg, is_done_section=False):
        lines.append(f"## {emoji} {title} ({len(items)})\n")
        if items:
            for t in items:
                task_id = t.get("id")
                id_comment = f" <!-- id: {task_id} -->" if task_id else ""
                check = "x" if (is_done_section or t.get("done", False)) else " "

                p = t.get("priority", "none")
                p_badge = ""
                if not is_done_section:
                    if p == "high":
                        p_badge = "[HIGH] "
                    elif p == "medium":
                        p_badge = "[MED] "
                    elif p == "low":
                        p_badge = "[LOW] "

                meta_parts = []
                if t.get("date"):
                    meta_parts.append(t["date"])
                if t.get("startTime"):
                    time_range = t["startTime"]
                    if t.get("endTime"):
                        time_range += f" - {t['endTime']}"
                    meta_parts.append(time_range)

                meta = f" *({' • '.join(meta_parts)})*" if meta_parts else ""
                lines.append(f"- [{check}] {p_badge}{t.get('text', '')}{meta}{id_comment}")

                for st in t.get("subtasks", []):
                    st_id = st.get("id")
                    st_id_comment = f" <!-- id: {st_id} -->" if st_id else ""
                    st_check = "x" if (is_done_section or st.get("done")) else " "
                    lines.append(f"  - [{st_check}] {st.get('text', '')}{st_id_comment}")
        else:
            lines.append(f"_{empty_msg}_\n")
        lines.append("")

    render_section("To Do", "📋", todo_list, "No to-do tasks.")
    render_section("Ongoing", "⏳", ongoing_list, "No ongoing tasks.")
    render_section("Completed", "✅", completed_list, "No completed tasks.", is_done_section=True)

    return "\n".join(lines).strip() + "\n"


def deduplicate_subtask_ids(tasks: list) -> list:
    seen = set()
    for t in tasks:
        for st in t.get("subtasks", []):
            sid = st.get("id")
            if not sid or str(sid) in seen:
                while True:
                    cand = int(time.time() * 1000000) + random.randint(100, 999)
                    if str(cand) not in seen:
                        st["id"] = cand
                        break
            seen.add(str(st.get("id")))
    return tasks


def parse_markdown(content: str, existing_tasks: list) -> list:
    by_id = {str(t.get("id")): t for t in existing_tasks if "id" in t}
    by_text = {}
    for t in existing_tasks:
        txt = t.get("text", "").strip().lower()
        if txt and txt not in by_text:
            by_text[txt] = t

    lines = content.split("\n")
    current_section = "todo"
    tasks = []
    current_task = None
    current_parent_subtasks = []
    seen_subtask_ids = set()

    for t in existing_tasks:
        for st in t.get("subtasks", []):
            sid = st.get("id")
            if sid:
                seen_subtask_ids.add(str(sid))

    for line in lines:
        sline = line.strip()
        if not sline:
            continue

        if sline.startswith("##"):
            lower = sline.lower()
            if "ongoing" in lower or "progress" in lower:
                current_section = "ongoing"
            elif "completed" in lower or "done" in lower:
                current_section = "done"
            elif "to do" in lower or "pending" in lower:
                current_section = "todo"
            current_task = None
            current_parent_subtasks = []
            continue

        # Subtask check (indented by 2+ spaces or tabs)
        st_m = SUBTASK_RE.match(line)
        if st_m and current_task is not None:
            st_done = st_m.group(1).lower() == "x"
            rest = st_m.group(2).strip()

            st_id_m = ID_COMMENT_RE.search(rest)
            st_id = st_id_m.group(1) if st_id_m else None
            st_clean = ID_COMMENT_RE.sub("", rest).strip()

            if not st_id:
                for est in current_parent_subtasks:
                    if est.get("text", "").strip().lower() == st_clean.lower():
                        cand_id = est.get("id")
                        if cand_id and str(cand_id) not in seen_subtask_ids:
                            st_id = cand_id
                            break

            if st_id and str(st_id) in seen_subtask_ids:
                st_id = None

            if not st_id:
                while True:
                    cand = int(time.time() * 1000000) + random.randint(100, 999)
                    if str(cand) not in seen_subtask_ids:
                        st_id = cand
                        break

            seen_subtask_ids.add(str(st_id))

            subtask_obj = {
                "id": int(st_id) if (st_id and str(st_id).isdigit()) else st_id,
                "text": st_clean,
                "done": st_done
            }
            current_task["subtasks"].append(subtask_obj)
            continue

        # Main task check
        m = MAIN_TASK_RE.match(line)
        if m:
            is_done = m.group(1).lower() == "x"
            rest = m.group(2).strip()

            tid_m = ID_COMMENT_RE.search(rest)
            tid = tid_m.group(1) if tid_m else None
            rest = ID_COMMENT_RE.sub("", rest).strip()

            meta_m = META_PAREN_RE.search(rest)
            meta = meta_m.group(1) if meta_m else ""
            clean_text = META_PAREN_RE.sub("", rest).strip()

            # Priority extraction
            p = "none"
            if "🔴" in clean_text or "[HIGH]" in clean_text.upper() or "#high" in clean_text.lower():
                p = "high"
            elif "🟡" in clean_text or "[MED]" in clean_text.upper() or "[MEDIUM]" in clean_text.upper() or "#medium" in clean_text.lower():
                p = "medium"
            elif "🟢" in clean_text or "[LOW]" in clean_text.upper() or "#low" in clean_text.lower():
                p = "low"

            # Strip priority badges from clean_text
            clean_text = re.sub(r"[🔴🟡🟢]\s*", "", clean_text)
            clean_text = re.sub(r"\[(HIGH|MED|LOW|MEDIUM)\]\s*", "", clean_text, flags=re.IGNORECASE).strip()
            clean_text = re.sub(r"#(?:high|med|medium|low)\b", "", clean_text, flags=re.IGNORECASE).strip()

            # Date and time extraction
            date_m = re.search(r"\b(\d{4}-\d{2}-\d{2})\b", meta)
            time_m = re.search(r"\b(\d{1,2}:\d{2})\s*(?:-\s*(\d{1,2}:\d{2}))?\b", meta)

            d = date_m.group(1) if date_m else ""
            st = time_m.group(1) if time_m else ""
            et = time_m.group(2) if (time_m and time_m.group(2)) else ""

            # Base object resolution
            base = None
            if tid and str(tid) in by_id:
                base = dict(by_id[str(tid)])
            elif clean_text.lower() in by_text:
                base = dict(by_text[clean_text.lower()])
            else:
                base = {
                    "id": int(time.time() * 1000) + random.randint(1, 999),
                    "notify": False,
                    "notified": False,
                    "createdAt": datetime.now().strftime("%I:%M %p")
                }

            if is_done:
                final_done = True
                final_col = "done"
            else:
                final_done = False
                if current_section == "ongoing":
                    final_col = "ongoing"
                else:
                    final_col = "todo"

            base["text"] = clean_text
            base["done"] = final_done
            base["column"] = final_col
            base["priority"] = p
            base["date"] = d
            base["startTime"] = st
            base["endTime"] = et
            current_parent_subtasks = list(base.get("subtasks", []))
            base["subtasks"] = []

            tasks.append(base)
            current_task = base

    # Sync parent done status with subtasks if all are done
    for t in tasks:
        subs = t.get("subtasks", [])
        if subs and not t["done"]:
            if all(s.get("done") for s in subs):
                t["done"] = True
                t["column"] = "done"

    return tasks


def cmd_save():
    ensure_dirs()
    try:
        if len(sys.argv) > 2:
            raw_data = sys.argv[2]
        else:
            raw_data = sys.stdin.read()

        tasks = json.loads(raw_data)
        if not isinstance(tasks, list):
            tasks = []
        tasks = deduplicate_subtask_ids(tasks)
    except Exception as e:
        sys.stderr.write(f"Failed to parse tasks input: {e}\n")
        print(json.dumps({"status": "error", "message": str(e)}))
        return

    # 1. Save tasks.json
    json_str = json.dumps(tasks, indent=4, ensure_ascii=False)
    atomic_write(TASKS_JSON, json_str)

    # 2. Save TODO.md in ~/.config/asura/data/
    md_content = generate_markdown(tasks)
    atomic_write(TODO_MD, md_content)

    # 3. Update hash so watcher knows this write was internal
    new_hash = hashlib.sha256(md_content.encode("utf-8")).hexdigest()
    set_saved_hash(new_hash)

    print(json.dumps({"status": "ok", "count": len(tasks)}))


def cmd_sync_from_md():
    ensure_dirs()
    if not os.path.exists(TODO_MD):
        cmd_load()
        return

    try:
        with open(TODO_MD, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        sys.stderr.write(f"Failed to read {TODO_MD}: {e}\n")
        cmd_load()
        return

    current_hash = hashlib.sha256(content.encode("utf-8")).hexdigest()
    saved_hash = get_saved_hash()

    if current_hash == saved_hash and os.path.exists(TASKS_JSON):
        print(json.dumps({"status": "unchanged"}))
        return

    existing_tasks = []
    if os.path.exists(TASKS_JSON):
        try:
            with open(TASKS_JSON, "r", encoding="utf-8") as f:
                existing_tasks = json.load(f)
                if not isinstance(existing_tasks, list):
                    existing_tasks = []
        except Exception:
            existing_tasks = []

    merged_tasks = parse_markdown(content, existing_tasks)

    # 1. Save tasks.json
    json_str = json.dumps(merged_tasks, indent=4, ensure_ascii=False)
    atomic_write(TASKS_JSON, json_str)

    # 2. Re-write TODO.md with normalized formatting and IDs
    clean_md = generate_markdown(merged_tasks)
    atomic_write(TODO_MD, clean_md)

    # 3. Update hash
    new_hash = hashlib.sha256(clean_md.encode("utf-8")).hexdigest()
    set_saved_hash(new_hash)

    # 4. Output the merged tasks JSON for QML
    print(json.dumps(merged_tasks, ensure_ascii=False))


def cmd_load():
    ensure_dirs()
    if not os.path.exists(TASKS_JSON) and os.path.exists(TODO_MD):
        cmd_sync_from_md()
        return

    if not os.path.exists(TASKS_JSON):
        print("[]")
        return

    # If TODO.md exists and was modified offline, sync it
    if os.path.exists(TODO_MD):
        try:
            md_mtime = os.path.getmtime(TODO_MD)
            json_mtime = os.path.getmtime(TASKS_JSON)
            cur_hash = get_file_hash(TODO_MD)
            saved_hash = get_saved_hash()
            if md_mtime > json_mtime and cur_hash != saved_hash:
                cmd_sync_from_md()
                return
        except Exception:
            pass

    try:
        with open(TASKS_JSON, "r", encoding="utf-8") as f:
            content = f.read()
            json.loads(content)
            print(content)
    except Exception as e:
        sys.stderr.write(f"Failed to load tasks: {e}\n")
        print("[]")


def cmd_open():
    ensure_dirs()
    target = TODO_MD if os.path.exists(TODO_MD) else TASKS_JSON
    try:
        subprocess.Popen(["xdg-open", target])
        print(json.dumps({"status": "ok", "opened": target}))
    except Exception as e:
        sys.stderr.write(f"Failed to open {target}: {e}\n")
        print(json.dumps({"status": "error", "message": str(e)}))


def main():
    if len(sys.argv) < 2:
        cmd_load()
        return

    action = sys.argv[1]
    if action == "save":
        cmd_save()
    elif action == "load":
        cmd_load()
    elif action in ("sync-from-md", "sync_from_md", "sync"):
        cmd_sync_from_md()
    elif action == "open":
        cmd_open()
    else:
        sys.stderr.write(f"Unknown action: {action}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
