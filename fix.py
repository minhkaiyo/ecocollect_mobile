import os

def fix_mojibake(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if content.startswith('\ufeff'):
        content = content[1:]
    
    # replace problematic chars that shouldn't be there
    content = content.replace('\x8d', '')
    
    try:
        fixed = content.encode('cp1258', errors='ignore').decode('utf-8')
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(fixed)
        print(f"Fixed {filepath}")
    except Exception as e:
        print(f"Error on {filepath}: {e}")

fix_mojibake('lib/screens/home_screen.dart')
fix_mojibake('lib/screens/onboarding_screen.dart')
