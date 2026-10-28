class_name Story
extends RefCounted
##
## Seluruh teks cerita game ada di file ini (Bahasa Indonesia).
## Dipisah dari logika supaya mudah diedit tanpa menyentuh kode gameplay.
##
## Satu halaman dialog = satu Dictionary:
##   name     : nama pembicara ("" untuk narasi)
##   role     : jabatan/peran di tim
##   portrait : Texture2D atau null
##   text     : isi dialog (mendukung BBCode sederhana)
##   title    : judul opsional (dipakai untuk surat / narasi)
##   variant  : "speech" (default), "narration", atau "letter"
##

const TITLE_GAME := "TEAM QUEST"
const SUBTITLE_GAME := "PETUALANGAN TIGA PERAN"

const BANNER_MISSION_TITLE := "MISI PENYELAMATAN"
const BANNER_MISSION_TEXT := "Masuki portal dan temukan Hafidz!"
const BANNER_SUCCESS_TITLE := "MISI BERHASIL!"
const BANNER_SUCCESS_TEXT := "Terima kasih telah menjadi bagian dari petualangan kami!"

const MISSION_HUD_TITLE := "MISI: SELAMATKAN HAFIDZ"
const MISSION_HUD_GOAL := "Tujuan: Kumpulkan koin dan kalahkan monster untuk menemukan Hafidz."

const PROMPT_LETTER := "Tekan %s untuk membaca surat."
const PROMPT_PORTAL := "Tekan %s untuk memasuki portal."
const PROMPT_HAFIDZ := "Tekan %s untuk menemui Hafidz."

const TOAST_COIN := "Koin berhasil dikumpulkan!"
const TOAST_ENEMY := "Monster berhasil dikalahkan!"
const TOAST_DANGER := "Hati-hati! Ada monster di dekatmu!"
const TOAST_COINS_DONE := "Semua koin berhasil dikumpulkan!"
const TOAST_ENEMIES_DONE := "Area sudah aman! Sekarang cari Hafidz."
const TOAST_DIED := "Kamu tumbang! Kembali ke titik awal."
const TOAST_SANDHO_JOINED := "Sandho sekarang mengikutimu!"
const TOAST_LETTER_READ := "Surat dibaca. Portal mulai terbuka!"

const HINT_ADVANCE := "%s : lanjut"


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------
static func _speaker(key: String, text: String) -> Dictionary:
	return {
		"name": GameState.member_name(key),
		"role": GameState.member_role(key),
		"portrait": GameState.member_portrait(key),
		"text": text,
		"variant": "speech",
	}


static func _narrator(text: String, title: String = "") -> Dictionary:
	return {
		"name": "",
		"role": "",
		"portrait": null,
		"text": text,
		"title": title,
		"variant": "narration",
	}


static func _letter(text: String, title: String = "") -> Dictionary:
	return {
		"name": "",
		"role": "",
		"portrait": null,
		"text": text,
		"title": title,
		"variant": "letter",
	}


# --------------------------------------------------------------------------
# 1. Opening narration
# --------------------------------------------------------------------------
static func opening() -> Array:
	return [
		_narrator("Setiap game hebat berawal dari sebuah ide. Namun, untuk mewujudkan ide tersebut, dibutuhkan kreativitas, kerja sama, dan semangat dari sebuah tim.", "PROLOG"),
		_narrator("Inilah perjalanan tiga anggota tim dengan peran dan keahlian yang berbeda. Bersama-sama, mereka akan menghadapi tantangan dan membuktikan bahwa kerja sama adalah kunci keberhasilan."),
	]


# --------------------------------------------------------------------------
# 2. Zhafran - Artist
# --------------------------------------------------------------------------
static func zhafran_intro() -> Array:
	return [
		_speaker("zhafran", "Halo, semuanya! Kenalin, aku Zhafran, dan di tim ini aku bertugas sebagai Artist."),
		_speaker("zhafran", "Aku bertanggung jawab membuat tampilan visual game, mulai dari desain karakter, sprite, hingga berbagai elemen visual lainnya agar game kita terlihat menarik."),
		_speaker("zhafran", "Yuk, ikuti petualanganku! Semoga ada hal menarik yang bisa kita temukan di depan."),
	]


