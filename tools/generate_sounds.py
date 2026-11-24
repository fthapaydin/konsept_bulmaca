#!/usr/bin/env python3
"""
Karehane — Özgün Oyun Ses Efektleri Üreteci.
Telifsiz, hafif, sıcak ahşap/marimba tonlu 8 adet WAV ses efekti üretir.
"""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets" / "sounds"
SAMPLE_RATE = 22050


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            clamped = max(-0.98, min(0.98, s))
            frames.extend(struct.pack("<h", int(clamped * 32767)))
        wf.writeframes(bytes(frames))


def marimba_note(freq: float, duration: float, volume: float = 0.55) -> list[float]:
    n = int(SAMPLE_RATE * duration)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        attack = min(1.0, t / 0.008)
        decay = math.exp(-t * (6.5 / max(0.08, duration)))
        env = attack * decay
        # Warm fundamental + gentle 2nd & 4th marimba harmonics
        val = (
            math.sin(2 * math.pi * freq * t) * 0.72
            + math.sin(2 * math.pi * freq * 2.0 * t) * 0.20 * math.exp(-t * 14)
            + math.sin(2 * math.pi * freq * 3.98 * t) * 0.08 * math.exp(-t * 24)
        )
        out.append(val * env * volume)
    return out


def mix_sequence(events: list[tuple[float, list[float]]]) -> list[float]:
    total_len = 0
    for start_sec, buf in events:
        end_idx = int(start_sec * SAMPLE_RATE) + len(buf)
        if end_idx > total_len:
            total_len = end_idx
    out = [0.0] * total_len
    for start_sec, buf in events:
        offset = int(start_sec * SAMPLE_RATE)
        for i, val in enumerate(buf):
            out[offset + i] += val
    # Soft peak normalization
    peak = max((abs(x) for x in out), default=1.0)
    if peak > 0.92:
        scale = 0.92 / peak
        out = [x * scale for x in out]
    return out


def main() -> None:
    # 1) tap.wav — yumuşak ahşap taş tıkırtısı
    write_wav(OUT_DIR / "tap.wav", marimba_note(620.0, 0.065, 0.35))

    # 2) backspace.wav — hafif tok silme sesi
    write_wav(OUT_DIR / "backspace.wav", marimba_note(310.0, 0.075, 0.32))

    # 3) word_ok.wav — sıcak yükselen 2 nota (C5 -> G5)
    write_wav(
        OUT_DIR / "word_ok.wav",
        mix_sequence([
            (0.00, marimba_note(523.25, 0.16, 0.48)),
            (0.08, marimba_note(783.99, 0.26, 0.55)),
        ]),
    )

    # 4) combo.wav — parlak yükselen 4 nota kombo arpeji (E5 -> G#5 -> B5 -> E6)
    write_wav(
        OUT_DIR / "combo.wav",
        mix_sequence([
            (0.00, marimba_note(659.25, 0.15, 0.45)),
            (0.065, marimba_note(830.61, 0.16, 0.50)),
            (0.13, marimba_note(987.77, 0.18, 0.55)),
            (0.195, marimba_note(1318.51, 0.34, 0.62)),
        ]),
    )

    # 5) hint.wav — zarif ipucu parıltısı (A5 -> C#6)
    write_wav(
        OUT_DIR / "hint.wav",
        mix_sequence([
            (0.00, marimba_note(880.0, 0.14, 0.40)),
            (0.07, marimba_note(1108.73, 0.28, 0.48)),
        ]),
    )

    # 6) victory.wav — neşeli zafer fanfarı (C5 -> E5 -> G5 -> C6 + akor)
    write_wav(
        OUT_DIR / "victory.wav",
        mix_sequence([
            (0.00, marimba_note(523.25, 0.18, 0.48)),
            (0.09, marimba_note(659.25, 0.18, 0.50)),
            (0.18, marimba_note(783.99, 0.20, 0.54)),
            (0.28, marimba_note(1046.50, 0.52, 0.64)),
            (0.28, marimba_note(523.25, 0.50, 0.32)),
            (0.28, marimba_note(783.99, 0.50, 0.32)),
        ]),
    )

    # 7) error.wav — nazik alçalan uyarı sesi
    write_wav(
        OUT_DIR / "error.wav",
        mix_sequence([
            (0.00, marimba_note(260.0, 0.12, 0.42)),
            (0.09, marimba_note(195.0, 0.18, 0.46)),
        ]),
    )

    # 8) tick.wav — Mini Sprint son 15 saniye saat tıkı
    write_wav(OUT_DIR / "tick.wav", marimba_note(960.0, 0.045, 0.28))

    print(f"[OK] 8 oyun ses efekti {OUT_DIR} içine oluşturuldu!")


if __name__ == "__main__":
    main()
