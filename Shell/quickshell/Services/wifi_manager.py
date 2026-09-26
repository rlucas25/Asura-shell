#!/usr/bin/env python3
import sys
import subprocess
import json
import re

def run_cmd(cmd):
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        return res.returncode, res.stdout.strip(), res.stderr.strip()
    except subprocess.TimeoutExpired:
        return -1, "", "Command timed out"
    except Exception as e:
        return -1, "", str(e)

def get_wifi_interface():
    code, out, _ = run_cmd(['nmcli', '-t', '-f', 'DEVICE,TYPE', 'dev'])
    if code == 0:
        for line in out.splitlines():
            parts = line.strip().split(':')
            if len(parts) >= 2 and parts[1] == 'wifi':
                return parts[0]
    return 'wlan0'

def get_ip_address(iface):
    if not iface:
        return ""
    code, out, _ = run_cmd(['nmcli', '-t', '-f', 'IP4.ADDRESS', 'dev', 'show', iface])
    if code == 0:
        for line in out.splitlines():
            if line.startswith('IP4.ADDRESS'):
                parts = line.split(':')
                if len(parts) >= 2:
                    return parts[1].split('/')[0].strip()
    return ""

def get_ethernet_info():
    code, out, _ = run_cmd(['nmcli', '-t', '-f', 'DEVICE,TYPE,STATE,CONNECTION', 'dev'])
    if code == 0:
        for line in out.splitlines():
            parts = line.strip().split(':')
            if len(parts) >= 3 and parts[1] == 'ethernet' and parts[2] == 'connected':
                dev = parts[0]
                conn_name = parts[3] if len(parts) > 3 and parts[3] else "Conexão Cabeada"
                ip_addr = get_ip_address(dev)
                return {
                    'connected': True,
                    'name': conn_name,
                    'iface': dev,
                    'ip': ip_addr
                }
    return {
        'connected': False,
        'name': '',
        'iface': '',
        'ip': ''
    }

def get_status():
    ethernet_info = get_ethernet_info()

    code, out_radio, _ = run_cmd(['nmcli', 'radio', 'wifi'])
    wifi_enabled = (code == 0 and out_radio.lower() == 'enabled')

    iface = get_wifi_interface()
    ip_addr = get_ip_address(iface)

    if not wifi_enabled:
        return {
            'enabled': False,
            'active': None,
            'networks': [],
            'iface': iface,
            'ip': '',
            'ethernet': ethernet_info
        }

    # Saved connections
    code, out_saved, _ = run_cmd(['nmcli', '-t', '-f', 'NAME,TYPE', 'connection', 'show'])
    saved_set = set()
    if code == 0:
        for line in out_saved.splitlines():
            if ':802-11-wireless' in line:
                parts = line.split(':')
                saved_set.add(parts[0])

    # Available networks
    code, out_nets, _ = run_cmd(['nmcli', '-t', '-f', 'IN-USE,SSID,SIGNAL,SECURITY,BSSID,FREQ,BARS', 'dev', 'wifi', 'list'])
    
    seen = {}
    active_net = None

    if code == 0:
        for line in out_nets.splitlines():
            if not line:
                continue
            parts = re.split(r'(?<!\\):', line)
            if len(parts) >= 6:
                in_use = parts[0].strip() == '*'
                ssid = parts[1].replace(r'\:', ':').strip()
                signal = int(parts[2]) if parts[2].isdigit() else 0
                security = parts[3].replace(r'\:', ':').strip()
                bssid = parts[4].replace(r'\:', ':').strip()
                freq = parts[5].replace(r'\:', ':').strip()
                bars = parts[6].replace(r'\:', ':').strip() if len(parts) > 6 else ""

                if not ssid:
                    continue  # skip unnamed APs without SSID

                is_saved = ssid in saved_set
                is_secure = bool(security and security != '--')

                band = "5 GHz" if ("5" in freq or (freq.replace(" MHz", "").isdigit() and int(freq.replace(" MHz", "")) > 4000)) else "2.4 GHz"

                entry = {
                    'ssid': ssid,
                    'signal': signal,
                    'security': security,
                    'secure': is_secure,
                    'bssid': bssid,
                    'freq': freq,
                    'band': band,
                    'bars': bars,
                    'active': in_use,
                    'saved': is_saved
                }

                if in_use:
                    active_net = entry
                    entry['ip'] = ip_addr

                if ssid not in seen:
                    seen[ssid] = entry
                else:
                    if in_use or (not seen[ssid]['active'] and signal > seen[ssid]['signal']):
                        seen[ssid] = entry

    net_list = list(seen.values())
    net_list.sort(key=lambda x: (not x['active'], not x['saved'], -x['signal'], x['ssid'].lower()))

    if active_net and ip_addr:
        active_net['ip'] = ip_addr

    return {
        'enabled': True,
        'active': active_net,
        'networks': net_list,
        'iface': iface,
        'ip': ip_addr,
        'ethernet': ethernet_info
    }