# --------------------------------------------------------------------------
# 3. Sandho - Project Manager & Level Manager
# --------------------------------------------------------------------------
static func sandho_intro() -> Array:
	return [
		_speaker("sandho", "Eh, halo! Kenalin, aku Sandho, bertugas sebagai Project Manager sekaligus Level Manager."),
		_speaker("sandho", "Tugasku adalah mengatur jalannya proyek, mengoordinasikan pekerjaan anggota tim, dan merancang level agar permainan kita berjalan dengan baik dan menyenangkan."),
		_speaker("sandho", "Kalau kamu mau menjelajah, aku ikut, ya! Petualangan pasti lebih seru kalau dilakukan bersama-sama."),
	]


static func sandho_team_talk() -> Array:
	return [
		_speaker("sandho", "Oke, Zhafran! Aku siap ikut. Ayo kita lanjutkan perjalanan ini!"),
		_speaker("zhafran", "Sip! Kita jalan bareng. Semoga nggak ada monster aneh di depan, ya."),
		_speaker("sandho", "Hahaha, tenang saja! Kalau ada masalah, kita hadapi bersama."),
	]


# --------------------------------------------------------------------------
# 4. Rescue letter
# --------------------------------------------------------------------------
static func letter() -> Array:
	return [
		_letter("Halo, Zhafran dan Sandho!", "PESAN DARURAT"),
		_letter("Aku Hafidz, Programmer di tim kita. Aku sedang terjebak di suatu tempat yang dipenuhi monster berbahaya. Aku butuh bantuan kalian!"),
		_letter("Untuk bisa sampai ke tempatku, kalian harus mengumpulkan koin dan mengalahkan monster-monster yang menghalangi jalan."),
		_letter("Aku yakin kita bisa melewati tantangan ini kalau kita bekerja sama.\n\nTolong segera temukan aku!"),
		_letter("— Hafidz"),
	]


# --------------------------------------------------------------------------
# 5. Portal
# --------------------------------------------------------------------------
static func portal_dialogue() -> Array:
	return [
		_speaker("sandho", "Wah, lihat! Ada portal yang muncul setelah kita membaca suratnya."),
		_speaker("zhafran", "Sepertinya portal ini adalah jalan menuju tempat Hafidz terjebak."),
		_speaker("sandho", "Kalau begitu, nggak ada waktu untuk berlama-lama. Kita harus menyelamatkannya!"),
		_speaker("zhafran", "Ayo! Kita selesaikan misi ini bersama-sama!"),
	]


# --------------------------------------------------------------------------
# 6. Map 2
# --------------------------------------------------------------------------
static func map2_intro() -> Array:
	return [
		_speaker("zhafran", "Wah, tempat ini berbahaya juga. Ada siput dan lebah di mana-mana!"),
		_speaker("sandho", "Kita harus berhati-hati. Kumpulkan koin yang ada dan kalahkan monster yang menghalangi jalan."),
		_speaker("zhafran", "Baiklah! Aku akan berusaha mengalahkan mereka dan menemukan Hafidz."),
		_speaker("sandho", "Semangat! Jangan lupa, kita harus saling membantu untuk menyelesaikan misi ini."),
	]


static func controls() -> Array:
	return [
		_narrator("Gunakan %s / %s untuk berjalan, %s untuk melompat, dan %s untuk menyerang. Tekan %s untuk berbicara atau membaca." % [UIKit.key_name("move_left"), UIKit.key_name("move_right"), UIKit.key_name("jump"), UIKit.key_name("attack"), UIKit.key_name("interact")], "PETUNJUK KONTROL"),
	]


