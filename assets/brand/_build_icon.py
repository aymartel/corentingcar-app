"""Regenera el icono de la app con fondo VERDE CLARO, ondas verdes y sombras grises.
Fuente del coche: Jeep.png (recorte limpio, transparente). No requiere numpy."""
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 1024
GREEN = (156, 201, 59)        # #9CC93B (verde de marca)
BG = (205, 229, 138)          # #CDE58A (fondo verde claro; tinte claro del verde de marca)
GRAY = (88, 92, 80)           # gris cálido para sombras


def wavy_lines(alpha=70, count=13, width=3, blur=1.0):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    random.seed(7)
    for i in range(count):
        base_y = (i + 0.5) * S / count
        amp = 16 + (i % 3) * 13
        period = 240 + (i % 4) * 55
        phase = i * 0.8
        pts = [
            (x, base_y + amp * math.sin((x / period) * 2 * math.pi + phase))
            for x in range(-30, S + 30, 4)
        ]
        d.line(pts, fill=(*GREEN, alpha), width=width)
    return layer.filter(ImageFilter.GaussianBlur(blur))


def radial_glow(cx, cy, rx, ry, alpha, blur):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(
        [cx - rx, cy - ry, cx + rx, cy + ry], fill=(*GREEN, alpha)
    )
    return layer.filter(ImageFilter.GaussianBlur(blur))


def car_and_shadow(target_w_frac, center_y_frac, shadow_alpha=185):
    """Devuelve (capa_coche, capa_sombra) a tamaño S, centradas horizontalmente."""
    car = Image.open("Jeep.png").convert("RGBA")
    car = car.crop(car.split()[3].getbbox())
    cw, ch = car.size
    target_w = int(S * target_w_frac)
    scale = target_w / cw
    car = car.resize((target_w, int(ch * scale)), Image.LANCZOS)
    cw, ch = car.size
    px = (S - cw) // 2
    py = int(S * center_y_frac) - ch // 2

    car_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    car_layer.paste(car, (px, py), car)

    sil = car.split()[3].point(lambda v: 255 if v > 170 else 0)
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shadow.paste((*GRAY, shadow_alpha), (px, py), sil)
    shadow = ImageChops.offset(shadow, 0, 26)
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    return car_layer, shadow


def build():
    # --- Icono principal (iOS + fallback Android): coche grande ---
    out = Image.new("RGBA", (S, S), (*BG, 255))   # fondo verde claro
    out.alpha_composite(wavy_lines(alpha=105, count=13, width=3, blur=0.9))
    out.alpha_composite(wavy_lines(alpha=52, count=7, width=9, blur=6.0))
    out.alpha_composite(radial_glow(S * 0.5, S * 0.53, 360, 285, 78, 120))
    car_layer, shadow = car_and_shadow(0.90, 0.50)
    out.alpha_composite(shadow)
    out.alpha_composite(car_layer)
    out.convert("RGB").save("icon.png")
    print("icon.png OK")

    # --- Foreground adaptativo (Android): coche dentro de la zona segura (el
    # sistema recorta el icono en círculo/squircle). Fondo transparente. ---
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fg.alpha_composite(radial_glow(S * 0.5, S * 0.52, 235, 195, 75, 95))
    fg_car, fg_shadow = car_and_shadow(0.66, 0.50)
    fg.alpha_composite(fg_shadow)
    fg.alpha_composite(fg_car)
    fg.save("icon_foreground.png")
    print("icon_foreground.png OK")


if __name__ == "__main__":
    build()
