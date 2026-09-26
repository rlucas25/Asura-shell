#!/usr/bin/env python3
import sys
import os
import subprocess
import json
import re

VOL_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "app_volumes.json")

def load_saved_volumes():
    if os.path.exists(VOL_FILE):
        try:
            with open(VOL_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {"volumes": {}, "mutes": {}}

def save_app_volume(app_key, vol, muted=None):
    if not app_key:
        return
    data = load_saved_volumes()
    if "volumes" not in data or not isinstance(data["volumes"], dict):
        data["volumes"] = {}
    data["volumes"][app_key] = vol
    if muted is not None:
        if "mutes" not in data or not isinstance(data["mutes"], dict):
            data["mutes"] = {}
        data["mutes"][app_key] = muted
    try:
        with open(VOL_FILE, "w") as f:
            json.dump(data, f, indent=2)
    except Exception:
        pass

def run_cmd(cmd):
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        return res.returncode, res.stdout.strip(), res.stderr.strip()
    except Exception as e:
        return -1, "", str(e)

def get_app_icon(name):
    lower = name.lower()
    if 'spotify' in lower:
        return "󰓇"
    if 'firefox' in lower:
        return "󰈹"
    if 'chrome' in lower or 'chromium' in lower or 'brave' in lower or 'vivaldi' in lower:
        return "󰊯"
    if 'discord' in lower or 'vesktop' in lower or 'webcord' in lower:
        return "󰙯"
    if 'vlc' in lower or 'mpv' in lower or 'video' in lower:
        return "󰕼"
    if 'telegram' in lower:
        return "󰔁"
    if 'steam' in lower or 'game' in lower or 'terraria' in lower or 'minecraft' in lower:
        return "󰊴"
    if 'obs' in lower:
        return "󰑋"
    return "󰓃"

def get_audio_info():
    code, out_vol, _ = run_cmd(['wpctl', 'get-volume', '@DEFAULT_AUDIO_SINK@'])
    master_vol = 70
    master_muted = False
    if code == 0 and out_vol:
        m = re.search(r'Volume:\s*([\d.]+)', out_vol)
        if m:
            master_vol = round(float(m.group(1)) * 100)
        master_muted = '[MUTED]' in out_vol

    code, out_mic, _ = run_cmd(['wpctl', 'get-volume', '@DEFAULT_AUDIO_SOURCE@'])
    mic_vol = 80
    mic_muted = False
    if code == 0 and out_mic:
        m = re.search(r'Volume:\s*([\d.]+)', out_mic)
        if m:
            mic_vol = round(float(m.group(1)) * 100)
        mic_muted = '[MUTED]' in out_mic

    code, out_sinks, _ = run_cmd(['pactl', 'list', 'sink-inputs'])
    apps = []

    saved_data = load_saved_volumes()
    saved_vols = saved_data.get("volumes", {})
    saved_mutes = saved_data.get("mutes", {})

    if code == 0 and out_sinks:
        blocks = out_sinks.split('Sink Input #')
        for block in blocks:
            if not block.strip():
                continue
            lines = block.strip().splitlines()
            first_line = lines[0].strip()
            sink_id = first_line.split()[0] if first_line else ""
            if not sink_id.isdigit():
                continue

            app_name = ""
            binary_name = ""
            media_name = ""
            vol = 100
            muted = False

            for line in lines:
                line_str = line.strip()
                if line_str.startswith('application.name ='):
                    m_name = re.search(r'=\s*"(.*)"', line_str)
                    if m_name and m_name.group(1):
                        app_name = m_name.group(1)
                elif line_str.startswith('application.process.binary ='):
                    m_bin = re.search(r'=\s*"(.*)"', line_str)
                    if m_bin and m_bin.group(1):
                        binary_name = m_bin.group(1)
                elif line_str.startswith('media.name ='):
                    m_med = re.search(r'=\s*"(.*)"', line_str)
                    if m_med and m_med.group(1):
                        media_name = m_med.group(1)
                elif line_str.startswith('Mute:'):
                    muted = 'yes' in line_str.lower()
                elif line_str.startswith('Volume:'):
                    m_vol = re.search(r'(\d+)%', line_str)
                    if m_vol:
                        vol = int(m_vol.group(1))

            final_name = app_name or binary_name or media_name or "Aplicativo"
            if "spotify" in final_name.lower() or "spotify" in binary_name.lower():
                final_name = "Spotify"

            app_key = final_name.lower().strip()

            if app_key in saved_vols:
                saved_vol = saved_vols[app_key]
                if abs(vol - saved_vol) > 1 and vol == 100:
                    run_cmd(['pactl', 'set-sink-input-volume', str(sink_id), f'{saved_vol}%'])
                    if 'spotify' in app_key:
                        run_cmd(['playerctl', '-p', 'spotify', 'volume', f'{saved_vol/100.0:.2f}'])
                    vol = saved_vol
                elif abs(vol - saved_vol) > 1 and vol != 100:
                    saved_vols[app_key] = vol
                    save_app_volume(app_key, vol)
            if app_key in saved_mutes:
                saved_mute = saved_mutes[app_key]
                if muted != saved_mute and 'spotify' in app_key:
                    run_cmd(['pactl', 'set-sink-input-mute', str(sink_id), '1' if saved_mute else '0'])
                    muted = saved_mute

            apps.append({
                'id': int(sink_id),
                'name': final_name,
                'icon': get_app_icon(final_name),
                'volume': vol,
                'muted': muted
            })

    return {
        'master': {
            'volume': master_vol,
            'muted': master_muted
        },
        'mic': {
            'volume': mic_vol,
            'muted': mic_muted
        },
        'apps': apps
    }

def main():
    if len(sys.argv) < 2 or sys.argv[1] == 'get':
        print(json.dumps(get_audio_info()))
        return

    cmd = sys.argv[1]

    if cmd == 'set-app' and len(sys.argv) >= 4:
        app_id = sys.argv[2]
        vol = max(0, min(150, int(sys.argv[3])))
        app_name = sys.argv[4] if len(sys.argv) > 4 else ""
        run_cmd(['pactl', 'set-sink-input-volume', str(app_id), f'{vol}%'])

        if not app_name:
            code, out_sinks, _ = run_cmd(['pactl', 'list', 'sink-inputs'])
            if code == 0 and out_sinks:
                blocks = out_sinks.split('Sink Input #')
                for block in blocks:
                    if block.strip().startswith(str(app_id)):
                        for line in block.splitlines():
                            l = line.strip()
                            if l.startswith('application.name ='):
                                m = re.search(r'=\s*"(.*)"', l)
                                if m:
                                    app_name = m.group(1)
                            elif l.startswith('application.process.binary =') and not app_name:
                                m = re.search(r'=\s*"(.*)"', l)
                                if m:
                                    app_name = m.group(1)

        if 'spotify' in app_name.lower():
            app_name = 'Spotify'
            run_cmd(['playerctl', '-p', 'spotify', 'volume', f'{vol/100.0:.2f}'])

        app_key = app_name.lower().strip()
        if app_key:
            save_app_volume(app_key, vol)

        print(json.dumps({'success': True}))

    elif cmd == 'mute-app' and len(sys.argv) >= 3:
        app_id = sys.argv[2]
        app_name = sys.argv[3] if len(sys.argv) > 3 else ""
        run_cmd(['pactl', 'set-sink-input-mute', str(app_id), 'toggle'])

        if not app_name:
            code, out_sinks, _ = run_cmd(['pactl', 'list', 'sink-inputs'])
            if code == 0 and out_sinks:
                blocks = out_sinks.split('Sink Input #')
                for block in blocks:
                    if block.strip().startswith(str(app_id)):
                        for line in block.splitlines():
                            l = line.strip()
                            if l.startswith('application.name ='):
                                m = re.search(r'=\s*"(.*)"', l)
                                if m:
                                    app_name = m.group(1)

        if 'spotify' in app_name.lower():
            app_name = 'Spotify'

        app_key = app_name.lower().strip()
        if app_key:
            saved_data = load_saved_volumes()
            curr_mute = saved_data.get("mutes", {}).get(app_key, False)
            save_app_volume(app_key, saved_data.get("volumes", {}).get(app_key, 100), not curr_mute)

        print(json.dumps({'success': True}))

    elif cmd == 'set-master' and len(sys.argv) >= 3:
        vol = max(0, min(100, int(sys.argv[2])))
        run_cmd(['wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', f'{vol/100:.2f}'])
        print(json.dumps({'success': True}))

    elif cmd == 'mute-master':
        run_cmd(['wpctl', 'set-mute', '@DEFAULT_AUDIO_SINK@', 'toggle'])
        print(json.dumps({'success': True}))

    elif cmd == 'set-mic' and len(sys.argv) >= 3:
        vol = max(0, min(100, int(sys.argv[2])))
        run_cmd(['wpctl', 'set-volume', '@DEFAULT_AUDIO_SOURCE@', f'{vol/100:.2f}'])
        print(json.dumps({'success': True}))

    elif cmd == 'mute-mic':
        run_cmd(['wpctl', 'set-mute', '@DEFAULT_AUDIO_SOURCE@', 'toggle'])
        print(json.dumps({'success': True}))

    else:
        print(json.dumps({'error': 'Comando inválido'}))

if __name__ == '__main__':
    main()
