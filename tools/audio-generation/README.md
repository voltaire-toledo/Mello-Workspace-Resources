# Voice Announcement Generation

The generator creates exactly 48 deterministic half-hour announcements from `manifest.json` (`Time_00_00.mp3` through `Time_23_30.mp3`). Voice, rate, volume, schedule, and phrase templates are manifest-driven and noninteractive.

```powershell
python -m venv tools/audio-generation/.venv
tools/audio-generation/.venv/Scripts/pip install -r tools/audio-generation/requirements.txt
tools/audio-generation/.venv/Scripts/python tools/audio-generation/generate_time_announcements.py --validate-only
tools/audio-generation/.venv/Scripts/python tools/audio-generation/generate_time_announcements.py --output-dir dist/generated-audio
```

Generation requires network access. Edge TTS is an unofficial client of a variable online service: voices, pronunciation, output bytes, throttling, and availability can change. Existing committed MP3 assets remain the reproducible inputs for routine offline DLL builds.
