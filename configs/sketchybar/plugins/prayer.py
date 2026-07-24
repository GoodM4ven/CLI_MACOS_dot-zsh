#!/usr/bin/env python3
import datetime
import json
import os
import urllib.parse
import urllib.request
from zoneinfo import ZoneInfo

CITY = "Al Majmaah"
COUNTRY = "Saudi Arabia"
METHOD = 4
TZ = ZoneInfo("Asia/Riyadh")
ORDER = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
ARABIC_NAMES = {
    "Fajr": "الفجر",
    "Dhuhr": "الظهر",
    "Asr": "العصر",
    "Maghrib": "المغرب",
    "Isha": "العشاء",
}
CACHE_PATH = os.path.expanduser("~/.cache/sketchybar/prayer.json")


def fetch(date_str):
    url = (
        f"https://api.aladhan.com/v1/timingsByCity/{date_str}"
        f"?city={urllib.parse.quote(CITY)}&country={urllib.parse.quote(COUNTRY)}&method={METHOD}"
    )
    with urllib.request.urlopen(url, timeout=5) as r:
        timings = json.load(r)["data"]["timings"]
    return {name: timings[name].split()[0] for name in ORDER}


def load_cache():
    try:
        with open(CACHE_PATH) as f:
            return json.load(f)
    except Exception:
        return {}


def save_cache(cache):
    os.makedirs(os.path.dirname(CACHE_PATH), exist_ok=True)
    with open(CACHE_PATH, "w") as f:
        json.dump(cache, f)


def find_cached(cache, date_str):
    for entry in cache.values():
        if isinstance(entry, dict) and entry.get("date") == date_str:
            return entry["timings"]
    return None


def ensure(cache, date_str, key):
    timings = find_cached(cache, date_str)
    if timings:
        cache[key] = {"date": date_str, "timings": timings}
        return timings
    try:
        timings = fetch(date_str)
        cache[key] = {"date": date_str, "timings": timings}
        save_cache(cache)
        return timings
    except Exception:
        entry = cache.get(key)
        return entry["timings"] if entry else None


def main():
    now = datetime.datetime.now(TZ)
    today_str = now.strftime("%d-%m-%Y")
    tomorrow_str = (now + datetime.timedelta(days=1)).strftime("%d-%m-%Y")

    cache = load_cache()

    today_timings = ensure(cache, today_str, "today")
    if today_timings is None:
        print("--:--|--")
        return

    next_name = None
    next_dt = None
    for name in ORDER:
        hour, minute = map(int, today_timings[name].split(":"))
        candidate = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
        if candidate > now:
            next_name, next_dt = name, candidate
            break

    if next_name is None:
        tomorrow_timings = ensure(cache, tomorrow_str, "tomorrow")
        if tomorrow_timings is None:
            print("--:--|--")
            return
        hour, minute = map(int, tomorrow_timings["Fajr"].split(":"))
        next_name = "Fajr"
        next_dt = (now + datetime.timedelta(days=1)).replace(
            hour=hour, minute=minute, second=0, microsecond=0
        )

    total_minutes = int((next_dt - now).total_seconds() // 60)
    hours, minutes = divmod(total_minutes, 60)
    print(f"{hours}:{minutes:02d}|{ARABIC_NAMES[next_name]}")


if __name__ == "__main__":
    main()
