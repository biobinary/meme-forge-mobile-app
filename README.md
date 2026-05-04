# Meme Forge Mobile App (MemeMaker)

Aplikasi pembuat meme interaktif dan bertenaga AI yang dibangun dengan Flutter. Aplikasi ini memungkinkan pengguna untuk membuat, mengedit, dan membagikan meme viral dengan mudah menggunakan dukungan Google Gemini AI.

## Deskripsi Umum

MemeMaker adalah aplikasi editor gambar yang dirancang khusus untuk membuat meme kekinian. Pengguna dapat memilih gambar, kemudian menggunakan fitur AI untuk menganalisis konteks gambar dan secara otomatis menghasilkan teks lucu, filter yang sesuai, serta rekomendasi stiker. Aplikasi ini juga menyediakan editor manual yang kaya fitur dan feed komunitas untuk membagikan karya pengguna.

## Fitur Utama

- **Pembuat Meme AI (Gemini):** Analisis gambar otomatis yang merekomendasikan teks atas/bawah, stiker, dan filter bergaya komedi Gen-Z atau surealis.
- **Editor Kanvas yang Kaya:** Pengeditan teks secara manual (font, warna, ukuran), penempatan stiker (emoji), dan penyesuaian rasio pemotongan gambar (crop).
- **Filter Gambar:** Pilihan filter visual bawaan (Normal, Grayscale, Sepia, Cool Blue) untuk mengatur *vibe* meme Anda.
- **Feed Komunitas & Profil:** Bagikan meme yang Anda buat ke *feed* publik dan kelola koleksi meme di profil Anda.
- **Notifikasi & Unggahan:** Dukungan proses latar belakang untuk mengunggah gambar ke *cloud* (Firebase/Supabase) dan memberikan notifikasi sistem saat proses selesai.
- **Batas Penggunaan AI Harian:** Integrasi pengecekan waktu jaringan dan database Firestore untuk memberikan jatah (kuota) *request* AI per pengguna setiap harinya.

## Arsitektur

Aplikasi ini dibangun menggunakan arsitektur modular yang rapi dan **Riverpod** untuk manajemen state:

- **Features (`lib/features/`):** Pemisahan logika UI berdasarkan fitur utama seperti `auth`, `editor`, `feed`, `home`, dan `profile`.
- **Core (`lib/core/`):** Menyimpan model, penyedia state (providers), tema, dan layanan utama (seperti `ai_service` untuk integrasi Gemini, `auth_service`, `upload_service`).
- **State Management:** Memanfaatkan ekosistem `flutter_riverpod` beserta `riverpod_generator` untuk reaktivitas UI yang reaktif dan efisien.

## Demo Video

Lihat video demo kami di sini:
[https://youtu.be/EbJ1IqiqpLI](https://youtu.be/EbJ1IqiqpLI)
