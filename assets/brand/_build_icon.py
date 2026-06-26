"""Regenera el icono de la app: fondo en DEGRADADO (verde→blanco) con un brillo
suave y pocas ondas, y el coche (Jeep.png) centrado y grande.

Genera 3 PNG:
  - icon.png            → iOS + Android legacy (degradado + coche).
  - icon_background.png → fondo adaptativo Android (degradado, sin coche).
  - icon_foreground.png → primer plano adaptativo Android (solo coche, transparente).
No requiere numpy."""
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 1024
TOP = (244, 249, 232)   # blanco verdoso (arriba del degradado)
BOTTOM = (150, 196, 56)  # verde de marca (abajo del degradado)
WHITE = (255, 255, 255)  # brillo y ondas suaves
GRAY = (88, 92, 80)      # gris cálido para la sombra del coche


def vertical_gradient(top, bottom):
    """Degradado vertical suave de `top` (arriba) a `bottom` (abajo)."""
    grad = Image.new("RGB", (1, S))
    px = grad.load()
    for y in range(S):
        t = y / (S - 1)
        px[0, y] = (
            round(top[0] + (bottom[0] - top[0]) * t),
            round(top[1] + (bottom[1] - top[1]) * t),
            round(top[2] + (bottom[2] - top[2]) * t),
        )
    return grad.resize((S, S)).convert("RGBA")


def soft_waves(color=WHITE, alpha=34, count=5, width=5, blur=3.0):
    """Pocas ondas muy suaves (textura ligera, no recargada)."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    random.seed(7)
    for i in range(count):
        base_y = (i + 0.5) * S / count
        amp = 18 + (i % 3) * 14
        period = 300 + (i % 3) * 70
        phase = i * 0.9
        pts = [
            (x, base_y + amp * math.sin((x / period) * 2 * math.pi + phase))
            for x in range(-30, S + 30, 4)
        ]
        d.line(pts, fill=(*color, alpha), width=width)
    return layer.filter(ImageFilter.GaussianBlur(blur))


def radial_glow(cx, cy, rx, ry, color, alpha, blur):
    """Halo elíptico difuminado (resalta el centro / detrás del coche)."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(*color, alpha))
    return layer.filter(ImageFilter.GaussianBlur(blur))


def background():
    """Fondo común: degradado + brillo central + ondas suaves."""
    bg = vertical_gradient(TOP, BOTTOM)
    bg.alpha_composite(soft_waves())
    bg.alpha_composite(radial_glow(S * 0.5, S * 0.46, 430, 360, WHITE, 95, 150))
    return bg


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
    bg = background()

    # --- Icono principal (iOS + fallback Android): fondo + coche grande centrado ---
    main = bg.copy()
    car_layer, shadow = car_and_shadow(0.92, 0.50)
    main.alpha_composite(shadow)
    main.alpha_composite(car_layer)
    main.convert("RGB").save("icon.png")
    print("icon.png OK")

    # --- Fondo adaptativo (Android): solo el degradado (el coche es el foreground) ---
    bg.convert("RGB").save("icon_background.png")
    print("icon_background.png OK")

    # --- Foreground adaptativo (Android): coche dentro de la zona segura, transparente ---
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fg_car, fg_shadow = car_and_shadow(0.66, 0.50)
    fg.alpha_composite(fg_shadow)
    fg.alpha_composite(fg_car)
    fg.save("icon_foreground.png")
    print("icon_foreground.png OK")


if __name__ == "__main__":
    build()