def set_wifi_radio(state):
    action = 'on' if state else 'off'
    code, out, err = run_cmd(['nmcli', 'radio', 'wifi', action])
    return {
        'success': code == 0,
        'message': out if code == 0 else err,
        'enabled': state
    }

def connect_wifi(ssid, password=None, is_hidden=False):
    if not ssid:
        return {'success': False, 'message': 'SSID não informado.'}

    cmd = ['nmcli', 'dev', 'wifi', 'connect', ssid]
    if password:
        cmd.extend(['password', password])
    if is_hidden:
        cmd.extend(['hidden', 'yes'])

    code, out, err = run_cmd(cmd)
    success = (code == 0)
    msg = out if success else (err or "Falha ao conectar à rede Wi-Fi.")
    return {
        'success': success,
        'message': msg,
        'ssid': ssid
    }

def disconnect_wifi():
    iface = get_wifi_interface()
    code, out, err = run_cmd(['nmcli', 'dev', 'disconnect', iface])
    success = (code == 0)
    return {
        'success': success,
        'message': out if success else (err or "Falha ao desconectar."),
    }

def forget_wifi(ssid):
    if not ssid:
        return {'success': False, 'message': 'SSID não informado.'}
    code, out, err = run_cmd(['nmcli', 'connection', 'delete', 'id', ssid])
    success = (code == 0)
    return {
        'success': success,
        'message': out if success else (err or f"Falha ao esquecer {ssid}."),
        'ssid': ssid
    }

def rescan_wifi():
    run_cmd(['nmcli', 'dev', 'wifi', 'rescan'])
    return get_status()

def main():
    if len(sys.argv) < 2 or sys.argv[1] == 'status':
        print(json.dumps(get_status()))
        return

    cmd = sys.argv[1].lower()
    
    if cmd == 'on':
        print(json.dumps(set_wifi_radio(True)))
    elif cmd == 'off':
        print(json.dumps(set_wifi_radio(False)))
    elif cmd == 'rescan' or cmd == 'scan':
        print(json.dumps(rescan_wifi()))
    elif cmd == 'disconnect':
        print(json.dumps(disconnect_wifi()))
    elif cmd == 'forget':
        if len(sys.argv) > 2:
            ssid = sys.argv[2]
            print(json.dumps(forget_wifi(ssid)))
        else:
            print(json.dumps({'success': False, 'message': 'Nome da rede obrigatório.'}))
    elif cmd == 'connect':
        if len(sys.argv) > 2:
            ssid = sys.argv[2]
            password = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] != "" else None
            is_hidden = len(sys.argv) > 4 and sys.argv[4].lower() in ['true', 'yes', '1', 'hidden']
            print(json.dumps(connect_wifi(ssid, password, is_hidden)))
        else:
            print(json.dumps({'success': False, 'message': 'Nome da rede obrigatório.'}))
    else:
        print(json.dumps({'error': f'Comando desconhecido: {cmd}'}))

if __name__ == '__main__':
    main()
