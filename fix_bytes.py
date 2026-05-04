import re

def fix_bytes(filepath):
    with open(filepath, 'rb') as f:
        content = f.read()
        
    # Replace the corrupted bytes directly
    # \xc4\x90 is supposed to be Đ
    # But maybe it was written as \ufffd\x90 ?
    # Let's print out what bytes correspond to "\x90ang"
    match = re.search(b'\\xef\\xbf\\xbd\\x90ang', content)
    if not match:
        match = re.search(b'.\\x90ang', content)
    print("Match for Đang:", match.group(0) if match else "None")

fix_bytes('lib/screens/home_screen.dart')
