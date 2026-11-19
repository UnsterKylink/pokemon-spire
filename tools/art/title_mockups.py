import sys, os, math, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageEnhance
R = '/home/user/pokemon-spire/'
OUT = sys.argv[1]
W, H = 1280, 720
LIL = R+'assets/fonts/lilita_one/LilitaOne-Regular.ttf'
JOST = R+'assets/fonts/jost/Jost-Variable.ttf'
def f(p, s): return ImageFont.truetype(p, s)
def cover(path, dark=0.0, blur=0):
    im = Image.open(path).convert('RGB'); s = max(W/im.width, H/im.height)
    im = im.resize((int(im.width*s)+1, int(im.height*s)+1), Image.LANCZOS)
    x, y = (im.width-W)//2, (im.height-H)//2; im = im.crop((x, y, x+W, y+H))
    if blur: im = im.filter(ImageFilter.GaussianBlur(blur))
    if dark: im = ImageEnhance.Brightness(im).enhance(1-dark)
    return im.convert('RGBA')
def art(slug, h):
    im = Image.open(R+'assets/sprites/artwork/%s.png' % slug).convert('RGBA'); s = h/im.height
    return im.resize((max(1,int(im.width*s)), int(h)), Image.LANCZOS)
def logo(w):
    im = Image.open(R+'assets/art/title/logo.png').convert('RGBA'); s = w/im.width
    return im.resize((int(w), int(im.height*s)), Image.LANCZOS)
def shadow_under(base, cx, y, w):
    sh = Image.new('RGBA', (W, H), 0); d = ImageDraw.Draw(sh)
    d.ellipse([cx-w/2, y-w*0.09, cx+w/2, y+w*0.09], fill=(0, 0, 0, 120)); base.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8)))
def glow(base, cx, cy, r, col):
    g = Image.new('RGBA', (W, H), 0); ImageDraw.Draw(g).ellipse([cx-r, cy-r, cx+r, cy+r], fill=col)
    base.alpha_composite(g.filter(ImageFilter.GaussianBlur(r*0.45)))
def grad(base, y0, y1, col, a0, a1):
    g = Image.new('RGBA', (W, H), 0); d = ImageDraw.Draw(g)
    for y in range(y0, y1):
        t = (y-y0)/max(1, y1-y0); d.line([(0, y), (W, y)], fill=col+(int(a0+(a1-a0)*t),))
    base.alpha_composite(g)
def button(d, box, text, base=(52, 120, 230), size=28, primary=False):
    x0, y0, x1, y1 = box
    d.rounded_rectangle([x0, y0+4, x1, y1+4], 14, fill=(10, 20, 50, 200))
    d.rounded_rectangle(box, 14, fill=base, outline=(18, 36, 94), width=4)
    d.rounded_rectangle([x0+6, y0+5, x1-6, (y0+y1)/2], 10, fill=tuple(min(255, c+40) for c in base))
    fo = f(LIL, size); tw = d.textlength(text, font=fo)
    d.text(((x0+x1-tw)/2+2, (y0+y1)/2-size*0.62+2), text, font=fo, fill=(18, 36, 94))
    d.text(((x0+x1-tw)/2, (y0+y1)/2-size*0.62), text, font=fo, fill=(255, 255, 255))
def particles(base, n, col, seed, ymin=0, ymax=H):
    rnd = random.Random(seed); g = Image.new('RGBA', (W, H), 0); d = ImageDraw.Draw(g)
    for _ in range(n):
        x, y, r = rnd.uniform(0, W), rnd.uniform(ymin, ymax), rnd.uniform(1.5, 4)
        d.ellipse([x-r, y-r, x+r, y+r], fill=col+(rnd.randint(120, 255),))
    base.alpha_composite(g.filter(ImageFilter.GaussianBlur(1)))
def text_c(d, y, text, fo, fill, stroke=None):
    tw = d.textlength(text, font=fo)
    d.text(((W-tw)/2, y), text, font=fo, fill=fill, stroke_width=3 if stroke else 0, stroke_fill=stroke)

# A — « Les trois partenaires » : starters d'une génération face caméra, logo centré, menu en bas
im = cover(R+'assets/art/title/title.jpg', dark=0.15, blur=3)
grad(im, 380, H, (8, 14, 40), 0, 235); glow(im, W/2, 330, 260, (255, 230, 150, 120))
for slug, cx, h in [('bulbasaur', 360, 250), ('charmander', 640, 290), ('squirtle', 920, 250)]:
    a = art(slug, h); shadow_under(im, cx, 520, a.width*0.8); im.alpha_composite(a, (int(cx-a.width/2), 520-a.height))
