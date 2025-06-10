import asyncio, random
import threading


HOST, PORT = '127.0.0.1', 8080
CONCURRENCY = 10000
SLEEP = 0.1  # seconds
ITERATIONS = 1000
MSG_SIZES = [16, 64, 256, 1024, 16384]

class AtomicInteger:
    def __init__(self, initial: int = 0):
        self._value = initial
        self._lock  = threading.Lock()

    def increment(self) -> int:
        """Atomically add 1, return new value."""
        with self._lock:
            self._value += 1
            return self._value

    def decrement(self) -> int:
        """Atomically subtract 1, return new value."""
        with self._lock:
            self._value -= 1
            return self._value

    def get(self) -> int:
        """Atomically read the current value."""
        with self._lock:
            return self._value

connection_counter = AtomicInteger()

async def worker(id):
    await asyncio.sleep(random.random() * 20)
    reader, writer = await asyncio.open_connection(HOST, PORT)
    v = connection_counter.increment()
    print (f'Worker {id} connected, total connections: {v}')
    while connection_counter.get() < CONCURRENCY:
        await asyncio.sleep(1)

    print(f'Worker {id} starting echo test with {ITERATIONS} iterations')

    for _ in range(ITERATIONS):
        size = random.choice(MSG_SIZES)
        msg = bytes(random.getrandbits(8) for _ in range(size)) + b'\n'
        writer.write(msg)
        await writer.drain()
        echo = await reader.readexactly(len(msg))
        if msg != echo:
            raise ValueError(f'Worker {id} received incorrect echo: {msg} -> {echo}')
        await asyncio.sleep(SLEEP)
    writer.close()
    await writer.wait_closed()
    v = connection_counter.decrement()
    print(f'Worker {id} disconnected, total connections: {v}')

async def main():
    tasks = [asyncio.create_task(worker(i)) for i in range(CONCURRENCY)]
    await asyncio.gather(*tasks)

if __name__=='__main__':
    asyncio.run(main())
