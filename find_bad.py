import re

def extract_bad_strings(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        text = f.read()
    # Find any word with the unicode replacement character \ufffd or \x8d
    bad_words = re.findall(r'\S*[\ufffd\x8d\x81\x8f\x90\x9d]\S*', text)
    print(set(bad_words))

extract_bad_strings('lib/screens/home_screen.dart')