particles(im, 70, (255, 240, 180), 1, 0, 500)
L = logo(620); im.alpha_composite(L, ((W-L.width)//2, 6))
d = ImageDraw.Draw(im)
for i, (t, c) in enumerate([('Continuer', (214, 44, 48)), ('Nouvelle partie', (52, 120, 230)), ('Tutoriel', (52, 120, 230)), ('Options', (52, 120, 230))]):
    x = 130 + i*265; button(d, [x, 560, x+240, 616], t, c, 26)
text_c(d, 650, 'Parties : 7   ·   Victoires : 1   ·   Meilleur : Éthernatos vaincu', f(JOST, 22), (230, 236, 255))
im.convert('RGB').save(OUT+'/A-trois-partenaires.png')

# B — « Deck de légende » : éventail de cartes derrière le logo, fond sombre élégant, menu vertical centré
im = cover(R+'assets/art/backdrops/league.jpg', dark=0.45, blur=6)
glow(im, W/2, 250, 330, (255, 210, 90, 90))
cards = Image.open(R+'production/qa/evidence/story-020b-refonte-visuelle-premium/3x-main-raretes.png').convert('RGBA')
boxes = [(192, 512, 360, 712), (374, 512, 542, 712), (556, 512, 724, 712), (738, 512, 906, 712), (920, 512, 1088, 712)]
for i, bx in enumerate(boxes):
    c = cards.crop(bx).resize((210, 250), Image.LANCZOS); ang = (i-2)*-13
    c = c.rotate(ang, expand=True, resample=Image.BICUBIC)
    cx = W/2 + (i-2)*150; cy = 300 + abs(i-2)*28
    im.alpha_composite(c, (int(cx-c.width/2), int(cy-c.height/2)))
grad(im, 380, H, (6, 8, 24), 0, 245)
L = logo(560); im.alpha_composite(L, ((W-L.width)//2, 150))
d = ImageDraw.Draw(im)
for i, (t, c) in enumerate([('Continuer', (214, 44, 48)), ('Nouvelle partie', (52, 120, 230)), ('Tutoriel', (52, 120, 230)), ('Options', (52, 120, 230))]):
    x = 145 + i*255; button(d, [x, 600, x+230, 652], t, c, 25)
im.convert('RGB').save(OUT+'/B-deck-de-legende.png')

# C — « L'ombre d'Éthernatos » : boss géant dans le ciel rouge, ton starter de dos face à lui, menu à gauche
im = cover(R+'assets/art/backdrops/ethernatos.jpg', dark=0.2)
glow(im, 860, 260, 300, (255, 40, 80, 140))
e = art('eternatus', 560); e = ImageEnhance.Brightness(e).enhance(0.9); im.alpha_composite(e, (860-e.width//2, -40))
grad(im, 420, H, (20, 0, 10), 0, 230); grad(im, 0, 120, (20, 0, 10), 140, 0)
side = Image.new('RGBA', (W, H), 0); ImageDraw.Draw(side).rectangle([0, 0, 470, H], fill=(10, 4, 18, 150)); im.alpha_composite(side.filter(ImageFilter.GaussianBlur(40)))
p = art('charmander', 230); p = p.transpose(Image.FLIP_LEFT_RIGHT); shadow_under(im, 560, 690, 170); im.alpha_composite(p, (560-p.width//2, 690-p.height))
particles(im, 90, (255, 120, 120), 3)
L = logo(420); im.alpha_composite(L, (40, 30))
d = ImageDraw.Draw(im)
for i, (t, c) in enumerate([('Continuer', (214, 44, 48)), ('Nouvelle partie', (52, 120, 230)), ('Tutoriel', (60, 70, 120)), ('Options', (60, 70, 120)), ('Quitter', (60, 70, 120))]):
    button(d, [60, 340+i*66, 380, 392+i*66], t, c, 26)
im.convert('RGB').save(OUT+'/C-ombre-d-ethernatos.png')

# D — « En route vers la Tour » : ton image peinte, une équipe qui gravit le chemin, menu épuré en bas à droite
im = cover(R+'assets/art/title/title.jpg')
grad(im, 0, 200, (255, 236, 200), 120, 0)
team = [('pikachu', 330, 640, 150), ('eevee', 470, 600, 120), ('totodile', 590, 570, 105), ('chikorita', 690, 548, 92), ('cyndaquil', 778, 530, 80)]
for slug, cx, fy, h in team:
    a = art(slug, h); shadow_under(im, cx, fy, a.width*0.7); im.alpha_composite(a, (int(cx-a.width/2), int(fy-a.height)))
particles(im, 50, (255, 255, 230), 4, 0, 400)
L = logo(520); im.alpha_composite(L, (40, 20))
pane = Image.new('RGBA', (W, H), 0); ImageDraw.Draw(pane).rounded_rectangle([930, 330, 1250, 690], 22, fill=(255, 255, 255, 215), outline=(42, 98, 184), width=6); im.alpha_composite(pane)
d = ImageDraw.Draw(im)
for i, (t, c) in enumerate([('Continuer', (214, 44, 48)), ('Nouvelle partie', (52, 120, 230)), ('Tutoriel', (52, 120, 230)), ('Options', (52, 120, 230)), ('Quitter', (80, 92, 130))]):
    button(d, [955, 350+i*66, 1225, 400+i*66], t, c, 24)
im.convert('RGB').save(OUT+'/D-en-route-vers-la-tour.png')
print('ok')
