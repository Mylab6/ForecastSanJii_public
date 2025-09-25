

rob_lines = [
    "Zambra doovan morka bleet", "Klimpa grovan zekul trest", "Murga blint tok zarden",
    "Flarn zibbo jonti presk", "Vrol snafta kelbrin dorp", "Nerbin zartook grelm",
    "Foopla trang dozern keek", "Yabba storn glooba fest", "Chorta bleeb monska rint",
    "Dazzle grunty pef wamb", "Veklor strump jarnel teep", "Brosh glemor vanta fip",
    "Cloofa stroon yarble fen", "Wooka flebb snint groon", "Plarn zogtroff merst glib",
    "Zindle moorvak petch drob", "Krinta zuvorn glash meem", "Narp kelvin treb sarnak",
    "Dibber swoont flern jask", "Joova meck troont blen"
]

jim_lines = [
    "Woofta dreem blarn skizz", "Jokka fleem twarn gooza", "Snorpit klarn zipdoo hest",
    "Wibber jolp trek gazz", "Fribbit gleep snoggle brank", "Yoopla wozzip tarm leeb",
    "Klikka drint zoomple vorb", "Bleemer flob gurntak jish", "Mezzar krang wibble froot",
    "Drabble kemp zontek whee", "Yarpin troose flonk rebb", "Skivver tharm jook narn",
    "Trizzle mootya plon draff", "Whizbit narm gleeby fesh", "Snarp clickle jarm hoog",
    "Gomper slint reevo twik", "Mizzle kooft rang dabber", "Sporkle veen zibber howt",
    "Troomber bazz knoop dern", "Kribble snab jooft wak"
]


# Rob — voice 0, slower

import pyttsx3
from pydub import AudioSegment
import os
import time

def speak_and_convert(text, voice, rate, filename):
    wav_path = filename.replace(".ogg", ".wav")
    engine = pyttsx3.init()
    engine.setProperty('voice', voice)
    engine.setProperty('rate', rate)
    engine.save_to_file(text, wav_path)
    engine.runAndWait()
    engine.stop()
    audio = AudioSegment.from_wav(wav_path)
    audio.export(filename, format="ogg")
    os.remove(wav_path)

def generate_batch(lines, voice_index, rate, name_prefix, batch_size=5):
    voices = pyttsx3.init().getProperty('voices')
    voice_id = voices[voice_index].id
    output_dir = "gibberish_ogg"
    os.makedirs(output_dir, exist_ok=True)

    for i in range(0, len(lines), batch_size):
        batch = lines[i:i+batch_size]
        for j, line in enumerate(batch):
            file_index = i + j + 1
            ogg_path = f"{output_dir}/{name_prefix}_{file_index:02}.ogg"
            speak_and_convert(line, voice_id, rate, ogg_path)
        print(f"✅ Batch {i//batch_size + 1} done.")
        time.sleep(1)  # Cooldown

# Run as batch
generate_batch(rob_lines, voice_index=0, rate=165, name_prefix="rob")
generate_batch(jim_lines, voice_index=1, rate=190, name_prefix="jim")
