# Meme Forge - Design System Guidelines

## 1. Art Style Direction
- **Vibe:** Nyentrik, Playful, Bold, tapi Clean (Terinspirasi gaya Neo-Brutalism).
- **Karakter:** Meme-centric. Kontras tinggi, bentuk tegas, tidak mencoba untuk terlalu "elegan" bergaya korporat. Aplikasi harus terasa menyenangkan dan ringan.

## 2. Color System
- **Primary Color:** `Vibrant Yellow (#FFD500)` — Warna "Meme" klasik yang mencuri perhatian.
- **On Primary (Text/Icon on Primary):** `Black (#000000)` — memberikan kontras maksimal.
- **Surface (Background):**
  - Light Mode: `Off-white (#FAFAFA)`
  - Dark Mode: `Zinc 900 (#18181B)`
- **Accent/Secondary:** `Electric Indigo (#4338CA)` — digunakan sesekali untuk indikator atau badge agar tidak monoton kuning-hitam.

## 3. Typography Rules
- **Headline & App Bar:** `Anton` (Google Fonts). Sangat bold, tebal, proporsi vertikal kuat—mengingatkan pada font "Impact" yang umum dipakai di meme.
- **UI Text, Body & Caption:** `Nunito` (Google Fonts). Font sans-serif dengan ujung membulat (rounded terminals). Memberikan keseimbangan yang soft/playful untuk mengimbangi bentuk tajam desain dan headline yang kaku.
- **Meme Text (Dalam Canvas/Sticker nantinya):** Harus menggunakan `Impact`, `Oswald` atau `Anton` dengan stroke hitam/putih agar kontras di atas gambar.

## 4. Component Guidelines
- **Buttons (Filled/Elevated):**
  - Bentuk: `Rounded Rectangle` (radius 16px).
  - Gaya (Light Mode): Terapkan style Solid Black border (ketebalan 2px) atau bayangan hitam tegas (bukan blur) jika ingin lebih kearah Neo-brutalist.
  - Teks: Font bold (Semibold/Extrabold), ukuran memadai (16-18px) untuk kemudahan di-tap (tumb-friendly).
- **Cards & Container:**
  - Radius membulat (16-20px) dengan warna dasar putih atau abu sangat gelap.
  - Tidak perlu shadow berlapis-lapis. Lebih baik gunakan garis pinggir (border tipis) `1.5px` agar kontras dengan Surface.

## 5. Spacing & Layout Rules
- **Sistem Grid:** Gunakan pakem kelipatan **4px** dan **8px**.
  - Elemen terkait (Icon & Text, jarak vertikal antar label): `8px`
  - Spasi antar seksi/komponen utama (Padding): `16px` – `24px`
  - Margin sisi layar (Screen horizontal padding): `24px`.
- **Negative Space:** Jangan memadatkan layar. Biarkan ada ruang bernapas yang cukup terutama di area kanvas editor.

## 6. Do & Don't
- **DO 👍:** Gunakan padding konsisten untuk menciptakan tap area yang luas pada UI elemen.
- **DO 👍:** Kombinasikan warna hitam dan kuning untuk action button penting (CTA utama).
- **DON'T 🚫:** Menggunakan *Soft Blur Shadows* bergaya neumorphism/iOS style. Hindari UI yang terasa rapuh.
- **DON'T 🚫:** Menggunakan lebih dari 2 font family untuk layout (Kecuali font khusus yang ditambahkan user ke dalam meme).
- **DON'T 🚫:** Menambahkan terlalu banyak icon yang tidak relevan. Buat seminimalist mungkin dan tetap straight to the point.
