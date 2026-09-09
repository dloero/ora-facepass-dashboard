"""Build two versions of the landing page from landing.template.html:
  - artifact.html : title + head + body content with images inlined as data URIs (for the Artifact tool)
  - index.html    : full standalone document with relative image paths (for the repo / hosting)
"""
import base64, os, re, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.join(HERE, "..", "img", "out")
tpl = open(os.path.join(HERE, "landing.template.html"), encoding="utf-8").read()

def part(name):
    return re.search(rf"<!--{name}-->(.*?)<!--/{name}-->", tpl, re.S).group(1)

title, head, body = part("TITLE").strip(), part("HEAD"), part("BODY")

def data_uri(name):
    p = os.path.join(IMG, f"{name}-web.webp")
    return "data:image/webp;base64," + base64.b64encode(open(p, "rb").read()).decode()

names = sorted(set(re.findall(r"\{\{IMG:([a-z0-9-]+)\}\}", body)))

# artifact version
art = f"<title>{title}</title>\n" + head + re.sub(r"\{\{IMG:([a-z0-9-]+)\}\}", lambda m: data_uri(m.group(1)), body)
open(os.path.join(HERE, "artifact.html"), "w", encoding="utf-8").write(art)

# repo version
out_dir = os.path.join(HERE, "site")
os.makedirs(os.path.join(out_dir, "img"), exist_ok=True)
for n in names:
    shutil.copy(os.path.join(IMG, f"{n}-web.webp"), os.path.join(out_dir, "img", f"{n}.webp"))
doc = ("<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
       f"<title>{title}</title>\n<meta name=\"description\" content=\"The new Ora FacePass FP06: 3D face unlock, solar charging, two cameras and a 4-inch interior screen in one smart lock. Reserve your spot on the launch list.\">\n"
       + head + "</head>\n<body>\n" + re.sub(r"\{\{IMG:([a-z0-9-]+)\}\}", r"img/\1.webp", body) + "\n</body>\n</html>\n")
open(os.path.join(out_dir, "index.html"), "w", encoding="utf-8").write(doc)
print("images:", names)
print("artifact.html KB", os.path.getsize(os.path.join(HERE, "artifact.html")) // 1024)
print("site/index.html KB", os.path.getsize(os.path.join(out_dir, "index.html")) // 1024)
