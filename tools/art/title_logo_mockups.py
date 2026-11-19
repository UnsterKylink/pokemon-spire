import sys, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageEnhance, ImageChops
R = '/home/user/pokemon-spire/'; FD = '/tmp/claude-0/-home-user-pokemon-spire/a2b72075-2d8b-51e2-a914-9e4b612c161d/scratchpad/fonts/'
OUT = sys.argv[1]; W, H = 1280, 720
LIL = R+'assets/fonts/lilita_one/LilitaOne-Regular.ttf'
def font(path, size, var=None):
    f = ImageFont.truetype(path, size)
    if var:
        try: f.set_variation_by_name(var)
        except Exception: pass
    return f
def cover(path, dark=0.0, blur=0):
    im = Image.open(path).convert('RGB'); s = max(W/im.width, H/im.height)
    im = im.resize((int(im.width*s)+1, int(im.height*s)+1), Image.LANCZOS)
    x, y = (im.width-W)//2, (im.height-H)//2; im = im.crop((x, y, x+W, y+H))
    if blur: im = im.filter(ImageFilter.GaussianBlur(blur))
    if dark: im = ImageEnhance.Brightness(im).enhance(1-dark)
    return im.convert('RGBA')
def glow(base, cx, cy, r, col):
    g = Image.new('RGBA', (W, H), 0); ImageDraw.Draw(g).ellipse([cx-r, cy-r, cx+r, cy+r], fill=col)
    base.alpha_composite(g.filter(ImageFilter.GaussianBlur(r*0.45)))
def grad_layer(y0, y1, stops):
    g = Image.new('RGBA', (W, H)); d = ImageDraw.Draw(g)
    for y in range(H):
        t = min(max((y-y0)/max(1, y1-y0), 0), 1)
        for i in range(len(stops)-1):
            (ta, ca), (tb, cb) = stops[i], stops[i+1]
            if ta <= t <= tb:
                u = (t-ta)/max(1e-6, tb-ta); c = tuple(int(ca[k]+(cb[k]-ca[k])*u) for k in range(3)); break
        d.line([(0, y), (W, y)], fill=c+(255,))
    return g
def vgrad(base, y0, y1, col, a0, a1):
    g = Image.new('RGBA', (W, H), 0); d = ImageDraw.Draw(g)
    for y in range(y0, y1):
        t = (y-y0)/max(1, y1-y0); d.line([(0, y), (W, y)], fill=col+(int(a0+(a1-a0)*t),))
    base.alpha_composite(g)
def text_mask(text, fnt, y, spacing=0, cx=W/2):
    m = Image.new('L', (W, H), 0); d = ImageDraw.Draw(m)
    widths = [d.textlength(c, font=fnt) for c in text]; total = sum(widths)+spacing*(len(text)-1)
    x = cx-total/2
    for c, w in zip(text, widths):
        d.text((x, y), c, font=fnt, fill=255); x += w+spacing
    return m
def grow(m, r): return m.filter(ImageFilter.MaxFilter(r*2+1)) if r > 0 else m
def paint(base, mask, col): base.paste(col if isinstance(col, tuple) else col, (0, 0), mask) if isinstance(col, tuple) else base.paste(col, (0, 0), mask)
def button(d, box, text, base=(52, 120, 230), size=25):
    x0, y0, x1, y1 = box
    d.rounded_rectangle([x0, y0+4, x1, y1+4], 14, fill=(10, 20, 50, 200))
    d.rounded_rectangle(box, 14, fill=base, outline=(18, 36, 94), width=4)
    d.rounded_rectangle([x0+6, y0+5, x1-6, (y0+y1)/2], 10, fill=tuple(min(255, c+40) for c in base))
    fo = font(LIL, size); tw = d.textlength(text, font=fo)
    d.text(((x0+x1-tw)/2+2, (y0+y1)/2-size*0.62+2), text, font=fo, fill=(18, 36, 94))
    d.text(((x0+x1-tw)/2, (y0+y1)/2-size*0.62), text, font=fo, fill=(255, 255, 255))
