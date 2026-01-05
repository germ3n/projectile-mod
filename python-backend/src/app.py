import sqlite3
import json
import os
import secrets
import requests
from flask import Flask, request, jsonify, redirect, url_for
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)

DB_PATH = 'database.db'

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    conn.execute('PRAGMA foreign_keys = ON')
    
    conn.execute('''
        CREATE TABLE IF NOT EXISTS configs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            submitter_steamid TEXT NOT NULL,
            config_name TEXT NOT NULL,
            config_flags INTEGER NOT NULL DEFAULT 0,
            config_data TEXT NOT NULL,
            config_version TEXT NOT NULL DEFAULT '1.0.0',
            thumbs_up INTEGER NOT NULL DEFAULT 0,
            thumbs_down INTEGER NOT NULL DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    conn.execute('''
        CREATE TABLE IF NOT EXISTS user_sessions (
            token TEXT PRIMARY KEY,
            steamid TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    conn.execute('''
        CREATE TABLE IF NOT EXISTS banned_users (
            steamid TEXT PRIMARY KEY,
            reason TEXT NOT NULL,
            banned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    conn.execute('CREATE INDEX IF NOT EXISTS idx_configs_steamid ON configs(submitter_steamid)')
    conn.execute('CREATE INDEX IF NOT EXISTS idx_sessions_steamid ON user_sessions(steamid)')
    
    conn.execute('''
        CREATE TABLE IF NOT EXISTS configs_update_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            config_id INTEGER NOT NULL,
            action TEXT NOT NULL CHECK(action IN ('CREATED', 'UPDATED', 'DELETED')),
            config_version TEXT NOT NULL,
            changes TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (config_id) REFERENCES configs(id) ON DELETE CASCADE
        )
    ''')
    
    conn.commit()
    conn.close()

init_db()

def get_steamid_from_token(token):
    if not token: return None
    conn = get_db_connection()
    row = conn.execute('''
        UPDATE user_sessions 
        SET last_active = CURRENT_TIMESTAMP 
        WHERE token = ? 
        RETURNING steamid
    ''', (token,)).fetchone()
    conn.commit()
    conn.close()
    return row['steamid'] if row else None

def is_banned(steamid):
    conn = get_db_connection()
    row = conn.execute('SELECT * FROM banned_users WHERE steamid = ?', (steamid,)).fetchone()
    conn.close()
    return row is not None
    if row:
        return True, row['reason'], row['expires_at']
    else:
        return False, None, None

@app.route('/auth/landing')
def auth_landing():
    """Serves a professional landing page for the Steam Overlay."""
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>ProjectileMod Login</title>
        <style>
            body { background: #1b2838; color: #c7d5e0; font-family: "Motiva Sans", Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
            .card { background: #2a475e; padding: 40px; border-radius: 4px; text-align: center; box-shadow: 0 10px 30px rgba(0,0,0,0.5); border: 1px solid #3d6b8d; max-width: 400px; }
            h2 { color: #fff; margin-top: 0; }
            p { line-height: 1.6; font-size: 14px; margin-bottom: 25px; }
            .btn-steam:hover { opacity: 0.8; }
            .btn-steam img { display: block; margin: 0 auto; border-radius: 4px; }
        </style>
    </head>
    <body>
        <div class="card">
            <h2>Authentication</h2>
            <p>To securely share and sync your ProjectileMod configurations, please sign in via Steam.</p>
            <a href="/auth/login" class="btn-steam">
                <img src="https://community.cloudflare.steamstatic.com/public/images/signinthroughsteam/sits_01.png" alt="Sign in through Steam">
            </a>
        </div>
    </body>
    </html>
    '''

@app.route('/auth/login')
def login():
    steam_openid_url = 'https://steamcommunity.com/openid/login'
    return_to = url_for('authorize', _external=True)
    
    params = {
        'openid.ns': 'http://specs.openid.net/auth/2.0',
        'openid.mode': 'checkid_setup',
        'openid.return_to': return_to,
        'openid.realm': return_to,
        'openid.identity': 'http://specs.openid.net/auth/2.0/identifier_select',
        'openid.claimed_id': 'http://specs.openid.net/auth/2.0/identifier_select'
    }
    query_string = '&'.join([f'{k}={v}' for k, v in params.items()])
    return redirect(f'{steam_openid_url}?{query_string}')

@app.route('/auth/authorize')
def authorize():
    params = request.args.to_dict()
    params['openid.mode'] = 'check_authentication'
    response = requests.post('https://steamcommunity.com/openid/login', data=params)
    
    if 'is_valid:true' in response.text:
        identity_url = request.args.get('openid.identity')
        if identity_url:
            steam_id = identity_url.split('/')[-1]
            token = secrets.token_hex(32)
            
            conn = get_db_connection()
            sessions = conn.execute(
                'SELECT token FROM user_sessions WHERE steamid = ? ORDER BY last_active DESC', 
                (steam_id,)
            ).fetchall()
            
            if len(sessions) >= 5:
                for idx, row in enumerate(sessions):
                    if idx >= 4:
                        conn.execute('DELETE FROM user_sessions WHERE token = ?', (row['token'],))

            conn.execute('INSERT INTO user_sessions (token, steamid) VALUES (?, ?)', (token, steam_id))
            conn.commit()
            conn.close()
            
            # If opened in Steam Overlay, we show a 'Success' page with the token to copy
            return f'''
            <html>
                <body style="background: #1b2838; color: white; font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh;">
                    <h2>Login Successful!</h2>
                    <p>Copy the code below if prompted in-game, otherwise you can close this window.</p>
                    <div style="background: #121a24; padding: 15px; border-radius: 4px; border: 1px solid #3d6b8d; font-family: monospace; font-size: 1.2em; color: #66c0f4;">{token}</div>
                    <script>
                        // Still try to notify the DHTML bridge if it's active
                        console.log("TOKEN_FOUND:{token}");
                    </script>
                </body>
            </html>
            '''
            
    return jsonify({"error": "Identity verification failed"}), 401

@app.route('/configs/search', methods=['GET'])
def search_configs():
    limit = request.args.get('limit', 10, type=int)
    sort_by = request.args.get('sort_by', 'date')
    order = request.args.get('order', 'desc').lower()

    sort_map = {'date': 'created_at', 'rating': 'rating', 'name': 'config_name'}
    column = sort_map.get(sort_by, 'created_at')
    direction = 'ASC' if order == 'asc' else 'DESC'

    conn = get_db_connection()
    query = f'SELECT * FROM configs ORDER BY {column} {direction} LIMIT ?'
    rows = conn.execute(query, (limit,)).fetchall()
    conn.close()

    result = []
    for idx, row in enumerate(rows):
        result.append({
            "id": row['id'],
            "steamid": row['submitter_steamid'],
            "name": row['config_name'],
            "flags": row['config_flags'],
            "version": row['config_version'],
            "rating": row['rating'],
            "config": json.loads(row['config_data']),
            "created_at": row['created_at']
        })
    return jsonify(result)

@app.route('/fetch-config/<int:config_id>', methods=['GET'])
def fetch_config(config_id):
    conn = get_db_connection()
    row = conn.execute('SELECT * FROM configs WHERE id = ?', (config_id,)).fetchone()
    conn.close()

    if not row:
        return jsonify({"error": "Config not found"}), 404

    return jsonify({
        "id": row['id'],
        "steamid": row['submitter_steamid'],
        "name": row['config_name'],
        "flags": row['config_flags'],
        "version": row['config_version'],
        "rating": row['rating'],
        "config": json.loads(row['config_data']),
        "created_at": row['created_at'],
        "updated_at": row['updated_at']
    })

@app.route('/upload-config', methods=['POST'])
def save_config():
    auth_header = request.headers.get('Authorization', '')
    token = auth_header.replace('Bearer ', '') if 'Bearer ' in auth_header else None
    
    verified_steamid = get_steamid_from_token(token)
    if not verified_steamid:
        return jsonify({"error": "Unauthorized"}), 401

    is_banned, reason, expires_at = is_banned(verified_steamid)
    if is_banned and expires_at and expires_at < datetime.now():
        return jsonify({"error": "You are banned from the server. Reason: " + reason}), 403

    data = request.get_json()
    if not data or 'config_name' not in data or 'config' not in data:
        return jsonify({"error": "Missing required fields"}), 400

    config_name = data['config_name']
    config_flags = data.get('flags', 0)
    version = data.get('version', '1.0.0')
    config_json = json.dumps(data['config'])

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('''
            INSERT INTO configs (submitter_steamid, config_name, config_flags, config_data, config_version) 
            VALUES (?, ?, ?, ?, ?)
        ''', (verified_steamid, config_name, config_flags, config_json, version))
        
        config_id = cursor.lastrowid
        cursor.execute('''
            INSERT INTO configs_update_log (config_id, action, config_version, changes) 
            VALUES (?, ?, ?, ?)
        ''', (config_id, 'CREATED', version, 'Initial creation'))
        conn.commit()
    except sqlite3.IntegrityError:
        return jsonify({"error": "Config name already exists"}), 409
    finally:
        conn.close()

    return jsonify({"message": "Config saved successfully", "id": config_id}), 201

@app.route('/update-config', methods=['POST'])
def update_config():
    auth_header = request.headers.get('Authorization', '')
    token = auth_header.replace('Bearer ', '') if 'Bearer ' in auth_header else None
    
    verified_steamid = get_steamid_from_token(token)
    if not verified_steamid:
        return jsonify({"error": "Unauthorized"}), 401

    is_banned, reason, expires_at = is_banned(verified_steamid)
    if is_banned and expires_at and expires_at < datetime.now():
        return jsonify({"error": "You are banned from the server. Reason: " + reason}), 403

    data = request.get_json()
    if not data or 'id' not in data or 'config' not in data:
        return jsonify({"error": "Missing required fields"}), 400

    config_id = data['id']
    conn = get_db_connection()
    cursor = conn.cursor()
    
    current = cursor.execute('SELECT submitter_steamid, config_version FROM configs WHERE id = ?', (config_id,)).fetchone()
    
    if not current:
        conn.close()
        return jsonify({"error": "Config not found"}), 404
        
    if current['submitter_steamid'] != verified_steamid:
        conn.close()
        return jsonify({"error": "You do not own this config"}), 403

    old_version = current['config_version']
    new_version = data.get('version', old_version)
    config_json = json.dumps(data['config'])
    flags = data.get('flags', 0)
    change_desc = f"Updated from {old_version}. Notes: {data.get('changes', 'No description provided')}"

    cursor.execute('''
        UPDATE configs 
        SET config_data = ?, config_version = ?, config_flags = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ''', (config_json, new_version, flags, config_id))

    cursor.execute('''
        INSERT INTO configs_update_log (config_id, action, config_version, changes) 
        VALUES (?, ?, ?, ?)
    ''', (config_id, 'UPDATED', new_version, change_desc))

    conn.commit()
    conn.close()
    
    return jsonify({
        "message": "Config updated successfully", 
        "old_version": old_version, 
        "new_version": new_version
    })

@app.route('/users/me', methods=['GET'])
def get_me():
    auth_header = request.headers.get('Authorization', '')
    token = auth_header.replace('Bearer ', '') if 'Bearer ' in auth_header else None
    
    steamid = get_steamid_from_token(token)
    if not steamid:
        return jsonify({"error": "Unauthorized"}), 401
        
    return jsonify({"steamid": steamid}), 200

if __name__ == '__main__':
    app.run(debug=True, port=8000)