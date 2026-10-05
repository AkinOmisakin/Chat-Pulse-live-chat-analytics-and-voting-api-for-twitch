import asyncio
import os

import redis.asyncio as redis


async def main() -> None:
    r = redis.from_url(os.environ.get("REDIS_URL", "redis://localhost:6379/0"))
    await r.ping()
    print("chat-worker started, connected to Redis", flush=True)

    # Placeholder loop: episode 2 replaces this with the Twitch IRC connection
    while True:
        await asyncio.sleep(60)


if __name__ == "__main__":
    asyncio.run(main())