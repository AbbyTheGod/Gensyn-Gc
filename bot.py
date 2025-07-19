import asyncio
import logging
import requests
from telegram import Bot

# === CONFIG ===
BOT_TOKEN = "7908799324:AAEEy9KP-42DjPIKPLIw5tUJET7UgvA6cUc"
CHANNEL_ID = "@galxealrets"
CHECK_INTERVAL = 60  # seconds
GALXE_PROJECTS = [
    "D3",
    "T-REXNetwork"
]

posted_links = set()
logging.basicConfig(level=logging.INFO)

# fetch latest quests from galxe using graphql api
def get_quests(project_name):
    url = "https://graphigo.prd.galxe.com/query"
    headers = {
        "content-type": "application/json",
        "origin": "https://app.galxe.com"
    }

    query = {
        "operationName": "workspaceQuests",
        "variables": {
            "id": project_name,
            "pagination": {
                "limit": 10,
                "page": 1
            }
        },
        "query": """
        query workspaceQuests($id: String!, $pagination: Pagination) {
            workspace(id: $id) {
                quests(pagination: $pagination) {
                    list {
                        id
                        title
                    }
                }
            }
        }
        """
    }

    response = requests.post(url, json=query, headers=headers).json()
    quests = []

    try:
        for quest in response['data']['workspace']['quests']['list']:
            quest_id = quest['id']
            title = quest['title']
            quest_url = f"https://app.galxe.com/quest/{project_name}/{quest_id}"
            quests.append((project_name, title, quest_url))
    except:
        pass

    return quests

# send to telegram
async def post(bot, project_name, title, quest_url):
    msg = f"<b>{project_name}</b>\n{title}\n{quest_url}"
    await bot.send_message(chat_id=CHANNEL_ID, text=msg, parse_mode="HTML", disable_web_page_preview=True)
    print(f"[✔] posted: {title}")

# main async loop
async def main():
    bot = Bot(token=BOT_TOKEN)

    while True:
        try:
            for project in GALXE_PROJECTS:
                print(f"[→] checking: {project}")
                quests = get_quests(project)
                for pname, title, url in quests:
                    if url not in posted_links:
                        await post(bot, pname, title, url)
                        posted_links.add(url)
        except Exception as e:
            logging.error(f"Error: {e}")

        await asyncio.sleep(CHECK_INTERVAL)

# run
if __name__ == "__main__":
    asyncio.run(main())
