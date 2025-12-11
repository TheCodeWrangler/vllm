from openai import OpenAI
import time

client = OpenAI(base_url="http://localhost:8000/v1", api_key="sk-test")

# audio_path = "sixty_sec.mp3"
audio_path = "thirty_sec.mp3"
model = "openai/whisper-large-v3"
for _ in range(3):
    start_time = time.time()
    # do a transcription
    with open(audio_path, "rb") as f:
        response = client.audio.transcriptions.create(
            model=model,
            file=f,
            extra_body={"use_beam_search": False},
            language="en",
        )
    end_time = time.time()
    print(f"Time taken: {end_time - start_time} seconds")
    print(response.text)

for beam_width in [2, 4, 8]:
    start_time = time.time()
    with open(audio_path, "rb") as f:
        response = client.audio.transcriptions.create(
            model=model,
            file=f,
            extra_body={"use_beam_search": True, "beam_width": beam_width},
            language="en",
        )
        end_time = time.time()
        print(f"BEAM {beam_width} Time taken: {end_time - start_time} seconds")
        print(response.text)