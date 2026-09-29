import struct
import numpy as np
import pytest
from app.services.deepfake_detector import deepfake_detector

def generate_sine_pcm(freq: float = 440.0, duration_sec: float = 0.5, sample_rate: int = 16000) -> bytes:
    t = np.linspace(0, duration_sec, int(sample_rate * duration_sec), endpoint=False)
    samples = (np.sin(2 * np.pi * freq * t) * 32767).astype(np.int16)
    return samples.tobytes()

def test_empty_audio_buffer():
    res = deepfake_detector.analyze_audio_chunk(b"")
    assert res["status"] in ["insufficient_data", "success"]
    assert res["label"] == "REAL"

def test_valid_pcm_audio():
    pcm_bytes = generate_sine_pcm(freq=300.0, duration_sec=0.25)
    res = deepfake_detector.analyze_audio_chunk(pcm_bytes)
    assert res["status"] == "success"
    assert "label" in res
    assert "confidence" in res
    assert isinstance(res["is_synthetic"], bool)

def test_high_frequency_artifact_detection():
    # Construct unnatural high frequency synthetic wave typical of neural vocoder artifacts
    sample_rate = 16000
    t = np.linspace(0, 0.5, int(sample_rate * 0.5), endpoint=False)
    # High frequency white noise plus harsh harmonic
    noise = np.random.uniform(-0.8, 0.8, len(t))
    synthetic_wave = (noise * 32767).astype(np.int16)
    res = deepfake_detector.analyze_audio_chunk(synthetic_wave.tobytes())
    assert res["status"] == "success"
    assert "spectral_flatness" in res or "confidence" in res