def scene():
    im = cover(R+'assets/art/backdrops/league.jpg', dark=0.5, blur=6)
    glow(im, W/2, 250, 330, (255, 210, 90, 80))
    cards = Image.open(R+'production/qa/evidence/story-020b-refonte-visuelle-premium/3x-main-raretes.png').convert('RGBA')
    boxes = [(192, 512, 360, 712), (374, 512, 542, 712), (556, 512, 724, 712), (738, 512, 906, 712), (920, 512, 1088, 712)]
    for i, bx in enumerate(boxes):
        c = cards.crop(bx).resize((210, 250), Image.LANCZOS).rotate((i-2)*-13, expand=True, resample=Image.BICUBIC)
        c = ImageEnhance.Brightness(c).enhance(0.8)
        cx = W/2+(i-2)*150; cy = 300+abs(i-2)*28; im.alpha_composite(c, (int(cx-c.width/2), int(cy-c.height/2)))
    vgrad(im, 380, H, (6, 8, 24), 0, 245)
    vgrad(im, 120, H, (6, 8, 24), 0, 110)
    return im
def menu(im):
    d = ImageDraw.Draw(im)
    for i, (t, c) in enumerate([('Continuer', (214, 44, 48)), ('Nouvelle partie', (52, 120, 230)), ('Tutoriel', (52, 120, 230)), ('Options', (52, 120, 230))]):
        x = 145+i*255; button(d, [x, 600, x+230, 652], t, c, 25)

# 1 — Or royal (serif doré, façon jeu de cartes premium)
im = scene()
big = text_mask('SPIRE', font(FD+'CinzelDecorative-Black.ttf', 170), 255)
small = text_mask('POKÉMON', font(FD+'Cinzel[wght].ttf', 46, 'Bold'), 210, spacing=18)
both = ImageChops.lighter(big, small)
gl = Image.new('RGBA', (W, H), 0); gl.paste((255, 190, 80, 255), (0, 0), grow(both, 6)); im.alpha_composite(gl.filter(ImageFilter.GaussianBlur(18)))
im.paste((40, 20, 6, 255), (0, 0), grow(both, 4))
gold = grad_layer(220, 460, [(0, (255, 246, 200)), (0.45, (240, 190, 70)), (0.55, (180, 120, 30)), (1, (255, 220, 120))])
im.paste(gold, (0, 0), both)
d = ImageDraw.Draw(im)
for side in (-1, 1):
    x0, x1 = W/2+side*150, W/2+side*330
    d.line([(x0, 236), (x1, 236)], fill=(240, 200, 110, 255), width=3)
    d.polygon([(x1+side*12, 236), (x1, 229), (x1-side*12, 236), (x1, 243)], fill=(240, 200, 110, 255))
sub = font(FD+'Cinzel[wght].ttf', 26, 'Bold'); t = 'ROGUELIKE DE CARTES'; tw = d.textlength(t, font=sub)
d.text(((W-tw)/2, 450), t, font=sub, fill=(235, 215, 170))
menu(im); im.convert('RGB').save(OUT+'/logo1-or-royal.png')

