import os
from flask import Flask, jsonify
from dotenv import load_dotenv
from flask_cors import CORS
import requests
import urllib.parse
import traceback

# Cargar variables de entorno desde el archivo .env
load_dotenv()

app = Flask(__name__)
CORS(app)

# Integración con Riot API usando variables de entorno
RIOT_API_KEY = os.getenv('RIOT_API_KEY')
HEADERS = {"X-Riot-Token": RIOT_API_KEY}

REGION_ACCOUNT = "americas"
REGION_LOL = "la1"

@app.route('/api/player/<game_name>/<tag_line>', methods=['GET'])
def get_player_data(game_name, tag_line):
    try:
        # --- LIMPIEZA DE CARACTERES ---
        invisible_chars = ['\u2066', '\u2069', '\u200b', '\u200c', '\u200d', '\ufeff', '\xa0']
        for char in invisible_chars:
            game_name = game_name.replace(char, '')
            tag_line = tag_line.replace(char, '')

        safe_name = urllib.parse.quote(game_name.strip())
        safe_tag = urllib.parse.quote(tag_line.strip())

        # --- PASO 1: OBTENER PUUID (ACCOUNT-V1) ---
        url_acc = f"https://{REGION_ACCOUNT}.api.riotgames.com/riot/account/v1/accounts/by-riot-id/{safe_name}/{safe_tag}"
        res_acc = requests.get(url_acc, headers=HEADERS)
        if res_acc.status_code != 200:
            return jsonify({"error": "Cuenta no encontrada"}), 404
        
        acc_data = res_acc.json()
        puuid = acc_data.get('puuid')

        # --- PASO 2: DATOS DE INVOCADOR (SUMMONER-V4) ---
        url_summ = f"https://{REGION_LOL}.api.riotgames.com/lol/summoner/v4/summoners/by-puuid/{puuid}"
        res_summ = requests.get(url_summ, headers=HEADERS)
        summ_data = res_summ.json()

        # --- PASO 3: RANGO ACTUAL (LEAGUE-V4 USANDO PUUID) ---
        url_rank = f"https://{REGION_LOL}.api.riotgames.com/lol/league/v4/entries/by-puuid/{puuid}"
        res_rank = requests.get(url_rank, headers=HEADERS)
        
        tier, lp = "UNRANKED", 0
        if res_rank.status_code == 200:
            rank_json = res_rank.json()
            stats = next((q for q in rank_json if q['queueType'] == 'RANKED_SOLO_5x5'), 
                         next((q for q in rank_json if q['queueType'] == 'RANKED_FLEX_SR'), None))
            if stats:
                tier = f"{stats.get('tier')} {stats.get('rank')}"
                lp = stats.get('leaguePoints')

        # --- PASO 4: MAESTRÍA Y CAMPEÓN TOP ---
        top_champ = "Teemo"
        url_mast = f"https://{REGION_LOL}.api.riotgames.com/lol/champion-mastery/v4/champion-masteries/by-puuid/{puuid}"
        res_mast = requests.get(url_mast, headers=HEADERS)
        if res_mast.status_code == 200 and res_mast.json():
            champ_id = res_mast.json()[0]['championId']
            dd = requests.get("https://ddragon.leagueoflegends.com/cdn/14.8.1/data/es_MX/champion.json").json()
            for name, d in dd['data'].items():
                if d['key'] == str(champ_id):
                    top_champ = name
                    break

        return jsonify({
            "gameName": acc_data.get('gameName'),
            "tagLine": acc_data.get('tagLine'),
            "summonerLevel": summ_data.get('summonerLevel'),
            "profileIconId": summ_data.get('profileIconId'),
            "tier": tier,
            "leaguePoints": lp,
            "topChampion": top_champ
        }), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)