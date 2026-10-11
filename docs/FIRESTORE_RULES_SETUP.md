# Cara Memasang Firestore Security Rules

## Opsi 1: Lewat Firebase Console (Manual)
1. Buka [Firebase Console](https://console.firebase.google.com)
2. Pilih proyek **motocare-d902e**
3. Buka menu **Firestore Database** → tab **Rules**
4. Salin isi file `firestore.rules` dari proyek ini
5. Tempel di editor rules, lalu klik **Publish**

## Opsi 2: Lewat Firebase CLI (Otomatis)
1. Pastikan Firebase CLI terpasang: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Dari direktori proyek, jalankan: `firebase deploy --only firestore:rules`

> **Catatan:** File `firebase.json` harus sudah ada dan mengarah ke `firestore.rules`. Jika belum, jalankan `firebase init firestore` terlebih dahulu.