# 2 — Blason (titre dans un écusson en forme de carte, icône de tour)
im = scene()
d = ImageDraw.Draw(im)
cx = W/2; bx = [cx-300, 175, cx+300, 470]
sh = Image.new('RGBA', (W, H), 0); ImageDraw.Draw(sh).rounded_rectangle([bx[0]+8, bx[1]+14, bx[2]+8, bx[3]+14], 30, fill=(0, 0, 0, 170)); im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(12)))
d.rounded_rectangle(bx, 30, fill=(16, 26, 70, 245), outline=(232, 190, 90), width=7)
d.rounded_rectangle([bx[0]+14, bx[1]+14, bx[2]-14, bx[3]-14], 22, outline=(232, 190, 90, 160), width=2)
tower = [(cx, 150), (cx+26, 205), (cx+18, 205), (cx+30, 250), (cx-30, 250), (cx-18, 205), (cx-26, 205)]
d.ellipse([cx-58, 140, cx+58, 256], fill=(16, 26, 70), outline=(232, 190, 90), width=6)
d.polygon(tower, fill=(255, 214, 110))
s1 = font(FD+'Montserrat[wght].ttf', 34, 'Bold'); t = 'P O K É M O N'; tw = d.textlength(t, font=s1); d.text(((W-tw)/2, 268), t, font=s1, fill=(150, 200, 255))
big = text_mask('SPIRE', font(FD+'BebasNeue-Regular.ttf', 170), 300)
im.paste((8, 14, 40, 255), (0, 0), grow(big, 4))
im.paste(grad_layer(320, 450, [(0, (255, 255, 255)), (1, (150, 200, 255))]), (0, 0), big)
d = ImageDraw.Draw(im); s2 = font(FD+'Montserrat[wght].ttf', 22, 'SemiBold'); t = 'ROGUELIKE DE CARTES'; tw = d.textlength(t, font=s2); d.text(((W-tw)/2, 488), t, font=s2, fill=(232, 190, 90))
menu(im); im.convert('RGB').save(OUT+'/logo2-blason.png')

# 3 — Moderne lumineux (sans-serif épais, dégradé cyan-violet, reflet)
im = scene()
big = text_mask('SPIRE', font(FD+'Montserrat[wght].ttf', 190, 'Black'), 230)
small = text_mask('POKÉMON', font(FD+'Montserrat[wght].ttf', 44, 'Light'), 200, spacing=22)
gl = Image.new('RGBA', (W, H), 0); gl.paste((90, 170, 255, 255), (0, 0), grow(big, 10)); im.alpha_composite(gl.filter(ImageFilter.GaussianBlur(26)))
im.paste((10, 14, 40, 255), (0, 0), grow(big, 3))
im.paste(grad_layer(250, 440, [(0, (120, 230, 255)), (0.5, (120, 140, 255)), (1, (210, 110, 255))]), (0, 0), big)
streak = Image.new('L', (W, H), 0); ImageDraw.Draw(streak).polygon([(560, 230), (600, 230), (520, 460), (480, 460)], fill=150)
im.paste((255, 255, 255, 255), (0, 0), ImageChops.multiply(big, streak.filter(ImageFilter.GaussianBlur(6))))
im.paste((235, 240, 255, 255), (0, 0), small)
d = ImageDraw.Draw(im); s2 = font(FD+'Montserrat[wght].ttf', 22, 'Medium'); t = 'ROGUELIKE DE CARTES'; tw = d.textlength(t, font=s2); d.text(((W-tw)/2, 470), t, font=s2, fill=(170, 190, 255))
menu(im); im.convert('RGB').save(OUT+'/logo3-moderne.png')

# 4 — Pokémon officiel retravaillé (jaune/bleu mais net : lettres serrées, pas de ruban, contour fin + ombre)
im = scene()
big = text_mask('Spire', font(LIL, 200), 225)
small = text_mask('Pokémon', font(LIL, 92), 150)
both = ImageChops.lighter(big, small)
sh = Image.new('RGBA', (W, H), 0); sh.paste((0, 0, 0, 200), (6, 10), grow(both, 10)); im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(10)))
im.paste((20, 44, 120, 255), (0, 0), grow(both, 10))
im.paste((60, 110, 220, 255), (0, 0), grow(both, 6))
im.paste(grad_layer(160, 420, [(0, (255, 240, 120)), (1, (255, 196, 20))]), (0, 0), both)
d = ImageDraw.Draw(im); s2 = font(FD+'Montserrat[wght].ttf', 22, 'SemiBold'); t = 'ROGUELIKE DE CARTES'; tw = d.textlength(t, font=s2); d.text(((W-tw)/2, 468), t, font=s2, fill=(255, 230, 140))
menu(im); im.convert('RGB').save(OUT+'/logo4-pokemon-net.png')
print('ok')
