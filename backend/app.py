import os
from flask import Flask, jsonify
from dotenv import load_dotenv
from flask_cors import CORS
import requests
import urllib.parse
import traceback

load_dotenv()

app = Flask(__name__)
CORS(app)

RIOT_API_KEY = os.getenv('RIOT_API_KEY')
HEADERS = {"X-Riot-Token": RIOT_API_KEY}

REGION_ACCOUNT = "americas"
REGION_LOL = "la1"

try:
    LATEST_PATCH = requests.get("https://ddragon.leagueoflegends.com/api/versions.json").json()[0]
except:
    LATEST_PATCH = "14.10.1"

SPELLS_MAP = {
    21: "SummonerBarrier", 1: "SummonerBoost", 14: "SummonerDot",
    3: "SummonerExhaust", 4: "SummonerFlash", 6: "SummonerHaste",
    7: "SummonerHeal", 13: "SummonerMana", 11: "SummonerSmite",
    12: "SummonerTeleport", 32: "SummonerSnowball", 
    2202: "SummonerCherryFlash", 2201: "SummonerCherryHold"
}

RUNES_MAP = {}
def load_runes():
    if not RUNES_MAP:
        try:
            req = requests.get(f"https://ddragon.leagueoflegends.com/cdn/{LATEST_PATCH}/data/es_MX/runesReforged.json")
            for tree in req.json():
                RUNES_MAP[tree['id']] = tree['icon'] 
                for slot in tree['slots']:
                    for rune in slot['runes']:
                        RUNES_MAP[rune['id']] = rune['icon'] 
        except Exception as e:
            print(f"Error cargando runas: {e}")

@app.route('/api/player/<game_name>/<tag_line>', methods=['GET'])
def get_player_data(game_name, tag_line):
    try:
        load_runes() 
        
        invisible_chars = ['\u2066', '\u2069', '\u200b', '\u200c', '\u200d', '\ufeff', '\xa0']
        for char in invisible_chars:
            game_name = game_name.replace(char, '')
            tag_line = tag_line.replace(char, '')

        safe_name = urllib.parse.quote(game_name.strip())
        safe_tag = urllib.parse.quote(tag_line.strip())

        url_acc = f"https://{REGION_ACCOUNT}.api.riotgames.com/riot/account/v1/accounts/by-riot-id/{safe_name}/{safe_tag}"
        res_acc = requests.get(url_acc, headers=HEADERS)
        if res_acc.status_code != 200:
            return jsonify({"error": "Cuenta no encontrada"}), 404
        acc_data = res_acc.json()
        puuid = acc_data.get('puuid')

        url_summ = f"https://{REGION_LOL}.api.riotgames.com/lol/summoner/v4/summoners/by-puuid/{puuid}"
        summ_data = requests.get(url_summ, headers=HEADERS).json()

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

        top_champ = "Teemo"
        url_mast = f"https://{REGION_LOL}.api.riotgames.com/lol/champion-mastery/v4/champion-masteries/by-puuid/{puuid}"
        res_mast = requests.get(url_mast, headers=HEADERS)
        if res_mast.status_code == 200 and res_mast.json():
            champ_id = res_mast.json()[0]['championId']
            dd = requests.get(f"https://ddragon.leagueoflegends.com/cdn/{LATEST_PATCH}/data/es_MX/champion.json").json()
            for name, d in dd['data'].items():
                if d['key'] == str(champ_id):
                    top_champ = name
                    break

        match_history = []
        url_matches = f"https://{REGION_ACCOUNT}.api.riotgames.com/lol/match/v5/matches/by-puuid/{puuid}/ids?start=0&count=10"
        res_matches = requests.get(url_matches, headers=HEADERS)
        
        if res_matches.status_code == 200:
            for m_id in res_matches.json():
                res_detail = requests.get(f"https://{REGION_ACCOUNT}.api.riotgames.com/lol/match/v5/matches/{m_id}", headers=HEADERS)
                if res_detail.status_code == 200:
                    data = res_detail.json()
                    participants = data['info']['participants']
                    player = next(p for p in participants if p['puuid'] == puuid)
                    
                    try:
                        primary_style = player['perks']['styles'][0]
                        secondary_style = player['perks']['styles'][1]
                        
                        primary_keystone_id = primary_style['selections'][0]['perk']
                        primary_rune1_id = primary_style['selections'][1]['perk']
                        primary_rune2_id = primary_style['selections'][2]['perk']
                        primary_rune3_id = primary_style['selections'][3]['perk']
                        
                        secondary_style_id = secondary_style['style']
                        secondary_rune1_id = secondary_style['selections'][0]['perk']
                        secondary_rune2_id = secondary_style['selections'][1]['perk']
                    except (KeyError, IndexError):
                        primary_keystone_id, primary_rune1_id, primary_rune2_id, primary_rune3_id = 8112, 8143, 8138, 8105
                        secondary_style_id, secondary_rune1_id, secondary_rune2_id = 8100, 8106, 8105
                    
                    match_history.append({
                        "win": player.get('win', False),
                        "championId": player.get('championId', 1),
                        "championName": player.get('championName', 'Unknown'),
                        "champLevel": player.get('champLevel', 1),
                        "kills": player.get('kills', 0),
                        "deaths": player.get('deaths', 0),
                        "assists": player.get('assists', 0),
                        "teamKills": sum(p['kills'] for p in participants if p['teamId'] == player['teamId']),
                        "totalCs": player.get('totalMinionsKilled', 0) + player.get('neutralMinionsKilled', 0),
                        "gameDuration": data['info']['gameDuration'],
                        "goldEarned": player.get('goldEarned', 0),
                        "visionScore": player.get('visionScore', 0),
                        
                        "spell1Name": SPELLS_MAP.get(player.get('summoner1Id'), "SummonerFlash"),
                        "spell2Name": SPELLS_MAP.get(player.get('summoner2Id'), "SummonerFlash"),
                    
                        "primaryKeystoneIcon": RUNES_MAP.get(primary_keystone_id, "perk-images/Styles/7200_Resolve.png"),
                        "primaryRune1Icon": RUNES_MAP.get(primary_rune1_id, "perk-images/Styles/7200_Resolve.png"),
                        "primaryRune2Icon": RUNES_MAP.get(primary_rune2_id, "perk-images/Styles/7200_Resolve.png"),
                        "primaryRune3Icon": RUNES_MAP.get(primary_rune3_id, "perk-images/Styles/7200_Resolve.png"),
                        
                        "secondaryStyleIcon": RUNES_MAP.get(secondary_style_id, "perk-images/Styles/7200_Resolve.png"),
                        "secondaryRune1Icon": RUNES_MAP.get(secondary_rune1_id, "perk-images/Styles/7200_Resolve.png"),
                        "secondaryRune2Icon": RUNES_MAP.get(secondary_rune2_id, "perk-images/Styles/7200_Resolve.png"),
                        
                        "item0": player.get('item0', 0), "item1": player.get('item1', 0),
                        "item2": player.get('item2', 0), "item3": player.get('item3', 0),
                        "item4": player.get('item4', 0), "item5": player.get('item5', 0),
                        "item6": player.get('item6', 0),
                    })

        return jsonify({
            "latestPatch": LATEST_PATCH, 
            "gameName": acc_data.get('gameName'), "tagLine": acc_data.get('tagLine'),
            "summonerLevel": summ_data.get('summonerLevel'), "profileIconId": summ_data.get('profileIconId'),
            "tier": tier, "leaguePoints": lp, "topChampion": top_champ,
            "matchHistory": match_history
        }), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)