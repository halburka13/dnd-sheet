# Regenerates town/index.html from the main index.html (run after editing index.html).
# Usage: python3 build-town.py
import re
h = open("index.html", encoding="utf-8").read()
def rep(old, new):
    global h
    assert old in h, old
    h = h.replace(old, new)
rep('<script src="./config.js"></script>', '<script>window.APP_MODE="town"</script>\n<script src="../config.js"></script>')
rep('<script src="./supabase.js"></script>', '<script src="../supabase.js"></script>')
h = re.sub(r'<title>.*?</title>', '<title>Town manager</title>', h, count=1)
open("town/index.html", "w", encoding="utf-8").write(h)
print("town/index.html written")
