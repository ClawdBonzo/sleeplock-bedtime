#!/usr/bin/env python3
"""Composite localized App Store screenshots at 1320x2868 (6.9").
Reads raw device captures from screenshots/raw/<lang>/<frame>.png and writes
branded, captioned frames to screenshots/appstore/<lang>/<NN-headline>.png.
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1320, 2868
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RAW = os.path.join(ROOT, "screenshots", "raw")
OUT = os.path.join(ROOT, "screenshots", "appstore")

FONT_LATIN = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
FONT_JA = "/System/Library/Fonts/Hiragino Sans GB.ttc"
FONT_KO = "/System/Library/Fonts/AppleSDGothicNeo.ttc"

def font_for(lang, size):
    if lang == "ja":
        return ImageFont.truetype(FONT_JA, size)
    if lang == "ko":
        return ImageFont.truetype(FONT_KO, size, index=0)
    return ImageFont.truetype(FONT_LATIN, size)

FRAMES = ["01-bedtime", "02-streaks", "03-levelup", "04-analytics"]
OUTNAME = {
    "01-bedtime": "01-LOCK-IN-YOUR-BEDTIME",
    "02-streaks": "02-BUILD-UNBREAKABLE-STREAKS",
    "03-levelup": "03-LEVEL-UP-YOUR-SLEEP",
    "04-analytics": "04-SEE-YOUR-SLEEP-TRENDS",
}

HEAD = {
 "01-bedtime": {"es":"FIJA TU HORA DE DORMIR","pt-BR":"TRAVE SUA HORA DE DORMIR","fr":"VERROUILLE TON COUCHER","it":"BLOCCA L'ORA DI DORMIRE","en":"LOCK IN YOUR BEDTIME","ja":"就寝時間をロックイン","ko":"취침 시간을 잠그세요","de":"SCHLAFENSZEIT FIXIEREN","nl":"LEG JE BEDTIJD VAST","sv":"LÅS IN DIN LÄGGDAGS"},
 "02-streaks": {"es":"RACHAS IMBATIBLES","pt-BR":"SEQUÊNCIAS IMBATÍVEIS","fr":"DES SÉRIES IMBATTABLES","it":"SERIE IMBATTIBILI","en":"BUILD UNBREAKABLE STREAKS","ja":"連続記録を伸ばそう","ko":"끊기지 않는 연속 기록","de":"UNZERBRECHLICHE SERIEN","nl":"BOUW ONBREEKBARE REEKSEN","sv":"BYGG OBRYTBARA SVITAR"},
 "03-levelup": {"es":"SUBE DE NIVEL TU SUEÑO","pt-BR":"SUBA DE NÍVEL NO SONO","fr":"PASSE AU NIVEAU SUPÉRIEUR","it":"SALI DI LIVELLO NEL SONNO","en":"LEVEL UP YOUR SLEEP","ja":"睡眠をレベルアップ","ko":"수면을 레벨 업하세요","de":"LEVEL UP FÜR DEINEN SCHLAF","nl":"LEVEL JE SLAAP OMHOOG","sv":"NIVÅHÖJ DIN SÖMN"},
 "04-analytics": {"es":"MIRA TUS TENDENCIAS","pt-BR":"VEJA SUAS TENDÊNCIAS","fr":"VOIS TES TENDANCES","it":"SCOPRI LE TUE TENDENZE","en":"SEE YOUR SLEEP TRENDS","ja":"睡眠の傾向を可視化","ko":"수면 추이를 확인하세요","de":"SIEH DEINE SCHLAF-TRENDS","nl":"ZIE JE SLAAPTRENDS","sv":"SE DINA SÖMNTRENDER"},
}
SUB = {
 "01-bedtime": {"es":"Una hora de dormir que de verdad cumples","pt-BR":"Uma hora de dormir que você cumpre","fr":"Une heure du coucher que tu tiens","it":"Un orario che rispetti davvero","en":"A bedtime you actually keep","ja":"続けられる就寝時間を","ko":"지킬 수 있는 취침 시간","de":"Eine Schlafenszeit, die du hältst","nl":"Een bedtijd die je volhoudt","sv":"En läggdags du faktiskt håller"},
 "02-streaks": {"es":"Cada noche a tiempo cuenta","pt-BR":"Cada noite no horário conta","fr":"Chaque soir à l'heure compte","it":"Ogni sera in orario conta","en":"Every on-target night counts","ja":"目標を守った夜が記録に","ko":"목표를 지킨 밤이 기록으로","de":"Jede pünktliche Nacht zählt","nl":"Elke nacht op tijd telt","sv":"Varje natt i tid räknas"},
 "03-levelup": {"es":"Gana XP, niveles e insignias","pt-BR":"Ganhe XP, níveis e conquistas","fr":"Gagne XP, niveaux et badges","it":"Guadagna XP, livelli e badge","en":"Earn XP, levels & badges","ja":"XP・レベル・バッジを獲得","ko":"XP·레벨·배지를 획득","de":"Sammle XP, Level & Abzeichen","nl":"Verdien XP, levels & badges","sv":"Tjäna XP, nivåer & märken"},
 "04-analytics": {"es":"Constancia, energía y duración","pt-BR":"Consistência, energia e duração","fr":"Régularité, énergie et durée","it":"Regolarità, energia e durata","en":"Consistency, energy & duration","ja":"一貫性・エネルギー・睡眠時間","ko":"일관성·에너지·수면 시간","de":"Konstanz, Energie & Dauer","nl":"Consistentie, energie & duur","sv":"Konsekvens, energi & längd"},
}

BG_TOP = (26, 22, 62)      # #1A163E
BG_BOT = (10, 20, 40)      # #0A1428
ACCENT = (139, 92, 246)    # purple
ACCENT2 = (124, 58, 237)

def gradient_bg():
    base = Image.new("RGB", (W, H), BG_BOT)
    top = Image.new("RGB", (W, H), BG_TOP)
    mask = Image.new("L", (W, H))
    md = mask.load()
    for y in range(H):
        v = int(255 * (1 - y / H) ** 1.3)
        for x in range(0, W, 1):
            md[x, y] = v
    base = Image.composite(top, base, mask)
    # purple glow top-center
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([W//2-520, -360, W//2+520, 560], fill=(124, 58, 237, 90))
    glow = glow.filter(ImageFilter.GaussianBlur(160))
    base = Image.alpha_composite(base.convert("RGBA"), glow)
    return base.convert("RGB")

def wrap(draw, text, font, max_w):
    # word-wrap (also handles CJK by char if no spaces)
    if " " in text:
        words = text.split(" ")
        lines, cur = [], ""
        for w in words:
            t = (cur + " " + w).strip()
            if draw.textlength(t, font=font) <= max_w:
                cur = t
            else:
                if cur: lines.append(cur)
                cur = w
        if cur: lines.append(cur)
        return lines
    else:
        lines, cur = [], ""
        for ch in text:
            if draw.textlength(cur + ch, font=font) <= max_w:
                cur += ch
            else:
                lines.append(cur); cur = ch
        if cur: lines.append(cur)
        return lines

def rounded(img, rad):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0], img.size[1]], radius=rad, fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out

def compose(lang, frame):
    raw = Image.open(os.path.join(RAW, lang, f"{frame}.png")).convert("RGB")
    canvas = gradient_bg().convert("RGBA")
    draw = ImageDraw.Draw(canvas)
    margin = 80
    max_w = W - 2 * margin

    # Headline — shrink to fit <=2 lines
    head = HEAD[frame][lang]
    size = 104 if lang not in ("ja", "ko") else 92
    while size > 48:
        f = font_for(lang, size)
        lines = wrap(draw, head, f, max_w)
        if len(lines) <= 2:
            break
        size -= 4
    f = font_for(lang, size)
    lines = wrap(draw, head, f, max_w)
    y = 150
    for ln in lines:
        w = draw.textlength(ln, font=f)
        draw.text(((W - w) / 2, y), ln, font=f, fill=(255, 255, 255))
        y += int(size * 1.12)

    # Accent bar
    bar_w = 150
    draw.rounded_rectangle([(W-bar_w)//2, y+18, (W+bar_w)//2, y+30], radius=6, fill=ACCENT)
    y += 60

    # Subtitle
    sf = font_for(lang, 44 if lang not in ("ja","ko") else 40)
    sub = SUB[frame][lang]
    slines = wrap(draw, sub, sf, max_w)
    for ln in slines:
        w = draw.textlength(ln, font=sf)
        draw.text(((W - w) / 2, y), ln, font=sf, fill=(170, 155, 230))
        y += int(48 * 1.1)

    # Device screenshot
    dev_w = 1040
    scale = dev_w / raw.width
    dev = raw.resize((dev_w, int(raw.height * scale)), Image.LANCZOS)
    dev = rounded(dev, 56)
    dx = (W - dev_w) // 2
    dy = y + 70
    # shadow
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle([dx, dy+18, dx+dev_w, dy+dev.height+18], radius=56, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(40))
    canvas = Image.alpha_composite(canvas, shadow)
    canvas.alpha_composite(dev, (dx, dy))

    os.makedirs(os.path.join(OUT, lang), exist_ok=True)
    out_path = os.path.join(OUT, lang, OUTNAME[frame] + ".png")
    canvas.convert("RGB").save(out_path, "PNG")
    return out_path

if __name__ == "__main__":
    langs = sorted([d for d in os.listdir(RAW) if os.path.isdir(os.path.join(RAW, d))])
    n = 0
    for lang in langs:
        for frame in FRAMES:
            if os.path.exists(os.path.join(RAW, lang, f"{frame}.png")):
                p = compose(lang, frame)
                n += 1
                print("wrote", os.path.relpath(p, ROOT))
    print(f"\nTotal: {n} screenshots at {W}x{H}")
