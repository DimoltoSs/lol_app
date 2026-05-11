from flask import Flask, jsonify
from flask_cors import CORS
import requests
import urllib.parse
import traceback

app = Flask(__name__)
CORS(app)
# Riot API Integration.
RIOT_API_KEY = ''
HEADERS = {"X-Riot-Token": RIOT_API_KEY}

REGION_ACCOUNT = "americas"
REGION_LOL = "la1"

@app.route('/api/player/<game_name>/<tag_line>', methods=['GET'])
def get_player_data(game_name, tag_line):
    try:
        invisible_chars = ['\u2066', '\u2069', '\u200b', '\u200c', '\u200d', '\ufeff', '\xa0']
        for char in invisible_chars:
            game_name = game_name.replace(char, '')
            tag_line = tag_line.replace(char, '')

        game_name = game_name.strip()
        tag_line = tag_line.strip()

        safe_game_name = urllib.parse.quote(game_name)
        safe_tag_line = urllib.parse.quote(tag_line)

        url_account = f"https://{REGION_ACCOUNT}.api.riotgames.com/riot/account/v1/accounts/by-riot-id/{safe_game_name}/{safe_tag_line}"
        res_account = requests.get(url_account, headers=HEADERS)
        
        if res_account.status_code != 200:
            return jsonify({"error": "Jugador no encontrado"}), 404
            
        account_data = res_account.json()
        puuid = account_data.get('puuid')

        url_summoner = f"https://{REGION_LOL}.api.riotgames.com/lol/summoner/v4/summoners/by-puuid/{puuid}"
        res_summoner = requests.get(url_summoner, headers=HEADERS)
        
        if res_summoner.status_code != 200:
             return jsonify({"error": "No se encontro el perfil de invocador"}), 404

        summoner_data = res_summoner.json()
        encrypted_summoner_id = summoner_data.get('id')

        url_ranked = f"https://{REGION_LOL}.api.riotgames.com/lol/league/v4/entries/by-summoner/{encrypted_summoner_id}"
        res_ranked = requests.get(url_ranked, headers=HEADERS)
        
        tier = "UNRANKED"
        league_points = 0
        
        print(f"\n--- DEBUG RANGO ---")
        print(f"Status Code Riot: {res_ranked.status_code}")
        print(f"Datos recibidos: {res_ranked.text}")
        print(f"-------------------\n")
        
        if res_ranked.status_code == 200:
            ranked_data = res_ranked.json()
            for queue in ranked_data:
                if queue.get('queueType') == "RANKED_SOLO_5x5":
                    tier = f"{queue.get('tier', 'UNRANKED')} {queue.get('rank', '')}".strip()
                    league_points = queue.get('leaguePoints', 0)
                    break

        top_champion_name = "Teemo"
        try:
            url_mastery = f"https://{REGION_LOL}.api.riotgames.com/lol/champion-mastery/v4/champion-masteries/by-puuid/{puuid}"
            res_mastery = requests.get(url_mastery, headers=HEADERS)
            
            if res_mastery.status_code == 200:
                masteries = res_mastery.json()
                if masteries and len(masteries) > 0:
                    top_champ_id = masteries[0]['championId']
                    dd_url = "https://ddragon.leagueoflegends.com/cdn/14.8.1/data/es_MX/champion.json"
                    dd_res = requests.get(dd_url).json()
                    for name, data in dd_res['data'].items():
                        if data['key'] == str(top_champ_id):
                            top_champion_name = name
                            break
        except:
            pass

        final_response = {
            "gameName": account_data.get('gameName', game_name),
            "tagLine": account_data.get('tagLine', tag_line),
            "summonerLevel": summoner_data.get('summonerLevel', 0),
            "profileIconId": summoner_data.get('profileIconId', 1),
            "tier": tier,
            "leaguePoints": league_points,
            "topChampion": top_champion_name
        }
        
        return jsonify(final_response), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": "Error interno del servidor"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)