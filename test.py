import asyncio, random, sys
import threading, time


HOST, PORT = '127.0.0.1', 8080
CONCURRENCY = 10000
INIT_TOTAL_TIME = 20
SLEEP = 0  # seconds
ITERATIONS = 2
MSG_SIZES = [16, 64, 256, 1024,
            #   16384,
             ]

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

class FlushBuffer:
    def write(self, data: str):
        # sys.stdout.buffer.write(data.encode('utf-8'))
        print(data, end='')

chars = list('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')

connection_counter = AtomicInteger()
fb = FlushBuffer()

gst = None
errc = 0

async def worker(id):
    await asyncio.sleep(id / CONCURRENCY * INIT_TOTAL_TIME)
    while True:
        try:
            reader, writer = await asyncio.open_connection(HOST, PORT)
            break
        except OSError:
            global errc
            errc += 1
            print(f'Worker {id} failed to connect, retrying ({errc} errors so far)...')
            await asyncio.sleep(0.1)
    v = connection_counter.increment()
    fb.write (f'Worker {id} connected, total connections: {v}\n')
    while connection_counter.get() < CONCURRENCY:
        await asyncio.sleep(0.1)
    
    global gst
    if gst is None:
        gst = time.time()

    # fb.write(f'Worker {id} starting echo test with {ITERATIONS} iterations\n')

    for it in range(ITERATIONS):
        size = random.choice(MSG_SIZES)
        msg = bytes(ord(chars[random.choice(range(len(chars)))]) for _ in range(size))
        writer.write(msg)
        await writer.drain()
        echo = await reader.readexactly(len(msg))
        if msg != echo:
            raise ValueError(f'Worker {id} received incorrect echo ({it} iteration): {msg} -> {echo}')
        # await asyncio.sleep(SLEEP)
        # fb.write(f'Worker {id} iteration {it + 1}/{ITERATIONS} completed\n')
    writer.close()
    # fb.write(f'Worker {id} closing connection\n')
    await writer.wait_closed()
    v = connection_counter.decrement()
    # fb.write(f'Worker {id} disconnected, total connections: {v}\n')

async def main():
    tasks = [asyncio.create_task(worker(i)) for i in range(CONCURRENCY)]
    await asyncio.gather(*tasks)

if __name__=='__main__':
    t = time.time()
    asyncio.run(main())
    elapsed = time.time() - t
    fb.write(f'\nAll workers completed in {elapsed:.2f} seconds\n')
    elapsed_gst = time.time() - gst
    fb.write(f'Total time from first worker start to last worker completion: {elapsed_gst:.2f} seconds\n')
    fb.write(f'::{elapsed},{elapsed_gst},{CONCURRENCY},{INIT_TOTAL_TIME},{ITERATIONS}\n')