static func attack_hint() -> Array:
	return [
		_narrator("Tekan %s untuk menyerang. Dekati monster lalu tekan tombol serang." % UIKit.key_name("attack"), "PETUNJUK"),
	]


static func rescue_incomplete(remaining: String) -> Array:
	return [
		_speaker("zhafran", "Hafidz! Akhirnya aku menemukanmu!"),
		_speaker("hafidz", "Zhafran! Sandho! Kalian datang juga!"),
		_speaker("zhafran", "Tunggu dulu, sepertinya masih ada tugas yang belum kita selesaikan."),
		_speaker("sandho", "Benar. Kita harus menyelesaikan misi terlebih dahulu sebelum membawa Hafidz keluar dari sini."),
		_narrator(remaining, "MISI BELUM SELESAI"),
	]


# --------------------------------------------------------------------------
# 7. Hafidz - Programmer
# --------------------------------------------------------------------------
static func hafidz_rescue() -> Array:
	return [
		_speaker("hafidz", "Akhirnya kalian berhasil menemukanku! Terima kasih banyak sudah datang untuk menyelamatkanku."),
		_speaker("hafidz", "Kenalin, aku Hafidz, Programmer di tim kita. Tugasku adalah menulis kode, mengembangkan mekanisme permainan, dan memastikan semua fitur dalam game bisa berjalan dengan baik."),
		_speaker("hafidz", "Ternyata, menghadapi tantangan seperti ini nggak bisa dilakukan sendirian. Kita benar-benar membutuhkan satu sama lain!"),
	]


# --------------------------------------------------------------------------
# 8. Ending
# --------------------------------------------------------------------------
static func final_teamwork() -> Array:
	return [
		_speaker("zhafran", "Petualangan ini mengajarkanku bahwa visual yang bagus akan menjadi lebih berarti ketika dipadukan dengan ide dan kerja sama seluruh anggota tim."),
		_speaker("sandho", "Dengan perencanaan yang baik, pembagian tugas yang jelas, dan koordinasi yang tepat, tantangan sesulit apa pun bisa kita hadapi bersama."),
		_speaker("hafidz", "Dan dengan pemrograman, kreativitas, serta kolaborasi, kita bisa mengubah ide menjadi sebuah game yang benar-benar bisa dimainkan!"),
		{
			"name": "Zhafran, Sandho, & Hafidz",
			"role": "Semua anggota tim",
			"portrait": GameState.member_portrait("zhafran"),
			"text": "Berbeda peran, satu tujuan. Bersama-sama, kita adalah tim yang solid!",
			"variant": "speech",
		},
	]


static func success_banner() -> Array:
	return [
		_narrator(BANNER_SUCCESS_TITLE, ""),
		_narrator(BANNER_SUCCESS_TEXT, ""),
	]


## Baris-baris kredit akhir. NIM diambil dari config/team.json, tidak pernah
## dikarang di dalam kode.
static func credits_lines() -> Array:
	var lines: Array = []
	lines.append({"kind": "title", "text": TITLE_GAME})
	lines.append({"kind": "subtitle", "text": SUBTITLE_GAME})
	lines.append({"kind": "gap"})
	for key in ["zhafran", "sandho", "hafidz"]:
		var m := GameState.member(key)
		var nim := GameState.member_nim(key)
		lines.append({"kind": "role", "text": String(m["role"]).to_upper()})
		lines.append({"kind": "name", "text": String(m["name"])})
		lines.append({"kind": "nim", "text": "NIM: " + (nim if not nim.is_empty() else "(belum diisi)")})
		lines.append({"kind": "gap"})
	lines.append({"kind": "body", "text": "Game ini dikembangkan menggunakan Godot Engine."})
	lines.append({"kind": "body", "text": "Terima kasih telah memainkan game ini!"})
	lines.append({"kind": "gap"})
	lines.append({"kind": "subtitle", "text": "Berbeda Peran, Satu Tujuan, Tim yang Solid."})
	return lines