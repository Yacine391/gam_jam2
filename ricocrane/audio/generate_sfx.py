import wave, struct, math, os, array

RATE = 44100

def write_wav(path: str, samples: list[float]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = array.array("h", [max(-32767, min(32767, int(s * 32767))) for s in samples])
    with wave.open(path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data.tobytes())

def sine(freq: float, dur: float, vol: float = 0.8, fade_out: bool = True) -> list[float]:
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        env = (1.0 - i / n) if fade_out else 1.0
        out.append(math.sin(2 * math.pi * freq * t) * vol * env)
    return out

def noise(dur: float, vol: float = 0.5) -> list[float]:
    import random
    n = int(RATE * dur)
    return [(random.random() * 2 - 1) * vol * (1 - i / n) for i in range(n)]

def sweep(f0: float, f1: float, dur: float, vol: float = 0.8) -> list[float]:
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        ratio = i / n
        freq = f0 + (f1 - f0) * ratio
        env = 1.0 - ratio * 0.5
        out.append(math.sin(2 * math.pi * freq * t) * vol * env)
    return out

def concat(*parts: list[float]) -> list[float]:
    result = []
    for p in parts:
        result.extend(p)
    return result

def mix(a: list[float], b: list[float]) -> list[float]:
    n = max(len(a), len(b))
    a += [0.0] * (n - len(a))
    b += [0.0] * (n - len(b))
    return [a[i] + b[i] for i in range(n)]

BASE = os.path.dirname(__file__)

# bonk — impact sourd + harmonique
bonk = mix(sine(120, 0.12, 0.9), sine(200, 0.08, 0.5))
write_wav(f"{BASE}/sfx/bonk.wav", bonk)

# perfect — ding brillant deux notes
perfect = concat(sine(880, 0.12, 0.7), sine(1320, 0.18, 0.8))
write_wav(f"{BASE}/sfx/perfect.wav", perfect)

# splash — bruit blanc court
splash = noise(0.22, 0.6)
write_wav(f"{BASE}/sfx/splash.wav", splash)

# combo_up — montée rapide
combo_up = sweep(400, 900, 0.18, 0.7)
write_wav(f"{BASE}/sfx/combo_up.wav", combo_up)

# combo_lost — descente rapide
combo_lost = sweep(600, 150, 0.22, 0.7)
write_wav(f"{BASE}/sfx/combo_lost.wav", combo_lost)

# game_over — trois notes descendantes
game_over = concat(sine(440, 0.18, 0.8), sine(330, 0.18, 0.8), sine(220, 0.32, 0.8))
write_wav(f"{BASE}/sfx/game_over.wav", game_over)

# theme — boucle chiptune simple (4 mesures)
def note(freq: float, dur: float) -> list[float]:
    return sine(freq, dur, 0.35, fade_out=False)

melody = [
    (523, 0.15), (659, 0.15), (784, 0.15), (1047, 0.15),
    (880, 0.15), (784, 0.15), (659, 0.30),
    (523, 0.15), (587, 0.15), (698, 0.15), (880, 0.15),
    (784, 0.15), (698, 0.15), (587, 0.30),
    (659, 0.15), (784, 0.15), (880, 0.15), (1047, 0.15),
    (988, 0.15), (880, 0.15), (784, 0.30),
    (523, 0.15), (659, 0.15), (523, 0.15), (440, 0.15),
    (494, 0.15), (523, 0.60),
]
theme = concat(*[note(f, d) for f, d in melody])
write_wav(f"{BASE}/music/theme.wav", theme)

print("Sons generes :")
for f in ["sfx/bonk.wav","sfx/perfect.wav","sfx/splash.wav",
          "sfx/combo_up.wav","sfx/combo_lost.wav","sfx/game_over.wav","music/theme.wav"]:
    path = f"{BASE}/{f}"
    size = os.path.getsize(path)
    print(f"  {f} ({size} bytes)")
