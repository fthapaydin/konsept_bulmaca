#!/usr/bin/env python3
"""
Konsept Bulmaca — Otomatik Kare Bulmaca Üreteci ve Doğrulayıcısı (v2 — 20 Seviye / Konsept).

Kullanım:
    python tools/generate_puzzles.py

Her konsept paketi için oyuncuyu sıkmadan bağlayan 20 kademeli seviye
(5x5 -> 6x6 -> 7x7 -> 8x8), yüksek kesişimli, kopuksuz ve matematiksel
olarak doğrulanmış kare bulmacalar üretip assets/puzzles/ klasörüne yazar.
"""

from __future__ import annotations

import json
import random
from collections import deque
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets" / "puzzles"

TR_UPPER_MAP = str.maketrans({
    "i": "İ",
    "ı": "I",
    "ş": "Ş",
    "ğ": "Ğ",
    "ü": "Ü",
    "ö": "Ö",
    "ç": "Ç",
})

VALID_TR_CHARS = set("ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ")
VALID_EN_CHARS = set("ABCDEFGHIJKLMNOPQRSTUVWXYZ")


def normalize_word(word: str, lang: str) -> str:
    w = word.strip()
    if lang == "tr":
        w = w.translate(TR_UPPER_MAP).upper()
        bad = set(w) - VALID_TR_CHARS
    else:
        w = w.upper()
        bad = set(w) - VALID_EN_CHARS
    if bad:
        raise ValueError(f"Geçersiz karakter ({bad}) -> kelime: {word!r}, dil: {lang}")
    return w


# ---------------------------------------------------------------------------
# OPTİMUM 20 SEVİYELİ MOBİL AKICILIK EĞRİSİ (Her konsept için 20 bulmaca)
# (level, rows, cols, min_words, max_words, initial_reveals, difficulty_label, tier)
# ---------------------------------------------------------------------------
LEVEL_BLUEPRINTS = [
    # Başlangıç (5x5 — hızlı tatmin, 2 harf açık)
    (1,  5, 5,  4,  5, 2, "Başlangıç", 1),
    (2,  5, 5,  4,  5, 2, "Başlangıç", 1),
    (3,  5, 5,  4,  6, 2, "Başlangıç", 1),
    (4,  5, 5,  5,  6, 1, "Başlangıç", 1),
    # Kolay (6x6 — akıcı tempo, 1-2 harf açık)
    (5,  6, 6,  5,  6, 2, "Kolay",     1),
    (6,  6, 6,  5,  7, 1, "Kolay",     1),
    (7,  6, 6,  5,  7, 1, "Kolay",     1),
    (8,  6, 6,  6,  8, 1, "Kolay",     2),
    (9,  6, 6,  6,  8, 1, "Kolay",     2),
    # Orta (7x7 — mobilin altın boyutu, zengin kesişim)
    (10, 7, 7,  6,  8, 1, "Orta",      2),
    (11, 7, 7,  6,  9, 1, "Orta",      2),
    (12, 7, 7,  7,  9, 1, "Orta",      2),
    (13, 7, 7,  7,  9, 1, "Orta",      2),
    (14, 7, 7,  7, 10, 0, "Orta",      2),
    # Zorlu (7x7 -> 8x8 — sıfır açık harf, tatlı meydan okuma)
    (15, 7, 7,  7, 10, 0, "Zorlu",     2),
    (16, 8, 8,  8, 10, 0, "Zorlu",     3),
    (17, 8, 8,  8, 11, 0, "Zorlu",     3),
    # Usta (8x8 — final bölümü)
    (18, 8, 8,  8, 11, 0, "Usta",      3),
    (19, 8, 8,  8, 12, 0, "Usta",      3),
    (20, 8, 8,  8, 12, 0, "Usta",      3),
]

# ---------------------------------------------------------------------------
# 1) YEŞİLÇAM KLASİKLERİ (Genişletilmiş Havuz — 160+ kelime)
# ---------------------------------------------------------------------------
YESILCAM_WORDS: List[Tuple[str, str, int]] = [
    # Tier 1 — Herkesin bildiği efsane isimler, replikler ve filmler
    ("ŞABAN",    "Kemal Sunal'ın efsaneleştirdiği saf ve sevimli karakter", 1),
    ("KEMAL",    "Hababam'ın İnek Şaban'ı, büyük komedi ustası ... Sunal", 1),
    ("SUNAL",    "Gülen yüzüyle Türk sinemasına damga vuran Kemal ...", 1),
    ("ADİLE",    "Kuzucuklarım repliğiyle hafızalara kazınan ... Naşit", 1),
    ("NAŞİT",    "Hafize Ana rolüyle sevilen efsane oyuncu Adile ...", 1),
    ("MÜNİR",    "Mahmut Hoca ve Yaşar Usta'ya hayat veren ... Özkul", 1),
    ("ÖZKUL",    "Bizim Aile'nin Yaşar Usta'sı, Münir ...", 1),
    ("TARIK",    "Damat Ferit rolüyle gönülleri fetheden ... Akan", 1),
    ("AKAN",     "Hababam Sınıfı'nın yakışıklı jönü Tarık ...", 1),
    ("ŞENER",    "Badi Ekrem ve Ziya karakterlerinin ustası ... Şen", 1),
    ("TÜRKAN",   "Yeşilçam'ın Sultan lakaplı efsane yıldızı ... Şoray", 1),
    ("ŞORAY",    "Selvi Boylum Al Yazmalım'ın Asya'sı Türkan ...", 1),
    ("KADİR",    "Al Yazmalım'ın İlyas'ı, karizmatik jön ... İnanır", 1),
    ("FİLİZ",    "Sarışın zarafetiyle tanınan Yeşilçam yıldızı ... Akın", 1),
    ("FATMA",    "Dört Yapraklı Yonca'nın güçlü oyuncusu ... Girik", 1),
    ("GİRİK",    "Mavi gözleriyle tanınan usta sanatçı Fatma ...", 1),
    ("CÜNEYT",   "Malkoçoğlu ve Battal Gazi'nin yıldızı ... Arkın", 1),
    ("ARKIN",    "Dünyayı Kurtaran Adam'ın kahramanı Cüneyt ...", 1),
    ("HOCA",     "Hababam Sınıfı'nın disiplinli ama şefkatli Mahmut ...'sı", 1),
    ("ANA",      "Hababam'ın zili çalan şefkatli emekçisi Hafize ...", 1),
    ("AŞK",      "Yeşilçam melodramlarının vazgeçilmez ana duygusu", 1),
    ("FİLM",     "Beyaz perdede izlenen sinema eseri", 1),
    ("ROL",      "Oyuncunun kamera karşısında canlandırdığı karakter", 1),
    ("JÖN",      "Eski sinemada başroldeki yakışıklı erkek oyuncu", 1),
    ("SAHNE",    "Filmde tek bir mekan ve zamanda geçen bölüm", 1),
    ("PERDE",    "Sinema salonunda görüntünün yansıtıldığı beyaz yüzey", 1),
    ("BABA",     "Münir Özkul'un birçok filmde canlandırdığı aile reisi", 1),
    ("AİLE",     "Neşeli Günler ve Bizim ... filmlerinin kalbindeki bağ", 1),
    ("SEVGİ",    "Selvi Boylum'un ünlü sorusu: '... neydi? Emekti.'", 1),
    ("EMEK",     "Al Yazmalım'ın unutulmaz cevabı: 'Sevgi ... idi'", 1),
    ("ZİL",      "Hafize Ana'nın koridorda çalıp öğrencileri topladığı alet", 1),
    ("OKUL",     "Hababam Sınıfı'nın haylazlıklarının geçtiği mekan", 1),
    ("TURŞU",    "Neşeli Günler'de sirke mi limon mu kavgasının sebebi", 1),
    ("SİRKE",    "Neşeli Günler'de Kazım Efendi'nin turşu sırrı", 1),
    ("LİMON",    "Neşeli Günler'de Saadet Hanım'ın turşu tercihi", 1),
    ("SULTAN",   "Türkan Şoray'ın halk arasındaki efsane lakabı", 1),
    ("KRAL",     "Ayhan Işık'ın lakabı: Taçsız ...", 1),
    ("SELVİ",    "'... Boylum Al Yazmalım' başyapıtının ilk kelimesi", 1),
    ("ASYA",     "Al Yazmalım'da Türkan Şoray'ın canlandırdığı karakter", 1),
    ("İLYAS",    "Al Yazmalım'da kırmızı kamyonlu şoför karakter", 1),
    ("TOSUN",    "Tellioğulları ve Seferoğulları'nın meşhur '... Paşa'sı", 1),
    ("PAŞA",     "Şaban'ın kılığına girdiği meşhur Tosun ...", 1),
    ("HABABAM",  "Rıfat Ilgaz'ın eserinden uyarlanan efsane lise serisi", 1),
    ("ZİYA",     "Neşeli Günler'de aslan avı uyduran palaveracı amca", 1),
    ("VECİHİ",   "Gülen Gözler'de uçağıyla eve dalan aşık pilot", 1),
    ("MAHMUT",   "Özel Çamlıca Lisesi'nin efsane müdür yardımcısı Kel ...", 1),
    ("FERİT",    "Hababam Sınıfı'nın çapkın öğrencisi Damat ...", 1),
    ("NECMİ",    "Halit Akçatepe'nin canlandırdığı Güdük ...", 1),
    ("BADİ",     "Şener Şen'in canlandırdığı beden öğretmeni ... Ekrem", 1),
    ("EKREM",    "Kırmızı eşofmanlı beden öğretmeni Badi ...", 1),
    ("SET",      "Film çekimlerinin yapıldığı çalışma alanı", 1),
    ("SES",      "Yeşilçam'da stüdyoda sonradan kaydedilen konuşma", 1),
    ("STAR",     "Dönemin en parlak sinema yıldızı", 1),
    ("DRAM",     "Gözyaşlarıyla izlenen duygusal sinema türü", 1),
    ("YAZ",      "Açık hava sinemalarının kurulduğu mevsim", 1),
    ("GAZOZ",    "Yazlık sinemalarda çekirdek yanında içilen serin içecek", 1),
    ("BİLET",    "Sinema gişesinden salona girmek için alınan kağıt", 1),
    ("GİŞE",     "Sinema girişinde bilet satılan küçük pencere", 1),
    ("KOLTUK",   "Sinema salonunda film izlenen kadife oturak", 1),
    ("SOKAK",    "Beyoğlu'nda sinemacıların toplandığı Yeşilçam ...'ı", 1),

    # Tier 2 — Filmler, ikonik karakterler, müzik ve sinema kültürü
    ("GÜLŞEN",   "Ah Nerede ve Girgirye'nin yıldızı ... Bubikoğlu", 2),
    ("HALİT",    "Güdük Necmi'yi canlandıran usta oyuncu ... Akçatepe", 2),
    ("AYŞEN",    "Domates Güzeli lakaplı komedi ustası ... Gruda", 2),
    ("GRUDA",    "Tosun Paşa ve Çöpçüler Kralı'nın yıldızı Ayşen ...", 2),
    ("SALMAN",   "Çiçek Abbas'ın minibüs şoförü İlyas ...", 2),
    ("ABBAS",    "Şakir ile atışan efsane minibüs şoförü Çiçek ...", 2),
    ("ŞAKİR",    "Çiçek Abbas'ta Şener Şen'in oynadığı kurnaz şoför", 2),
    ("FEYZO",    "Ağaya baş kaldıran ünlü film karakteri Kibar ...", 2),
    ("KİBAR",    "Başrolünde Kemal Sunal'ın olduğu '... Feyzo' filmi", 2),
    ("BİLO",     "Münih diye İstanbul'a bırakılan Banker ...", 2),
    ("BANKER",   "Şener Şen'in Maho rolüyle parladığı '... Bilo' filmi", 2),
    ("MAHO",     "Köylüleri kandıran meşhur sahtekar ... Ağa", 2),
    ("AĞA",      "Kibar Feyzo ve Züğürt ... filmlerindeki toprak sahibi", 2),
    ("ZÜĞÜRT",   "Şener Şen'in başyapıtlarından '... Ağa'", 2),
    ("ZÜBÜK",    "Aziz Nesin uyarlaması politik taşlama filmi", 2),
    ("DAVARO",   "Kan davası hicvi yapan 1981 yapımı Kemal Sunal filmi", 2),
    ("SALAKO",   "Ağanın kızını kaçıran saf karakterin filmi", 2),
    ("TULUM",    "Hababam Sınıfı'nın iriyarı öğrencisi ... Hayri", 2),
    ("HAYRİ",    "Hababam'ın güçlü kuvvetli öğrencisi Tulum ...", 2),
    ("GÜDÜK",    "Sınıfın en ufak tefek ve kurnaz öğrencisi ... Necmi", 2),
    ("DAMAT",    "Tarık Akan'ın Hababam'daki unutulmaz lakabı ... Ferit", 2),
    ("HAFİZE",   "Hababam Sınıfı'nın sevecen hademesi ... Ana", 2),
    ("YAŞAR",    "Bizim Aile'nin 'Bak beyim!' tiradını atan ... Usta", 2),
    ("USTA",     "Münir Özkul'un efsane repliğindeki karakter: Yaşar ...", 2),
    ("KAZIM",    "Neşeli Günler'de turşucu baba ... Efendi", 2),
    ("SAADET",   "Neşeli Günler'de Adile Naşit'in oynadığı anne", 2),
    ("GÜLEN",    "Münir Özkul ve Vecihi'nin yer aldığı '... Gözler' filmi", 2),
    ("GÖZLER",   "Şener Şen'in de rol aldığı aile komedisi: Gülen ...", 2),
    ("NEŞELİ",   "Ayrılan turşucu çiftin çocuklarının hikayesi: ... Günler", 2),
    ("BATTAL",   "Cüneyt Arkın'ın tarihi kahramanı ... Gazi", 2),
    ("GAZİ",     "Bizans kalelerini tek başına fetheden Battal ...", 2),
    ("TARKAN",   "Kartal Tibet'in kurtlu çizgi roman kahramanı", 2),
    ("KARTAL",   "Hem oyuncu hem yönetmen usta isim ... Tibet", 2),
    ("TİBET",    "Tosun Paşa'nın yönetmeni, Tarkan'ın yıldızı Kartal ...", 2),
    ("EDİZ",     "Yeşilçam'ın beyefendi jönü ... Hun", 2),
    ("AYHAN",    "Taçsız Kral unvanlı efsane aktör ... Işık", 2),
    ("IŞIK",     "Küçük Hanımefendi'nin başrolü Ayhan ...", 2),
    ("BELGİN",   "Küçük Hanımefendi'nin unutulmaz yıldızı ... Doruk", 2),
    ("DORUK",    "Yeşilçam'ın zarif divası Belgin ...", 2),
    ("EMEL",     "Mavi Boncuk'un kaçırılan şarkıcısı ... Sayın", 2),
    ("SAYIN",    "Mavi Boncuk'un unutulmaz sesi Emel ...", 2),
    ("BONCUK",   "Altı arkadaşın halı içinde kaçırdığı şarkıcı: Mavi ...", 2),
    ("MAVİ",     "Emel Sayın'ın başrol oynadığı '... Boncuk' filmi", 2),
    ("HALI",     "Mavi Boncuk filminde şarkıcıyı sakladıkları eşya", 2),
    ("SÜT",      "Gulyabani korkusunun yaşandığı '... Kardeşler' filmi", 2),
    ("RAMAZAN",  "Süt Kardeşler'de kumandanın evine gelen şaşkın asker", 2),
    ("SİNEMA",   "Yeşilçam sokağının kalbinin attığı yedinci sanat", 2),
    ("REPLİK",   "Filmlerde hafızalara kazınan unutulmaz söz", 2),
    ("KAMERA",   "Sette 'Motor!' komutuyla kayda giren cihaz", 2),
    ("AFİŞ",     "Sinema girişlerini süsleyen elle boyanmış film posteri", 2),
    ("DUBLAJ",   "Eski Türk filmlerinde karakterlere sonradan ses verme", 2),
    ("SENARYO",  "Filmin diyalog ve sahnelerini içeren yazılı metin", 2),
    ("KASET",    "80'lerde evlerde Yeşilçam izlenen video şeridi", 2),
    ("BEYOĞLU",  "Yeşilçam Sokağı'nın bulunduğu tarihi İstanbul semti", 2),
    ("ŞOFÖR",    "Kamyon veya minibüs direksiyonundaki Yeşilçam kahramanı", 2),
    ("DOMATES",  "Ayşen Gruda'nın efsane lakabı: ... Güzeli", 2),
    ("MİNİBÜS",  "Çiçek Abbas ile Şakir'in yarıştığı ulaşım aracı", 2),
    ("KOPYA",    "Hababam öğrencilerinin sınavda başvurduğu hile", 2),
    ("TÜNEL",    "Hababam Sınıfı'nda bahçeye kaçmak için kazılan geçit", 2),
    ("KAMP",     "Hababam Sınıfı'nın izcilik maceralarının geçtiği yer", 2),
    ("UÇAK",     "Vecihi'nin sevgilisi Fikret için uçurduğu araç", 2),
    ("FİKRET",   "Gülen Gözler'de Vecihi'nin aşık olduğu genç kız", 2),
    ("ÇİÇEK",    "İlyas Salman'ın efsane şoför filmi: ... Abbas", 2),
    ("GAZİNO",   "Mavi Boncuk'ta Emel Sayın'ın sahne aldığı mekan", 2),
    ("ALTIN",    "Köyden İndim Şehire'de kardeşlerin bulduğu define", 2),
    ("KÖYLÜ",    "Şehre gelen saf ve temiz kalpli Yeşilçam karakteri", 2),

    # Tier 3 — Derin Yeşilçam kültürü, yönetmenler, unutulmaz detaylar
    ("ATIF",     "Selvi Boylum Al Yazmalım'ın usta yönetmeni ... Yılmaz", 3),
    ("YILMAZ",   "Usta yönetmenler: Atıf ... ve ... Güney", 3),
    ("ERTEM",    "Hababam Sınıfı'nın efsane yönetmeni ... Eğilmez", 3),
    ("EĞİLMEZ",  "Arzu Film'in kurucusu ve yönetmeni Ertem ...", 3),
    ("ARZU",     "Hababam ve Tosun Paşa'yı çeken efsane şirket ... Film", 3),
    ("METİN",    "Susuz Yaz ile Altın Ayı kazanan yönetmen ... Erksan", 3),
    ("ERKSAN",   "Sevmek Zamanı'nın yönetmeni Metin ...", 3),
    ("SUSUZ",    "Berlin'de Altın Ayı kazanan ilk Türk filmi: ... Yaz", 3),
    ("VESİKA",   "Türkan Şoray ve İzzet Günay'ın klasiği: ...lı Yarim", 3),
    ("YARİM",    "Lütfi Akad başyapıtı: Vesikalı ...", 3),
    ("MÜJDE",    "Arabesk ve Aaahh Belinda'nın yıldızı ... Ar", 3),
    ("ZEKİ",     "Metin Akpınar'ın sahne ve film partneri ... Alasya", 3),
    ("ALASYA",   "Köyden İndim Şehire'nin yıldızlarından Zeki ...", 3),
    ("AKPINAR",  "Zeki Alasya ile efsane ikili kuran Metin ...", 3),
    ("SADRİ",    "Turist Ömer karakterinin yaratıcısı ... Alışık", 3),
    ("ALIŞIK",   "Ofsayt Osman ve Turist Ömer'in ustası Sadri ...", 3),
    ("TURİST",   "Sadri Alışık'ın selamıyla ünlü serisi: ... Ömer", 3),
    ("ÖMER",     "Uzay Yolu'na bile giden gezgin karakter Turist ...", 3),
    ("HULUSİ",   "Tonton dede ve fabrikatör rollerinin ustası ... Kentmen", 3),
    ("KENTMEN",  "Bıyıklı ve babacan komiser rollerinin ustası Hulusi ...", 3),
    ("EROL",     "Kötü adam rolleriyle efsaneleşen ... Taş", 3),
    ("NUBAR",    "Sıcakkanlı baba ve usta rollerinin oyuncusu ... Terziyan", 3),
    ("MÜMTAZ",   "Yeşilçam'ın karakter oyuncusu ... Ener", 3),
    ("PERİHAN",  "Küçük Besleme ve dramaların yıldızı ... Savaş", 3),
    ("SAVAŞ",    "Usta aktris Perihan ...", 3),
    ("NECLA",    "Çalıkuşu ve Ateş Böceği'nin yıldızı ... Nazır", 3),
    ("NAZIR",    "Ferdi Tayfur filmlerinin başrolü Necla ...", 3),
    ("HALE",     "Oh Olsun ve Canım Kardeşim'in yıldızı ... Soygazi", 3),
    ("CEMİL",    "Al Yazmalım'da Asya'ya kol kanat geren iyi kalpli adam", 3),
    ("SAMET",    "Al Yazmalım'da Asya ile İlyas'ın küçük oğlu", 3),
    ("KAMYON",   "İlyas'ın kırmızı 'Aldırma Gönül' yazılı aracı", 3),
    ("ÇÖPÇÜ",    "Kemal Sunal'ın Apti rolüyle oynadığı '...ler Kralı'", 3),
    ("APTİ",     "Çöpçüler Kralı'nda Hacer'e aşık temizlik işçisi", 3),
    ("HACER",    "Çöpçüler Kralı'nda Ayşen Gruda'nın canlandırdığı karakter", 3),
    ("ZABITA",   "Çöpçüler Kralı'nda Şener Şen'in oynadığı amir", 3),
    ("VİLLA",    "Yeşilçam'da zengin fabrikatörlerin yaşadığı köşk", 3),
    ("KÖŞK",     "Tosun Paşa'da Tellioğulları'nın uğruna yarıştığı malikane", 3),
    ("YEŞİL",    "Tellioğulları ve Seferoğulları'nın paylaştığı '... Vadi'", 3),
    ("VADİ",     "Tosun Paşa'da iki ailenin uğruna kapıştığı Yeşil ...", 3),
    ("HAMAM",    "Tosun Paşa'da iki ailenin karşılaştığı meşhur mekan", 3),
    ("LEYLA",    "Tosun Paşa'da Daver Bey'in güzel kızı", 3),
    ("DAVER",    "Tosun Paşa'da Leyla'nın babası ... Bey", 3),
    ("KONAK",    "Süt Kardeşler'de Melek Hanım'ın yaşadığı büyük ev", 3),
    ("MELEK",    "Süt Kardeşler'de Adile Naşit'in canlandırdığı hanım", 3),
    ("CAHİT",    "Al Yazmalım'ın efsane müziğini besteleyen ... Berkay", 3),
    ("BERKAY",   "Moğollar üyesi ve film müziği bestecisi Cahit ...", 3),
    ("MELİH",    "Hababam Sınıfı'nın unutulmaz müziğinin bestecisi ... Kibar", 3),
    ("ARABESK",  "Şener Şen ve Müjde Ar'lı unutulmaz parodi filmi", 3),
    ("MUHSİN",   "Şener Şen'in müzik yapımcısını oynadığı '... Bey'", 3),
    ("EŞKIYA",   "90'larda Türk sinemasını yeniden ayağa kaldıran başyapıt", 3),
    ("BARAN",    "Eşkıya filminde Şener Şen'in canlandırdığı karakter", 3),
    ("KEJE",     "Eşkıya'da Baran'ın 35 yıl beklediği sevdası", 3),
    ("PLATO",    "Film çekimlerinin yapıldığı dekorlu stüdyo alanı", 3),
    ("FİGÜRAN",  "Sahnelerde arka planda yer alan yardımcı oyuncu", 3),
    ("KLAKET",   "Sahne çekimi başında şaklatılan tahta levha", 3),
    ("GALA",     "Yeni bir filmin ilk özel gösterim gecesi", 3),
    ("AKIN",     "Dört Yapraklı Yonca'nın zarif yıldızı Filiz ...", 3),
    ("İNANIR",   "Tatar Ramazan ve Al Yazmalım'ın başrolü Kadir ...", 3),
    ("GÜNEY",    "Yol ve Umut filmleriyle bilinen sinemacı Yılmaz ...", 3),
    ("ORHAN",    "Batsın Bu Dünya filminin yıldızı ... Gencebay", 3),
    ("FERDİ",    "Çeşme ve Derbeder filmlerinin yıldızı ... Tayfur", 3),
    ("ÖZTÜRK",   "Şaka ile Karışık'ın efsane komedyeni ... Serengil", 3),
    ("İZZET",    "Vesikalı Yarim'in manav Halil'i ... Günay", 3),
    ("GÜNAY",    "Yeşilçam'ın zarif jönü İzzet ...", 3),
    ("ŞEVKET",   "Süt Kardeşler'in kahramanlarından ... Altuğ", 3),
    ("ALTUĞ",    "Perihan Abla ve Süper Baba'nın yıldızı Şevket ...", 3),
    ("PERRAN",   "Gırgıriye ve Köyden İndim Şehire'nin yıldızı ... Kutman", 3),
    ("KUTMAN",   "Hayat Bilgisi ve Yeşilçam'ın ustası Perran ...", 3),
    ("İHSAN",    "Kibar Feyzo ve Çiçek Abbas'ın karakter oyuncusu ... Yüce", 3),
    ("KUDRET",   "Kötü adam ve fedai rollerinin tanınan yüzü ... Karadağ", 3),
    ("YÖNETMEN", "Sette 'Kestik!' ve 'Motor!' diyen baş sorumlu", 3),
]

# ---------------------------------------------------------------------------
# 2) İNGİLİZCE KELİME AVI (Türkiye'de herkesin severek çözebileceği A1 - A2 - Basit B1!)
# ---------------------------------------------------------------------------
INGILIZCE_WORDS: List[Tuple[str, str, int]] = [
    # Tier 1 — A1 Çok Bilinen Temel Kelimeler
    ("HELLO",    "Merhaba (A1)", 1),
    ("THANK",    "Teşekkür etmek (A1)", 1),
    ("SORRY",    "Üzgünüm, pardon (A1)", 1),
    ("HAPPY",    "Mutlu (A1)", 1),
    ("APPLE",    "Elma (A1)", 1),
    ("WATER",    "Su (A1)", 1),
    ("HOUSE",    "Ev (A1)", 1),
    ("HOME",     "Yuva, ev (A1)", 1),
    ("BOOK",     "Kitap (A1)", 1),
    ("TREE",     "Ağaç (A1)", 1),
    ("STAR",     "Yıldız (A1)", 1),
    ("MOON",     "Ay (gök cismi) (A1)", 1),
    ("SUN",      "Güneş (A1)", 1),
    ("CAT",      "Kedi (A1)", 1),
    ("DOG",      "Köpek (A1)", 1),
    ("CAR",      "Araba (A1)", 1),
    ("BUS",      "Otobüs (A1)", 1),
    ("TAXI",     "Taksi (A1)", 1),
    ("DAY",      "Gün (A1)", 1),
    ("NIGHT",    "Gece (A1)", 1),
    ("KEY",      "Anahtar (A1)", 1),
    ("TEA",      "Çay (A1)", 1),
    ("CAFE",     "Kafe (A1)", 1),
    ("MENU",     "Yemek listesi, menü (A1)", 1),
    ("MAP",      "Harita (A1)", 1),
    ("PEN",      "Tükenmez kalem (A1)", 1),
    ("HAT",      "Şapka (A1)", 1),
    ("BED",      "Yatak (A1)", 1),
    ("CUP",      "Fincan, kupa (A1)", 1),
    ("SEA",      "Deniz (A1)", 1),
    ("SKY",      "Gökyüzü (A1)", 1),
    ("RED",      "Kırmızı (A1)", 1),
    ("BLUE",     "Mavi (A1)", 1),
    ("GREEN",    "Yeşil (A1)", 1),
    ("WHITE",    "Beyaz (A1)", 1),
    ("BLACK",    "Siyah (A1)", 1),
    ("GOLD",     "Altın (A1)", 1),
    ("COLOR",    "Renk (A1)", 1),
    ("MILK",     "Süt (A1)", 1),
    ("CAKE",     "Pasta, kek (A1)", 1),
    ("PIZZA",    "Pizza (A1)", 1),
    ("PASTA",    "Makarna (A1)", 1),
    ("SALAD",    "Salata (A1)", 1),
    ("SALT",     "Tuz (A1)", 1),
    ("FISH",     "Balık (A1)", 1),
    ("BIRD",     "Kuş (A1)", 1),
    ("DOOR",     "Kapı (A1)", 1),
    ("HAND",     "El (A1)", 1),
    ("FOOD",     "Yiyecek (A1)", 1),
    ("TIME",     "Zaman (A1)", 1),
    ("NAME",     "İsim, ad (A1)", 1),
    ("RAIN",     "Yağmur (A1)", 1),
    ("SNOW",     "Kar (A1)", 1),
    ("WIND",     "Rüzgar (A1)", 1),
    ("FIRE",     "Ateş (A1)", 1),
    ("ROAD",     "Yol (A1)", 1),
    ("CITY",     "Şehir (A1)", 1),
    ("PARK",     "Park (A1)", 1),
    ("BANK",     "Banka (A1)", 1),
    ("SHOP",     "Mağaza, dükkan (A1)", 1),
    ("LOVE",     "Sevgi, aşk (A1)", 1),
    ("WORK",     "İş, çalışmak (A1)", 1),
    ("PLAY",     "Oynamak, oyun (A1)", 1),
    ("GAME",     "Oyun (A1)", 1),
    ("TEAM",     "Takım (A1)", 1),
    ("GOAL",     "Gol, hedef (A1)", 1),
    ("SPORT",    "Spor (A1)", 1),
    ("READ",     "Okumak (A1)", 1),
    ("WALK",     "Yürümek (A1)", 1),
    ("SWIM",     "Yüzmek (A1)", 1),
    ("OPEN",     "Açık, açmak (A1)", 1),
    ("START",    "Başlamak (A1)", 1),
    ("FAST",     "Hızlı (A1)", 1),
    ("EASY",     "Kolay (A1)", 1),
    ("COLD",     "Soğuk (A1)", 1),
    ("WARM",     "Ilık, sıcak (A1)", 1),
    ("DARK",     "Karanlık, koyu (A1)", 1),
    ("GOOD",     "İyi (A1)", 1),
    ("SMALL",    "Küçük (A1)", 1),
    ("SHORT",    "Kısa (A1)", 1),
    ("LONG",     "Uzun (A1)", 1),
    ("SHIP",     "Gemi (A1)", 1),
    ("SONG",     "Şarkı (A1)", 1),
    ("KING",     "Kral (A1)", 1),
    ("HERO",     "Kahraman (A1)", 1),
    ("BEAR",     "Ayı (A1)", 1),
    ("LION",     "Aslan (A1)", 1),
    ("WOLF",     "Kurt (A1)", 1),
    ("ROSE",     "Gül (A1)", 1),
    ("LAKE",     "Göl (A1)", 1),
    ("YEAR",     "Yıl, sene (A1)", 1),
    ("WEEK",     "Hafta (A1)", 1),
    ("RING",     "Yüzük, zil sesi (A1)", 1),
    ("GIFT",     "Hediye (A1)", 1),
    ("BOSS",     "Patron (A1)", 1),
    ("CHEF",     "Aşçı, şef (A1)", 1),
    ("EXAM",     "Sınav (A1)", 1),

    # Tier 2 — A2 Günlük Yaşam, Teknoloji, Seyahat, Mutfak
    ("PLEASE",   "Lütfen (A2)", 2),
    ("MONEY",    "Para (A2)", 2),
    ("PRICE",    "Fiyat (A2)", 2),
    ("COFFEE",   "Kahve (A2)", 2),
    ("BREAD",    "Ekmek (A2)", 2),
    ("SUGAR",    "Şeker (A2)", 2),
    ("HONEY",    "Bal (A2)", 2),
    ("LEMON",    "Limon (A2)", 2),
    ("CHEESE",   "Peynir (A2)", 2),
    ("BUTTER",   "Tereyağı (A2)", 2),
    ("BANANA",   "Muz (A2)", 2),
    ("TOMATO",   "Domates (A2)", 2),
    ("POTATO",   "Patates (A2)", 2),
    ("CHERRY",   "Kiraz (A2)", 2),
    ("CARROT",   "Havuç (A2)", 2),
    ("PEPPER",   "Biber (A2)", 2),
    ("ORANGE",   "Portakal, turuncu (A2)", 2),
    ("YELLOW",   "Sarı (A2)", 2),
    ("PURPLE",   "Mor (A2)", 2),
    ("SILVER",   "Gümüş (A2)", 2),
    ("TIGER",    "Kaplan (A2)", 2),
    ("HORSE",    "At (A2)", 2),
    ("EAGLE",    "Kartal (A2)", 2),
    ("SHARK",    "Köpekbalığı (A2)", 2),
    ("MONKEY",   "Maymun (A2)", 2),
    ("RABBIT",   "Tavşan (A2)", 2),
    ("ANIMAL",   "Hayvan (A2)", 2),
    ("FLOWER",   "Çiçek (A2)", 2),
    ("CLOCK",    "Duvar/masa saati (A2)", 2),
    ("WATCH",    "Kol saati, izlemek (A2)", 2),
    ("PHONE",    "Telefon (A2)", 2),
    ("EMAIL",    "E-posta (A2)", 2),
    ("PHOTO",    "Fotoğraf (A2)", 2),
    ("VIDEO",    "Video (A2)", 2),
    ("CAMERA",   "Kamera, fotoğraf makinesi (A2)", 2),
    ("SCREEN",   "Ekran (A2)", 2),
    ("BUTTON",   "Düğme, buton (A2)", 2),
    ("ONLINE",   "Çevrimiçi (A2)", 2),
    ("SEARCH",   "Aramak, arama (A2)", 2),
    ("SHARE",    "Paylaşmak (A2)", 2),
    ("TABLE",    "Masa (A2)", 2),
    ("CHAIR",    "Sandalye (A2)", 2),
    ("PILLOW",   "Yastık (A2)", 2),
    ("MIRROR",   "Ayna (A2)", 2),
    ("WINDOW",   "Pencere (A2)", 2),
    ("GLASS",    "Cam, bardak (A2)", 2),
    ("LIGHT",    "Işık, hafif (A2)", 2),
    ("MUSIC",    "Müzik (A2)", 2),
    ("MOVIE",    "Sinema filmi (A2)", 2),
    ("CINEMA",   "Sinema salonu (A2)", 2),
    ("ACTOR",    "Oyuncu, aktör (A2)", 2),
    ("STAGE",    "Sahne (A2)", 2),
    ("STORY",    "Hikaye, öykü (A2)", 2),
    ("RADIO",    "Radyo (A2)", 2),
    ("SOUND",    "Ses (A2)", 2),
    ("VOICE",    "İnsan sesi (A2)", 2),
    ("DREAM",    "Rüya, hayal (A2)", 2),
    ("SMILE",    "Gülümseme (A2)", 2),
    ("HEART",    "Kalp, yürek (A2)", 2),
    ("MAGIC",    "Sihir, büyü (A2)", 2),
    ("QUEEN",    "Kraliçe (A2)", 2),
    ("EARTH",    "Dünya, toprak (A2)", 2),
    ("WORLD",    "Dünya (A2)", 2),
    ("SPACE",    "Uzay, boşluk (A2)", 2),
    ("CLOUD",    "Bulut (A2)", 2),
    ("STORM",    "Fırtına (A2)", 2),
    ("RIVER",    "Nehir, ırmak (A2)", 2),
    ("OCEAN",    "Okyanus (A2)", 2),
    ("BEACH",    "Plaj, sahil (A2)", 2),
    ("ISLAND",   "Ada (A2)", 2),
    ("FOREST",   "Orman (A2)", 2),
    ("GARDEN",   "Bahçe (A2)", 2),
    ("DESERT",   "Çöl (A2)", 2),
    ("TRAIN",    "Tren (A2)", 2),
    ("METRO",    "Metro (A2)", 2),
    ("PLANE",    "Uçak (A2)", 2),
    ("FLIGHT",   "Uçuş (A2)", 2),
    ("TICKET",   "Bilet (A2)", 2),
    ("HOTEL",    "Otel (A2)", 2),
    ("TRAVEL",   "Seyahat etmek (A2)", 2),
    ("BRIDGE",   "Köprü (A2)", 2),
    ("STREET",   "Sokak, cadde (A2)", 2),
    ("SQUARE",   "Meydan, kare (A2)", 2),
    ("MARKET",   "Pazar, market (A2)", 2),
    ("MUSEUM",   "Müze (A2)", 2),
    ("CASTLE",   "Kale, şato (A2)", 2),
    ("TOWER",    "Kule (A2)", 2),
    ("OFFICE",   "Ofis, büro (A2)", 2),
    ("SCHOOL",   "Okul (A2)", 2),
    ("CLASS",    "Sınıf, ders (A2)", 2),
    ("LESSON",   "Ders (A2)", 2),
    ("FRIEND",   "Arkadaş (A2)", 2),
    ("FAMILY",   "Aile (A2)", 2),
    ("MOTHER",   "Anne (A2)", 2),
    ("FATHER",   "Baba (A2)", 2),
    ("SISTER",   "Kız kardeş (A2)", 2),
    ("DOCTOR",   "Doktor (A2)", 2),
    ("NURSE",    "Hemşire (A2)", 2),
    ("PILOT",    "Pilot (A2)", 2),
    ("ARTIST",   "Sanatçı (A2)", 2),
    ("WINTER",   "Kış mevsimi (A2)", 2),
    ("SUMMER",   "Yaz mevsimi (A2)", 2),
    ("SPRING",   "İlkbahar (A2)", 2),
    ("SUNDAY",   "Pazar günü (A2)", 2),
    ("MONDAY",   "Pazartesi (A2)", 2),
    ("FRIDAY",   "Cuma günü (A2)", 2),
    ("LUNCH",    "Öğle yemeği (A2)", 2),
    ("DINNER",   "Akşam yemeği (A2)", 2),
    ("JACKET",   "Ceket (A2)", 2),
    ("SHIRT",    "Gömlek (A2)", 2),
    ("SHOES",    "Ayakkabı (A2)", 2),
    ("POCKET",   "Cep (A2)", 2),
    ("LETTER",   "Mektup, harf (A2)", 2),
    ("PAPER",    "Kağıt (A2)", 2),
    ("STONE",    "Taş (A2)", 2),
    ("METAL",    "Metal (A2)", 2),
    ("CLEAN",    "Temiz (A2)", 2),
    ("FRESH",    "Taze, ferah (A2)", 2),
    ("SWEET",    "Tatlı, şekerli (A2)", 2),
    ("READY",    "Hazır (A2)", 2),
    ("LARGE",    "Büyük, geniş (A2)", 2),
    ("SMART",    "Akıllı, zeki (A2)", 2),
    ("LUCKY",    "Şanslı (A2)", 2),
    ("STRONG",   "Güçlü (A2)", 2),
    ("SIMPLE",   "Basit, sade (A2)", 2),
    ("FINISH",   "Bitirmek, son (A2)", 2),

    # Tier 3 — Basit ve Bilindik B1 Kelimeler (Günlük İngilizceden tanıdık)
    ("MORNING",  "Sabah (A2-B1)", 3),
    ("KITCHEN",  "Mutfak (A2-B1)", 3),
    ("BEDROOM",  "Yatak odası (A2-B1)", 3),
    ("TEACHER",  "Öğretmen (A2-B1)", 3),
    ("STUDENT",  "Öğrenci (A2-B1)", 3),
    ("BROTHER",  "Erkek kardeş (A2-B1)", 3),
    ("CONCERT",  "Konser (A2-B1)", 3),
    ("PLANET",   "Gezegen (B1)", 3),
    ("ROCKET",   "Roket (B1)", 3),
    ("ROBOT",    "Robot (B1)", 3),
    ("NATURE",   "Doğa (B1)", 3),
    ("ENERGY",   "Enerji (B1)", 3),
    ("POWER",    "Güç (B1)", 3),
    ("SPEED",    "Hız (B1)", 3),
    ("FUTURE",   "Gelecek (B1)", 3),
    ("MEMORY",   "Hafıza, anı (B1)", 3),
    ("FREEDOM",  "Özgürlük (B1)", 3),
    ("SUCCESS",  "Başarı (B1)", 3),
    ("SUPPORT",  "Destek (B1)", 3),
    ("SERVICE",  "Hizmet, servis (B1)", 3),
    ("QUALITY",  "Kalite (B1)", 3),
    ("DESIGN",   "Tasarım (B1)", 3),
    ("STYLE",    "Stil, tarz (B1)", 3),
    ("TREND",    "Eğilim, moda akımı (B1)", 3),
    ("BRAND",    "Marka (B1)", 3),
    ("TARGET",   "Hedef (B1)", 3),
    ("WINNER",   "Kazanan, galip (B1)", 3),
    ("LEADER",   "Lider, önder (B1)", 3),
    ("CHOICE",   "Seçim, tercih (B1)", 3),
    ("CHANCE",   "Şans, fırsat (B1)", 3),
    ("CHANGE",   "Değişim, değiştirmek (B1)", 3),
    ("REASON",   "Sebep, neden (B1)", 3),
    ("RESULT",   "Sonuç (B1)", 3),
    ("ANSWER",   "Cevap, yanıt (B1)", 3),
    ("SIGNAL",   "Sinyal, işaret (B1)", 3),
    ("SYSTEM",   "Sistem (B1)", 3),
    ("MODERN",   "Çağdaş, modern (B1)", 3),
    ("GLOBAL",   "Küresel (B1)", 3),
    ("PUBLIC",   "Halka açık, kamu (B1)", 3),
    ("SOCIAL",   "Sosyal, toplumsal (B1)", 3),
    ("ACTIVE",   "Aktif, hareketli (B1)", 3),
    ("NORMAL",   "Normal, olağan (B1)", 3),
    ("PERFECT",  "Mükemmel, kusursuz (B1)", 3),
    ("SPECIAL",  "Özel (B1)", 3),
    ("POPULAR",  "Popüler, sevilen (B1)", 3),
    ("NATURAL",  "Doğal (B1)", 3),
    ("CLASSIC",  "Klasik (B1)", 3),
    ("DIGITAL",  "Dijital, sayısal (B1)", 3),
    ("NETWORK",  "Ağ, şebeke (B1)", 3),
    ("HISTORY",  "Tarih (B1)", 3),
    ("SCIENCE",  "Bilim (B1)", 3),
    ("CULTURE",  "Kültür (B1)", 3),
    ("LIBRARY",  "Kütüphane (B1)", 3),
    ("THEATER",  "Tiyatro (B1)", 3),
    ("FACTORY",  "Fabrika (B1)", 3),
    ("MACHINE",  "Makine (B1)", 3),
    ("BATTERY",  "Pil, batarya (B1)", 3),
    ("JOURNEY",  "Yolculuk (B1)", 3),
    ("HOLIDAY",  "Tatil, bayram (B1)", 3),
    ("WEATHER",  "Hava durumu (B1)", 3),
    ("BALANCE",  "Denge (B1)", 3),
    ("DIAMOND",  "Elmas (B1)", 3),
    ("CRYSTAL",  "Kristal (B1)", 3),
    ("CAPTAIN",  "Kaptan (B1)", 3),
    ("MESSAGE",  "Mesaj, ileti (B1)", 3),
    ("PROJECT",  "Proje (B1)", 3),
    ("PROGRAM",  "Program (B1)", 3),
    ("PROBLEM",  "Sorun, problem (B1)", 3),
    ("PRODUCT",  "Ürün (B1)", 3),
    ("COMPANY",  "Şirket, firma (B1)", 3),
    ("MANAGER",  "Yönetici, müdür (B1)", 3),
    ("PARTNER",  "Ortak, eş (B1)", 3),
    ("COUNTRY",  "Ülke (B1)", 3),
    ("VILLAGE",  "Köy (B1)", 3),
    ("CAPITAL",  "Başkent (B1)", 3),
    ("STATION",  "İstasyon, durak (B1)", 3),
    ("AIRPORT",  "Havalimanı (B1)", 3),
    ("PASSPORT", "Pasaport (B1)", 3),
    ("CALENDAR", "Takvim (B1)", 3),
    ("COMPUTER", "Bilgisayar (B1)", 3),
    ("INTERNET", "İnternet (B1)", 3),
    ("LANGUAGE", "Dil, lisan (B1)", 3),
    ("FESTIVAL", "Festival, şenlik (B1)", 3),
    ("CHAMPION", "Şampiyon (B1)", 3),
    ("HOSPITAL", "Hastane (B1)", 3),
    ("MEDICINE", "İlaç, tıp (B1)", 3),
    ("TRAINING", "Antrenman, eğitim (B1)", 3),
    ("FOOTBALL", "Futbol (B1)", 3),
    ("BIRTHDAY", "Doğum günü (B1)", 3),
    ("SANDWICH", "Sandviç (B1)", 3),
    ("UMBRELLA", "Şemsiye (B1)", 3),
    ("BACKPACK", "Sırt çantası (B1)", 3),
    ("SUITCASE", "Valiz, bavul (B1)", 3),
    ("MOUNTAIN", "Dağ (B1)", 3),
]

# ---------------------------------------------------------------------------
# 3) TÜRKİYE & MUTFAK (Genişletilmiş Havuz — 165+ kelime)
# ---------------------------------------------------------------------------
TURKIYE_WORDS: List[Tuple[str, str, int]] = [
    # Tier 1
    ("ÇAY",      "Rize yamaçlarının vazgeçilmez sıcak içeceği", 1),
    ("VAN",      "Kedisi ve büyük gölüyle ünlü doğu ilimiz", 1),
    ("EGE",      "Zeytin ağaçları ve koylarıyla ünlü bölgemiz", 1),
    ("BOLU",     "Aşçıları ve Abant Gölü ile meşhur ilimiz", 1),
    ("KARS",     "Kaşarı, kazı ve Ani Harabeleri ile bilinen şehir", 1),
    ("RİZE",     "Ayder Yaylası ve çay bahçelerinin başkenti", 1),
    ("URFA",     "Balıklıgöl ve Göbeklitepe'nin şehri", 1),
    ("ORDU",     "Fındığı ve Boztepe'siyle ünlü Karadeniz ili", 1),
    ("AĞRI",     "Türkiye'nin en yüksek dağına adını veren il", 1),
    ("EFES",     "İzmir Selçuk'taki görkemli antik kent", 1),
    ("PİDE",     "Taş fırından çıkan uzun, çıtır hamur işi", 1),
    ("MEZE",     "Sofraların başlangıcında sunulan soğuk lezzetler", 1),
    ("BOZA",     "Kış akşamlarının tarçınlı ve leblebili içeceği", 1),
    ("SİMİT",    "Susamlı, çıtır sabah kahvaltısı klasiği", 1),
    ("MANTI",    "Kayseri ile özdeşleşen yoğurtlu hamur yemeği", 1),
    ("KEBAP",    "Adana ve Urfa usulüyle ünlü ızgara et yemeği", 1),
    ("BÖREK",    "Yufka katmanlarıyla hazırlanan peynirli veya kıymalı lezzet", 1),
    ("DÖNER",    "Dikey şişte ağır ağır pişen dünyaca ünlü lezzet", 1),
    ("LOKUM",    "Türk kahvesinin yanında ikram edilen tatlı", 1),
    ("AYRAN",    "Yoğurt, su ve tuzla çırpılan ferahlatıcı içecek", 1),
    ("KAHVE",    "Kırk yıl hatırı olan köpüklü geleneksel içecek", 1),
    ("SALEP",    "Tarçın serpilerek içilen sıcak kış içeceği", 1),
    ("HELVA",    "İrmik veya unla kavrulan geleneksel tatlı", 1),
    ("AŞURE",    "Muharrem ayında bolluk ve bereketle pişen tatlı", 1),
    ("DOLMA",    "Biber veya patlıcanın pirinçli harçla doldurulmuş hali", 1),
    ("SARMA",    "Asma yaprağına incecik sarılan zeytinyağlı yemek", 1),
    ("CACIK",    "Yoğurt, salatalık ve naneyle yapılan serin lezzet", 1),
    ("SUCUK",    "Baharatlı, kahvaltıların gözdesi et ürünü", 1),
    ("İNCİR",    "Aydın ilimizin dünyaca meşhur meyvesi", 1),
    ("İZMİR",    "Saat Kulesi ve Kordon'uyla Ege'nin incisi", 1),
    ("BURSA",    "Uludağ, kestane şekeri ve İskender'in şehri", 1),
    ("ADANA",    "Taşköprü, şalgam ve acılı kebabın şehri", 1),
    ("KONYA",    "Mevlana Müzesi ve etli ekmeğiyle ünlü şehir", 1),
    ("SİVAS",    "Kangal köpeği ve Kongre binasıyla bilinen il", 1),
    ("HATAY",    "Künefesi ve zengin mutfağıyla medeniyetler şehri", 1),
    ("ANTEP",    "Baklavası ve yeşil fıstığıyla gastronomi başkenti", 1),
    ("MUĞLA",    "Bodrum, Fethiye ve Marmaris'in bağlı olduğu il", 1),
    ("AYDIN",    "Didim ve Kuşadası'na ev sahipliği yapan Ege ili", 1),
    ("SİNOP",    "Türkiye'nin en kuzey ucundaki sakin liman şehri", 1),
    ("TRUVA",    "Çanakkale'de tahta atıyla ünlü antik kent", 1),
    ("BOĞAZ",    "İstanbul'da Asya ile Avrupa'yı ayıran su yolu", 1),
    ("FIRAT",    "Anadolu'dan doğup Basra'ya dökülen büyük nehir", 1),
    ("DİCLE",    "Diyarbakır surlarının yanından akan kadim ırmak", 1),
    ("TOROS",    "Akdeniz kıyılarına paralel uzanan sıradağlar", 1),
    ("ÇİNİ",     "İznik ve Kütahya ile özdeşleşen sırlı seramik sanatı", 1),
    ("EBRU",     "Su üzerine boya serpilerek yapılan geleneksel sanat", 1),
    ("HALI",     "Hereke, Uşak ve Isparta'da dokunan geleneksel zemin örtüsü", 1),
    ("HORON",    "Karadeniz'in kemençe eşliğinde oynanan hızlı halk oyunu", 1),
    ("HALAY",    "Davul zurna eşliğinde el ele tutuşularak çekilen oyun", 1),
    ("KÖFTE",    "Tekirdağ, Akçaabat ve İnegöl çeşitleriyle ünlü et yemeği", 1),
    ("ÇORBA",    "Mercimek ve ezogelinle sofranın sıcak başlangıcı", 1),
    ("PİLAV",    "Kuru fasulyenin ayrılmaz pirinçli eşlikçisi", 1),
    ("TURŞU",    "Lahanadan salatalığa sofraların ekşi tamamlayıcısı", 1),
    ("REÇEL",    "Kahvaltıların meyveli tatlı eşlikçisi", 1),
    ("BAL",      "Anzer ve çiçek çeşitleriyle ünlü şifa kaynağı", 1),
    ("NAR",      "Bereket simgesi, ekşisi salatalarda kullanılan meyve", 1),
    ("ÜZÜM",     "Manisa bağlarında yetişen şifalı yaz meyvesi", 1),
    ("ELMA",     "Amasya ve Isparta bahçelerinin meşhur meyvesi", 1),
    ("KİRAZ",    "Afyon ve Kemalpaşa ile anılan kırmızı yaz meyvesi", 1),
    ("UŞAK",     "Tarhanası ve halısıyla bilinen Ege ilimiz", 1),
    ("TOKAT",    "Kebabı ve asma yaprağıyla ünlü Karadeniz ili", 1),
    ("NİĞDE",    "Aladağlar ve patatesiyle bilinen İç Anadolu ili", 1),
    ("ÇORUM",    "Leblebisi ve Hattuşa'sıyla bilinen ilimiz", 1),
    ("BARTIN",   "Amasra sahiliyle meşhur Batı Karadeniz ili", 1),

    # Tier 2
    ("ANKARA",   "Anıtkabir'in bulunduğu Türkiye Cumhuriyeti başkenti", 2),
    ("MARDİN",   "Taş evleri ve Mezopotamya manzarasıyla masalsı şehir", 2),
    ("EDİRNE",   "Selimiye Camii ve Kırkpınar güreşlerinin şehri", 2),
    ("AMASYA",   "Yeşilırmak kıyısındaki yalı boyu evleri ve elmasıyla ünlü il", 2),
    ("BODRUM",   "Beyaz evleri ve kalesiyle ünlü tatil beldesi", 2),
    ("GALATA",   "İstanbul'un siluetini süsleyen tarihi Ceneviz kulesi", 2),
    ("SÜMELA",   "Trabzon Maçka'da sarp kayalığa kurulu tarihi manastır", 2),
    ("NEMRUT",   "Adıyaman'da dev heykelleriyle gün doğumu izlenen dağ", 2),
    ("ULUDAĞ",   "Bursa'daki ünlü kış turizmi ve kayak merkezi", 2),
    ("KAÇKAR",   "Doğu Karadeniz'in bulutlara uzanan görkemli dağları", 2),
    ("MERİÇ",    "Yunanistan sınırımızı çizen Trakya nehri", 2),
    ("GEDİZ",    "Ege Bölgesi'nden denize dökülen verimli ova nehri", 2),
    ("KÜNEFE",   "Sıcak şerbetli, uzayan peynirli Hatay tatlısı", 2),
    ("SÜTLAÇ",   "Üzeri fırında kızartılan pirinçli süt tatlısı", 2),
    ("KEŞKEK",   "Buğday ve etin dövülerek pişirildiği düğün yemeği", 2),
    ("ZEYTİN",   "Gemlik ve Ayvalık sofralarının baş tacı meyve", 2),
    ("PEYNİR",   "Ezine, tulum ve kaşar gibi onlarca yöresel çeşidi olan gıda", 2),
    ("KAYISI",   "Malatya ilimizin güneşte kurutulan altın meyvesi", 2),
    ("FINDIK",   "Giresun ve Ordu'nun dünyaya ihraç ettiği kuruyemiş", 2),
    ("FISTIK",   "Baklavanın vazgeçilmez yeşil malzemesi", 2),
    ("ŞALGAM",   "Mor havuçtan yapılan acılı veya acısız Adana içeceği", 2),
    ("PİYAZ",    "Antalya usulünde tahinle tatlandırılan fasulye salatası", 2),
    ("KİLİM",    "Düz dokuma tekniğiyle üretilen motifli Anadolu örtüsü", 2),
    ("ZEYBEK",   "Ege bölgesinin ağır ve heybetli halk oyunu", 2),
    ("MARMARA",  "İç denizimiz ve Türkiye'nin en kalabalık bölgesi", 2),
    ("AKDENİZ",  "Turkuaz koyları ve sıcak iklimiyle güney denizimiz", 2),
    ("ERCİYES",  "Kayseri'de yükselen görkemli sönmüş yanardağ", 2),
    ("TRABZON",  "Uzungöl ve kemençesiyle ünlü Doğu Karadeniz şehri", 2),
    ("ANTALYA",  "Düden Şelalesi ve antik kentleriyle turizm başkenti", 2),
    ("BAKLAVA",  "İncecik kırk kat yufkadan yapılan şerbetli şölen tatlısı", 2),
    ("TARHANA",  "Yazdan kurutulup kışın pişirilen şifalı geleneksel çorba", 2),
    ("MENEMEN",  "Domates, biber ve yumurtanın tavadaki efsane buluşması", 2),
    ("GÖZLEME",  "Sac üzerinde pişirilen incecik açılmış Anadolu hamuru", 2),
    ("KADAYIF",  "Tel veya burma çeşitleriyle sevilen çıtır tatlı", 2),
    ("KESTANE",  "Bursa'da şekerlemesi, sokaklarda közlemesi yapılan lezzet", 2),
    ("TANTUNİ",  "Mersin'in ince doğranmış etle yapılan dürüm lezzeti", 2),
    ("TOPKAPI",  "Osmanlı padişahlarına yüzyıllar boyu ev sahipliği yapan saray", 2),
    ("BAĞLAMA",  "Aşık Veysel ve Neşet Ertaş'ın elinde dillenen telli çalgı", 2),
    ("KEMENÇE",  "Karadeniz türkülerinin ruhunu veren yaylı çalgı", 2),
    ("DERVİŞ",   "Konya'da sema dönen tasavvuf ehli", 2),
    ("KAYSERİ",  "Mantısı, pastırması ve Erciyes'iyle ünlü ilimiz", 2),
    ("MERSİN",   "Tantunisi ve limanıyla Akdeniz'in canlı şehri", 2),
    ("DENİZLİ",  "Horozu ve Pamukkale travertenleriyle ünlü ilimiz", 2),
    ("MANİSA",   "Mesir macunu ve Spil Dağı ile bilinen Ege ili", 2),
    ("SAMSUN",   "Kurtuluş Mücadelesi'nin başladığı Karadeniz şehri", 2),
    ("GİRESUN",  "Fındık ve kiraz diyarı yeşil Karadeniz ili", 2),
    ("ARTVİN",   "Karagöl'ü ve yeşil vadileriyle doğa harikası il", 2),
    ("ERZURUM",  "Cağ kebabı ve Palandöken'iyle ünlü Doğu şehri", 2),
    ("ELAZIĞ",   "Harput Kalesi ve orcik tatlısıyla bilinen il", 2),
    ("MALATYA",  "Dünyanın kayısı başkenti olan ilimiz", 2),
    ("ISPARTA",  "Gül bahçeleri ve lavanta tarlalarıyla ünlü il", 2),
    ("AFYON",    "Kaymağı, sucuğu ve termalleriyle meşhur ilimiz", 2),
    ("YALOVA",   "Termal kaplıcaları ve Marmara sahiliyle bilinen il", 2),
    ("KOCAELİ",  "İzmit pişmaniyesi ve sanayisiyle tanınan Marmara ili", 2),
    ("ÇEŞME",    "Ilıca plajı ve sakızlı dondurmasıyla ünlü İzmir ilçesi", 2),
    ("FETHİYE",  "Ölüdeniz ve yamaç paraşütüyle ünlü tatil cenneti", 2),
    ("KAŞ",      "Dalış noktaları ve begonvilleriyle ünlü Antalya ilçesi", 2),

    # Tier 3
    ("LAHMACUN", "İnce hamur üstü baharatlı kıymayla fırınlanan lezzet", 3),
    ("İSKENDER", "Tereyağı ve yoğurtla taçlanan Bursa döner klasiği", 3),
    ("PASTIRMA", "Çemenle kaplanarak kurutulan Kayseri lezzeti", 3),
    ("KAHRAMAN", "İstiklal madalyalı ...maraş şehrimizin unvanı", 3),
    ("PERİBACA", "Ürgüp ve Göreme'deki doğa harikası tüf oluşumu", 3),
    ("SAFRAN",   "Karabük'ün tarihi konaklı ilçesine adını veren değerli bitki", 3),
    ("BERGAMA",  "Parşömenin icat edildiği antik İzmir ilçesi", 3),
    ("ZEUGMA",   "Çingene Kızı mozaiğiyle ünlü Gaziantep antik kenti", 3),
    ("ASPENDOS", "Mükemmel akustiğiyle ünlü Antalya antik tiyatrosu", 3),
    ("HATTUŞA",  "Çorum Boğazkale'deki görkemli Hitit başkenti", 3),
    ("PATARA",   "Likya Birliği'nin meclis binasına ev sahipliği yapan plaj", 3),
    ("KEKOVA",   "Tekne turuyla gezilen batık şehir koyu", 3),
    ("CUNDA",    "Ayvalık'ta taş sokaklarıyla ünlü huzurlu ada", 3),
    ("ALAÇATI",  "Rüzgar sörfü ve taş değirmenleriyle ünlü Çeşme beldesi", 3),
    ("UZUNGÖL",  "Trabzon Çaykara'da çam ormanlarıyla çevrili göl", 3),
    ("AYDER",    "Rize Çamlıhemşin'in sisli ve yeşil yaylası", 3),
    ("ABANT",    "Bolu'nun nilüferli ve çam kokulu krater gölü", 3),
    ("SALDA",    "Burdur'daki beyaz kumsallı turkuaz göl", 3),
    ("TUZGÖLÜ",  "İç Anadolu'nun flamingolara ev sahipliği yapan beyaz gölü", 3),
    ("ARAS",     "Doğu Anadolu'dan doğup Hazar'a yönelen nehir", 3),
    ("SAKARYA",  "Adını büyük ırmaktan alan Marmara ilimiz", 3),
    ("ÇANAK",    "Avanos'ta Kızılırmak kiliyle çarkta döndürülen toprak kap", 3),
    ("OYA",      "Anadolu kadınlarının tığ ve iğneyle işlediği zarif kenar süsü", 3),
    ("KERVAN",   "İpek Yolu'nda hanlarda konaklayan tüccar kafilesi", 3),
    ("HAN",      "Tarihi ticaret yollarındaki kervan konaklama yapısı", 3),
    ("HAMAM",    "Kubbeleri ve kurnalarıyla geleneksel Türk banyosu", 3),
    ("KÜLLİYE",  "Cami etrafında medrese ve şifahaneyi toplayan yapı topluluğu", 3),
    ("SEMAZEN",  "Mevlevi töreninde beyaz tennuresiyle dönen kişi", 3),
    ("MİDYE",    "Ege ve İstanbul sahillerinin limonlu dolma atıştırmalığı", 3),
    ("KOKOREÇ",  "Baharatlı, közde pişen meşhur sokak lezzeti", 3),
    ("BOYOZ",    "İzmir sabahlarının haşlanmış yumurtayla yenen hamuru", 3),
    ("KUMRU",    "Çeşme ve İzmir'in susamlı sıcak sandviçi", 3),
    ("HAMSİ",    "Karadeniz'in buğulamasından pilavına her hali yapılan balığı", 3),
    ("MUHLAMA",  "Mısır unu ve uzayan kolot peyniriyle yapılan Karadeniz kahvaltılığı", 3),
    ("LEBLEBİ",  "Çorum ile özdeşleşen kavrulmuş nohut çerezi", 3),
    ("MESİR",    "Manisa'da her bahar saçılan 41 baharatlı şifa macunu", 3),
    ("CEZERYE",  "Mersin'in havuç ve cevizle yapılan enerji tatlısı", 3),
    ("GÜLLAÇ",   "Ramazan sofralarının sütlü ve güllü hafif tatlısı", 3),
    ("PEKMEZ",   "Üzüm veya dut şırasının kaynatılmasıyla elde edilen şifa", 3),
    ("TAHİN",    "Kavrulmuş susamın ezilmesiyle yapılan yoğun lezzet", 3),
    ("YAYLA",    "Yazın serinlemek için çıkılan yüksek ve yeşil dağ düzlüğü", 3),
    ("İSTANBUL", "İki kıtayı birleştiren yedi tepeli eşsiz metropol", 3),
    ("GÖREME",   "Kapadokya'nın açık hava müzesiyle ünlü beldesi", 3),
    ("ÜRGÜP",    "Taş konakları ve Üç Güzeller'iyle bilinen Nevşehir ilçesi", 3),
    ("AMASRA",   "Fatih Sultan Mehmet'in 'Çeşm-i Cihan' dediği sahil beldesi", 3),
    ("AYVALIK",  "Tostu ve zeytinyağıyla meşhur Balıkesir ilçesi", 3),
    ("MARMARİS", "Çam ormanlarıyla çevrili Muğla tatil beldesi", 3),
    ("ALANYA",   "Kızıl Kule ve Kleopatra Plajı ile ünlü ilçe", 3),
    ("SİDE",     "Apollon Tapınağı ile gün batımının izlendiği antik kent", 3),
    ("İZNİK",    "Gölü ve dünyaca ünlü çinileriyle tarihi Bursa ilçesi", 3),
    ("BÜRYAN",   "Siirt ve Bitlis'in kuyuda pişen meşhur et yemeği", 3),
    ("İÇLİKÖF",  "Silinecek", 99),
    ("HUMUS",    "Nohut ve tahinle yapılan Tarsus ve Hatay mezesi", 3),
    ("ŞEHRİYE",  "Pilav ve çorbalara lezzet katan ince hamur tanesi", 3),
    ("TULUMBA",  "Çıtır şerbetli sevilen sokak tatlısı", 3),
    ("REVANI",   "İrmikle hazırlanan limon aromalı şerbetli tatlı", 3),
    ("REVANİ",   "İrmikle hazırlanan limon aromalı şerbetli tatlı", 3),
]
TURKIYE_WORDS = [(w, c, t) for (w, c, t) in TURKIYE_WORDS if t != 99 and w != "REVANI"]

# ---------------------------------------------------------------------------
# 4) GENEL KÜLTÜR & BİLİM (Genişletilmiş Havuz — 175+ kelime)
# ---------------------------------------------------------------------------
GENEL_KULTUR_WORDS: List[Tuple[str, str, int]] = [
    # Tier 1
    ("GÜNEŞ",    "Sistemimizin merkezindeki ısı ve ışık kaynağımız", 1),
    ("DÜNYA",    "Yaşam barındırdığı bilinen mavi gezegen", 1),
    ("MARS",     "Kızıl Gezegen olarak bilinen komşu gezegen", 1),
    ("VENÜS",    "Güneş sisteminin en sıcak gezegeni, Çoban Yıldızı", 1),
    ("ATOM",     "Maddenin kimyasal özelliklerini taşıyan temel yapı taşı", 1),
    ("DNA",      "Canlıların genetik şifresini taşıyan çift sarmallı molekül", 1),
    ("GEN",      "Kalıtsal özellikleri nesilden nesile aktaran DNA parçası", 1),
    ("AŞI",      "Bağışıklık sistemini hastalıklara karşı eğiten biyolojik ürün", 1),
    ("PİL",      "Kimyasal enerjiyi elektriğe çeviren taşınabilir güç kaynağı", 1),
    ("KOD",      "Bilgisayarlara ne yapacağını söyleyen komut dizisi", 1),
    ("VERİ",     "İşlenerek bilgiye dönüştürülen ham kayıt veya sayı", 1),
    ("ÇİP",      "Elektronik cihazların beyni olan mikro devre", 1),
    ("GOL",      "Futbolda topun kale çizgisini geçmesiyle kazanılan sayı", 1),
    ("KUPA",     "Turnuva şampiyonlarına verilen simgesel ödül", 1),
    ("BOKS",     "Ringde eldivenle yapılan dövüş sporu", 1),
    ("TENİS",    "Raket ve file ile kortta oynanan spor", 1),
    ("NOTA",     "Müzik seslerini kağıda aktaran işaretler", 1),
    ("GİTAR",    "Altı telli, akor ve solo çalınan popüler enstrüman", 1),
    ("KEMAN",    "Dört telli, omuzda yayla çalınan klasik çalgı", 1),
    ("FLÜT",     "Üfleyerek çalınan zarif müzik aleti", 1),
    ("DAVUL",    "Tokmakla vurularak ritim tutulan vurmalı çalgı", 1),
    ("ŞİİR",     "Duyguları dizeler ve imgelerle anlatan edebiyat türü", 1),
    ("ROMAN",    "Geniş kurgulu, uzun edebi anlatı türü", 1),
    ("MASAL",    "Olağanüstü olaylarla dolu, 'Bir varmış bir yokmuş' anlatısı", 1),
    ("ÖYKÜ",     "Kısa ve yoğun kurgulu edebi metin, hikaye", 1),
    ("RESİM",    "Boya ve fırçayla yüzeyde oluşturulan görsel sanat", 1),
    ("MÜZE",     "Tarihi ve sanatsal eserlerin sergilendiği kurum", 1),
    ("SAHNE",    "Tiyatro ve konserlerde performansın sergilendiği alan", 1),
    ("OPERA",    "Müzik ve dramayı birleştiren görkemli sahne sanatı", 1),
    ("BALE",     "Klasik müzik eşliğinde zarif dans sanatı", 1),
    ("KITA",     "Okyanuslarla çevrili dev kara parçası", 1),
    ("ADA",      "Dört tarafı sularla çevrili kara parçası", 1),
    ("ÇÖL",      "Yağışın çok az olduğu kurak iklim bölgesi", 1),
    ("ORMAN",    "Yeryüzünün akciğeri sayılan yoğun ağaçlık alan", 1),
    ("NEHİR",    "Deniz veya göle dökülen büyük akarsu", 1),
    ("ALTIN",    "Kimyasal simgesi Au olan değerli sarı metal", 1),
    ("DEMİR",    "Kandaki hemoglobinde de bulunan güçlü metal", 1),
    ("BAKIR",    "Elektrik kablolarında kullanılan kızıl iletken metal", 1),
    ("GÜMÜŞ",    "Kimyasal simgesi Ag olan parlak beyaz metal", 1),
    ("ELMAS",    "Doğada bilinen en sert karbon minerali", 1),
    ("KÜRE",     "Gezegenlerin ve topların geometrik şekli", 1),
    ("ÜÇGEN",    "İç açıları toplamı 180 derece olan çokgen", 1),
    ("AÇI",      "İki ışının kesişmesiyle oluşan geometrik açıklık", 1),
    ("BİLİM",    "Deney ve gözleme dayalı sistemli bilgi bütünü", 1),
    ("DENEY",    "Bir hipotezi test etmek için kontrollü araştırma", 1),
    ("TARİH",    "İnsanlığın geçmişini belgelerle inceleyen bilim dalı", 1),
    ("ROMA",     "Kolezyum ve hukukuyla antik çağın büyük imparatorluğu", 1),
    ("MISIR",    "Nil Nehri ve piramitleriyle ünlü antik medeniyet", 1),
    ("ROBOT",    "Programlanabilen otonom mekanik yardımcı", 1),
    ("UYDU",     "Bir gezegenin yörüngesinde dönen doğal veya yapay cisim", 1),
    ("ROKET",    "Uzaya araç taşımak için itki üreten fırlatma sistemi", 1),
    ("UZAY",     "Gök cisimlerini barındıran sonsuz evren boşluğu", 1),
    ("IŞIK",     "Saniyede yaklaşık 300 bin kilometre yol alan enerji", 1),
    ("KALP",     "Vücuda sürekli kan pompalayan hayati organ", 1),
    ("BEYİN",    "Düşünme, hafıza ve hareketin yönetim merkezi", 1),
    ("KEMİK",    "İskelet sistemimizi oluşturan sert doku", 1),
    ("NABIZ",    "Kalbin dakikadaki atım ritmi", 1),
    ("KİTAP",    "Bilgi ve hikayeleri çağlar ötesine taşıyan basılı eser", 1),
    ("KARE",     "Dört kenarı eşit ve açıları 90 derece olan şekil", 1),
    ("SAYI",     "Matematiğin temel sayma ve ölçme birimi", 1),
    ("KALE",     "Futbolda kalecinin koruduğu ağlı çerçeve", 1),
    ("PAS",      "Takım sporlarında topu arkadaşına aktarma hamlesi", 1),
    ("ŞUT",      "Futbolda kaleye doğru yapılan sert vuruş", 1),
    ("MAÇ",      "İki takım veya sporcu arasındaki resmi karşılaşma", 1),

    # Tier 2
    ("SATÜRN",   "Görkemli buz ve kaya halkalarıyla ünlü gezegen", 2),
    ("JÜPİTER",  "Güneş sisteminin en büyük gaz devi gezegeni", 2),
    ("NEPTÜN",   "Güneş'e en uzak, fırtınalı mavi gezegen", 2),
    ("URANÜS",   "Eksen eğikliği nedeniyle yan yatmış dönen gezegen", 2),
    ("MERKÜR",   "Güneş'e en yakın ve en hızlı dönen gezegen", 2),
    ("YILDIZ",   "Kendi ışığını nükleer füzyonla üreten gök cismi", 2),
    ("METEOR",   "Atmosfere girip yanarak iz bırakan uzay taşı", 2),
    ("GALAKSİ",  "Milyarlarca yıldızdan oluşan dev kozmik sistem", 2),
    ("LAZER",    "Yoğunlaştırılmış tek dalga boylu ışık demeti", 2),
    ("RADAR",    "Radyo dalgalarıyla nesnelerin yerini tespit eden sistem", 2),
    ("ENERJİ",   "İş yapabilme yeteneği; kinetik veya potansiyel olabilir", 2),
    ("KARBON",   "Organik yaşamın ve elmasın temel elementi", 2),
    ("OKSİJEN",  "Solunum için vazgeçilmez, atmosferin %21'ini oluşturan gaz", 2),
    ("PROTON",   "Atom çekirdeğindeki pozitif yüklü parçacık", 2),
    ("HÜCRE",    "Tüm canlı organizmaların en küçük yapısal birimi", 2),
    ("VİRÜS",    "Sadece canlı konak içinde çoğalabilen mikroskobik etken", 2),
    ("MİKROP",   "Gözle görülemeyen tek hücreli canlıların genel adı", 2),
    ("FOSİL",    "Milyonlarca yıl öncesinden taşlaşarak kalan canlı izi", 2),
    ("NOBEL",    "Bilim, edebiyat ve barış alanlarında verilen en prestijli ödül", 2),
    ("YAPAY",    "Doğal olmayan; '... zeka' tamlamasının ilk sözcüğü", 2),
    ("ZEKA",     "Öğrenme, akıl yürütme ve problem çözme yetisi", 2),
    ("BULUT",    "İnternet üzerinden uzak sunucularda veri depolama modeli", 2),
    ("SENSÖR",   "Sıcaklık, ışık veya hareketi algılayan elektronik parça", 2),
    ("PİKSEL",   "Dijital bir görüntüyü oluşturan en küçük renk noktası", 2),
    ("EKRAN",    "Telefon ve bilgisayarlarda görüntüyü sunan panel", 2),
    ("MODEM",    "İnternet bağlantısını dijital sinyale çeviren ağ cihazı", 2),
    ("PİYANO",   "88 siyah-beyaz tuşuyla klasik müziğin temel çalgısı", 2),
    ("RİTİM",    "Müzikte vuruşların düzenli ve ölçülü akışı", 2),
    ("MELODİ",   "Bir şarkının akılda kalan ezgisi", 2),
    ("DESTAN",   "Milletlerin kahramanlıklarını anlatan uzun manzum eser", 2),
    ("TİYATRO",  "Oyuncuların seyirci önünde canlı sahnelediği sanat", 2),
    ("HEYKEL",   "Taş, bronz veya kil yontularak yapılan üç boyutlu sanat", 2),
    ("MİMAR",    "Bina ve mekanları estetik ve işlevsel tasarlayan uzman", 2),
    ("ANTİK",    "İlk çağlardan kalma tarihi eser veya dönem", 2),
    ("SÜMER",    "Çivi yazısını icat eden Mezopotamya uygarlığı", 2),
    ("HİTİT",    "Anadolu'da Kadeş Antlaşması'nı imzalayan kadim uygarlık", 2),
    ("PİRAMİT",  "Mısır firavunları için inşa edilen dev anıt mezar", 2),
    ("PUSULA",   "Manyetik iğnesiyle kuzeyi gösteren yön bulma aracı", 2),
    ("HARİTA",   "Yeryüzünün ölçekli ve düzlem üzerine çizilmiş modeli", 2),
    ("OKYANUS",  "Kıtaları birbirinden ayıran devasa tuzlu su kütlesi", 2),
    ("VOLKAN",   "Magmanın yeryüzüne püskürdüğü yanardağ", 2),
    ("DEPREM",   "Yer kabuğundaki fay kırılmasıyla oluşan sarsıntı", 2),
    ("BUZUL",    "Kutup ve yüksek zirvelerdeki dev hareketli buz kütlesi", 2),
    ("ŞELALE",   "Akarsuyun yüksek bir kayalıktan döküldüğü yer", 2),
    ("KÖRFEZ",   "Denizin karanın içine derinlemesine sokulduğu kısım", 2),
    ("FUTBOL",   "Dünyada en çok izlenen on birer kişilik takım sporu", 2),
    ("VOLEYBO",  "Silinecek", 99),
    ("BASKET",   "Potaya top atarak sayı kazanılan salon sporu", 2),
    ("SATRANÇ",  "64 karede şah mat etmek için oynanan zeka oyunu", 2),
    ("GÜREŞ",    "Minderde veya çayırda yapılan ata sporumuz", 2),
    ("YÜZME",    "Kulaç atarak suda hız yapılan olimpik spor", 2),
    ("MADALYA",  "Olimpiyatlarda ilk üçe giren sporculara takılan ödül", 2),
    ("HAKEM",    "Karşılaşmalarda kuralların uygulanmasını sağlayan görevli", 2),
    ("STADYUM",  "Binlerce seyircinin maç izlediği büyük spor arenası", 2),
    ("FELSEFE",  "Varlık, bilgi ve değer üzerine derin düşünme disiplini", 2),
    ("MANTIK",   "Doğru akıl yürütmenin kurallarını inceleyen bilim", 2),
    ("ETİK",     "Ahlaki değerler ve doğru davranış ilkeleri felsefesi", 2),
    ("TEORİ",    "Gözlem ve deneylerle güçlü biçimde desteklenen bilimsel kuram", 2),
    ("FORMÜL",   "Matematik veya kimyada ilişkileri gösteren sembolik ifade", 2),
    ("DAİRE",    "Çemberin içi dolu geometrik alanı", 2),
    ("SİMETRİ",  "Bir eksene göre iki tarafın birebir ayna uyumu", 2),
    ("TAKVİM",   "Gün, hafta ve ayları düzenli gösteren zaman çizelgesi", 2),
    ("MÜHENDİS", "Bilimi kullanarak pratik sistem ve yapılar tasarlayan uzman", 2),
    ("RESSAM",   "Tuval üzerine renklerle eser üreten sanatçı", 2),
    ("YAZAR",    "Roman, öykü veya makale kaleme alan kişi", 2),
    ("ŞAİR",     "Duyguları dizelere döken edebiyatçı", 2),
    ("BESTECİ",  "Yeni müzik eserleri oluşturan sanatçı", 2),

    # Tier 3
    ("HİDROJEN", "Evrende en bol bulunan, 1 numaralı hafif element", 3),
    ("NÖTRON",   "Atom çekirdeğindeki elektriksel yükü sıfır olan parçacık", 3),
    ("ELEKTRON", "Atom çekirdeği etrafında dönen eksi yüklü parçacık", 3),
    ("FOTON",    "Işığı oluşturan kütlesiz enerji paketi", 3),
    ("KUANTUM",  "Atom altı dünyanın fizik yasalarını inceleyen bilim dalı", 3),
    ("GRAVİTE",  "Kütlelerin birbirini çekme kuvveti, yerçekimi", 3),
    ("SİBER",    "Dijital ağlar ve bilgi güvenliği alanını tanımlayan kavram", 3),
    ("KRİPTO",   "Şifreleme bilimiyle güvence altına alınan veri veya varlık", 3),
    ("SUNUCU",   "Ağ üzerinden istemcilere hizmet ve veri sağlayan güçlü bilgisayar", 3),
    ("YAZILIM",  "Bilgisayar donanımına hayat veren programların bütünü", 3),
    ("DONANIM",  "Bilgisayarın elle tutulabilir fiziksel bileşenleri", 3),
    ("TARAYICI", "Web sayfalarını açıp görüntülemeye yarayan uygulama", 3),
    ("ASTRONOM", "Gök cisimlerini ve evreni inceleyen bilim insanı", 3),
    ("TELESKOP", "Uzak yıldız ve galaksileri gözlemleyen optik alet", 3),
    ("KÜRESEL",  "Tüm dünyayı kapsayan, gezegen ölçeğindeki", 3),
    ("EKOLOJİ",  "Canlıların çevreleriyle ilişkisini inceleyen bilim", 3),
    ("BİYOLOJİ", "Canlı yaşamını tüm boyutlarıyla inceleyen bilim dalı", 3),
    ("JEOLOJİ",  "Yerkürenin katmanlarını ve kayaçlarını inceleyen bilim", 3),
    ("ANTİKÇAĞ", "Yazının icadından Batı Roma'nın yıkılışına dek süren dönem", 3),
    ("RÖNESANS", "Avrupa'da sanat ve bilimin yeniden doğuş çağı", 3),
    ("BAROK",    "17. yüzyılın süslü ve görkemli sanat akımı", 3),
    ("KÜBİZM",   "Picasso ile özdeşleşen geometrik resim akımı", 3),
    ("MOZAİK",   "Küçük renkli taşlarla oluşturulan kadim süsleme sanatı", 3),
    ("FRESK",    "Islak sıva üzerine yapılan kalıcı duvar resmi", 3),
    ("SENFONİ",  "Büyük orkestra için yazılmış çok bölümlü müzik eseri", 3),
    ("KORO",     "Çok sesli şarkı söyleyen topluluk", 3),
    ("SOLİST",   "Orkestra veya koro önünde tek başına eser icra eden sanatçı", 3),
    ("TRAJEDİ",  "Kader ve derin çatışma işleyen klasik tiyatro türü", 3),
    ("KOMEDİ",   "İnsanı güldürürken düşündüren sahne ve sinema türü", 3),
    ("HİCİV",    "Toplumsal aksaklıkları iğneleyici dille eleştiren sanat", 3),
    ("METAFOR",  "Bir kavramı başka bir şeye benzeterek anlatma sanatı, eğretileme", 3),
    ("PARADOKS", "İlk bakışta çelişkili görünüp derin mantık barındıran önerme", 3),
    ("ÜTOPYA",   "Kusursuz işleyen, hayali ideal toplum tasarımı", 3),
    ("DİSTOPYA", "Baskıcı ve karanlık gelecek kurgusu", 3),
    ("OLİMPİK",  "Dört yılda bir düzenlenen dünya oyunlarıyla ilgili", 3),
    ("MARATON",  "42 kilometre 195 metrelik dayanıklılık koşusu", 3),
    ("ESKRİM",   "Kılıç ve maskeyle yapılan zarif salon sporu", 3),
    ("OKÇULUK",  "Yay ve okla hedefi on ikiden vurma sporu", 3),
    ("ATLETİZM", "Koşu, atlama ve atma branşlarını kapsayan temel spor", 3),
    ("REKOR",    "Bir spor dalında şimdiye kadar ulaşılmış en iyi derece", 3),
    ("PRİZMA",   "Beyaz ışığı gökkuşağı renklerine ayıran cam cisim", 3),
    ("SPEKTRUM", "Işığın dalga boylarına göre ayrılmış renk tayfı", 3),
    ("KATALİZ",  "Kimyasal tepkimeyi hızlandıran süreç", 3),
    ("OSMOZ",    "Suyun yarı geçirgen zardan geçiş olayı", 3),
    ("KRİSTAL",  "Atomları düzenli geometrik örgüde dizilmiş katı yapı", 3),
    ("ATMOSFER", "Dünya'yı saran koruyucu gaz tabakası", 3),
    ("EKVATOR",  "Dünya'yı kuzey ve güney yarım küreye bölen hayali çizgi", 3),
    ("MERİDYEN", "Kutupları birleştiren hayali boylam yayı", 3),
    ("VOLTAJ",   "Elektrik devresindeki potansiyel farkı", 3),
    ("FREKANS",  "Bir dalganın saniyedeki titreşim sayısı", 3),
    ("DİNAMO",   "Mekanik hareketi elektrik enerjisine dönüştüren araç", 3),
    ("MIKNATIS", "Demir ve nikeli çeken manyetik cisim", 3),
    ("PERİSKOP", "Denizaltılarda su yüzeyini gözlemleyen aynalı optik tüp", 3),
    ("BAROMET",  "Silinecek", 99),
    ("İKLİM",    "Bir bölgede uzun yıllar gözlenen ortalama hava koşulları", 3),
    ("MEVSİM",   "Dünya'nın eksen eğikliğiyle oluşan dört dönem", 3),
    ("TUTULMA",  "Güneş, Dünya ve Ay'ın aynı hizaya gelmesi olayı", 3),
    ("YÖRÜNGE",  "Bir gök cisminin başka bir cisim etrafındaki yolu", 3),
    ("EVRİM",    "Canlı türlerinin uzun zaman içinde değişim süreci", 3),
    ("ENZİM",    "Canlı hücrelerde biyokimyasal tepkimeleri hızlandıran protein", 3),
    ("VİTAMİN",  "Vücudun sağlıklı çalışması için gerekli organik bileşik", 3),
    ("MİNERAL",  "Doğada oluşan ve metabolizma için gerekli inorganik madde", 3),
    ("KLOROFİL", "Bitkilere yeşil rengi veren fotosentez pigmenti", 3),
    ("MİTOLOJİ", "Antik toplumların tanrı ve kahraman efsaneleri bütünü", 3),
    ("EPİLOG",   "Bir roman veya oyunun sonundaki kapanış bölümü", 3),
    ("PROLOG",   "Bir eserin başındaki giriş bölümü", 3),
]
GENEL_KULTUR_WORDS = [(w, c, t) for (w, c, t) in GENEL_KULTUR_WORDS if t != 99]


# ---------------------------------------------------------------------------
# KARE BULMACA YERLEŞTİRME MOTORU
# ---------------------------------------------------------------------------

def can_place(
    grid: List[List[str]],
    dir_grid: List[List[int]],
    word: str,
    r: int,
    c: int,
    direction: str,
    require_intersection: bool,
) -> Optional[int]:
    rows = len(grid)
    cols = len(grid[0])
    dr, dc = (0, 1) if direction == "across" else (1, 0)
    dir_bit = 1 if direction == "across" else 2
    wlen = len(word)

    end_r = r + (wlen - 1) * dr
    end_c = c + (wlen - 1) * dc
    if r < 0 or c < 0 or end_r >= rows or end_c >= cols:
        return None

    before_r, before_c = r - dr, c - dc
    if 0 <= before_r < rows and 0 <= before_c < cols and grid[before_r][before_c] != "":
        return None
    after_r, after_c = r + wlen * dr, c + wlen * dc
    if 0 <= after_r < rows and 0 <= after_c < cols and grid[after_r][after_c] != "":
        return None

    intersections = 0
    new_cells = 0

    for i, ch in enumerate(word):
        rr = r + i * dr
        cc = c + i * dc
        if dir_grid[rr][cc] & dir_bit:
            return None
        cur = grid[rr][cc]
        if cur != "":
            if cur != ch:
                return None
            intersections += 1
        else:
            new_cells += 1
            p1_r, p1_c = rr + dc, cc + dr
            p2_r, p2_c = rr - dc, cc - dr
            if 0 <= p1_r < rows and 0 <= p1_c < cols and grid[p1_r][p1_c] != "":
                return None
            if 0 <= p2_r < rows and 0 <= p2_c < cols and grid[p2_r][p2_c] != "":
                return None

    if new_cells == 0:
        return None
    if require_intersection and intersections == 0:
        return None
    return intersections


def place_word(
    grid: List[List[str]],
    dir_grid: Optional[List[List[int]]],
    word: str,
    r: int,
    c: int,
    direction: str,
) -> None:
    dr, dc = (0, 1) if direction == "across" else (1, 0)
    dir_bit = 1 if direction == "across" else 2
    for i, ch in enumerate(word):
        rr = r + i * dr
        cc = c + i * dc
        grid[rr][cc] = ch
        if dir_grid is not None:
            dir_grid[rr][cc] |= dir_bit


def center_placements(
    rows: int,
    cols: int,
    placements: List[Tuple[str, str, int, int, str]],
) -> List[Tuple[str, str, int, int, str]]:
    min_r, min_c = rows, cols
    max_r, max_c = 0, 0
    for word, _, r, c, d in placements:
        dr, dc = (0, 1) if d == "across" else (1, 0)
        for i in range(len(word)):
            rr, cc = r + i * dr, c + i * dc
            min_r = min(min_r, rr)
            min_c = min(min_c, cc)
            max_r = max(max_r, rr)
            max_c = max(max_c, cc)

    used_h = max_r - min_r + 1
    used_w = max_c - min_c + 1
    target_r = (rows - used_h) // 2
    target_c = (cols - used_w) // 2
    shift_r = target_r - min_r
    shift_c = target_c - min_c

    return [
        (word, clue, r + shift_r, c + shift_c, d)
        for (word, clue, r, c, d) in placements
    ]


def build_single_puzzle(
    rows: int,
    cols: int,
    min_words: int,
    max_words: int,
    primary_pool: List[Tuple[str, str]],
    fallback_pool: List[Tuple[str, str]],
    rng: random.Random,
    trials: int = 260,
) -> Tuple[List[List[str]], List[Tuple[str, str, int, int, str]]]:
    max_dim = max(rows, cols)
    primary = [(w, c) for (w, c) in primary_pool if 3 <= len(w) <= max_dim]
    fallback = [(w, c) for (w, c) in fallback_pool if 3 <= len(w) <= max_dim]

    best_score = -10**9
    best_result = None

    for attempt in range(trials):
        if attempt < trials * 0.65 and len(primary) >= min_words * 2:
            candidates = list(primary)
        else:
            seen = {w for w, _ in primary}
            candidates = list(primary) + [(w, c) for (w, c) in fallback if w not in seen]

        rng.shuffle(candidates)
        seed_choices = [item for item in candidates if len(item[0]) >= min(4, max_dim)]
        if not seed_choices:
            seed_choices = candidates
        seed_word, seed_clue = rng.choice(seed_choices[: max(1, min(18, len(seed_choices)))])

        grid = [["" for _ in range(cols)] for _ in range(rows)]
        dir_grid = [[0 for _ in range(cols)] for _ in range(rows)]
        placements: List[Tuple[str, str, int, int, str]] = []
        used_words: Set[str] = set()

        seed_dir = rng.choice(["across", "down"])
        if seed_dir == "across" and len(seed_word) > cols:
            seed_dir = "down"
        elif seed_dir == "down" and len(seed_word) > rows:
            seed_dir = "across"

        if seed_dir == "across":
            sr = rng.randint(0, rows - 1)
            sc = rng.randint(0, max(0, cols - len(seed_word)))
        else:
            sr = rng.randint(0, max(0, rows - len(seed_word)))
            sc = rng.randint(0, cols - 1)

        if can_place(grid, dir_grid, seed_word, sr, sc, seed_dir, require_intersection=False) is None:
            continue

        place_word(grid, dir_grid, seed_word, sr, sc, seed_dir)
        placements.append((seed_word, seed_clue, sr, sc, seed_dir))
        used_words.add(seed_word)

        primary_set = {w for w, _ in primary}
        for _ in range(max_words * 2):
            if len(placements) >= max_words:
                break

            letter_positions: Dict[str, List[Tuple[int, int]]] = {}
            for r in range(rows):
                for c in range(cols):
                    ch = grid[r][c]
                    if ch:
                        letter_positions.setdefault(ch, []).append((r, c))

            best_move = None
            best_move_score = -10**9

            across_cnt = sum(1 for p in placements if p[4] == "across")
            down_cnt = len(placements) - across_cnt

            sample_cands = [item for item in candidates if item[0] not in used_words]
            if len(sample_cands) > 90:
                p_cands = [x for x in sample_cands if x[0] in primary_set]
                f_cands = [x for x in sample_cands if x[0] not in primary_set]
                sample_cands = p_cands[:70] + f_cands[:20]

            for word, clue in sample_cands:
                is_primary = word in primary_set
                for idx, ch in enumerate(word):
                    positions = letter_positions.get(ch)
                    if not positions:
                        continue
                    for r0, c0 in positions:
                        for d in ("across", "down"):
                            sr2 = r0 if d == "across" else r0 - idx
                            sc2 = c0 - idx if d == "across" else c0
                            inter = can_place(grid, dir_grid, word, sr2, sc2, d, require_intersection=True)
                            if inter is None:
                                continue
                            dir_bonus = 6 if (d == "across" and across_cnt < down_cnt) or (d == "down" and down_cnt < across_cnt) else 0
                            prim_bonus = 10 if is_primary else 0
                            score = inter * 18 + len(word) * 1.5 + dir_bonus + prim_bonus + rng.random() * 4.0
                            if score > best_move_score:
                                best_move_score = score
                                best_move = (word, clue, sr2, sc2, d)

            if best_move is None:
                break
            w, cl, r_p, c_p, d_p = best_move
            place_word(grid, dir_grid, w, r_p, c_p, d_p)
            placements.append(best_move)
            used_words.add(w)

        across_cnt = sum(1 for p in placements if p[4] == "across")
        down_cnt = len(placements) - across_cnt
        if len(placements) < min_words or across_cnt < 2 or down_cnt < 2:
            continue

        cell_use: Dict[Tuple[int, int], int] = {}
        for w, _, r_p, c_p, d_p in placements:
            dr, dc = (0, 1) if d_p == "across" else (1, 0)
            for i in range(len(w)):
                key = (r_p + i * dr, c_p + i * dc)
                cell_use[key] = cell_use.get(key, 0) + 1

        intersections = sum(1 for cnt in cell_use.values() if cnt >= 2)
        filled_cells = len(cell_use)
        primary_used = sum(1 for p in placements if p[0] in primary_set)
        balance_penalty = abs(across_cnt - down_cnt) * 5

        total_score = (
            intersections * 22
            + len(placements) * 14
            + filled_cells * 2
            + primary_used * 8
            - balance_penalty
        )

        if total_score > best_score:
            best_score = total_score
            centered = center_placements(rows, cols, placements)
            final_grid = [["" for _ in range(cols)] for _ in range(rows)]
            for w, _, r_p, c_p, d_p in centered:
                place_word(final_grid, None, w, r_p, c_p, d_p)
            best_result = (final_grid, centered)

    if best_result is None:
        raise RuntimeError(f"{rows}x{cols} için geçerli bulmaca üretilemedi!")
    return best_result


def assign_numbers_and_format(
    puzzle_id: str,
    level: int,
    title: str,
    difficulty: str,
    rows: int,
    cols: int,
    placements: List[Tuple[str, str, int, int, str]],
    initial_reveals: int,
    rng: random.Random,
) -> dict:
    starts: Dict[Tuple[int, int], List[Tuple[str, str, int, int, str]]] = {}
    for p in placements:
        starts.setdefault((p[2], p[3]), []).append(p)

    num_map: Dict[Tuple[int, int], int] = {}
    next_num = 1
    for r in range(rows):
        for c in range(cols):
            if (r, c) in starts:
                num_map[(r, c)] = next_num
                next_num += 1

    entries = []
    for word, clue, r, c, d in placements:
        entries.append({
            "number": num_map[(r, c)],
            "direction": d,
            "row": r,
            "col": c,
            "answer": word,
            "clue": clue,
        })

    entries.sort(key=lambda e: (0 if e["direction"] == "across" else 1, e["number"]))

    revealed: List[List[int]] = []
    if initial_reveals > 0:
        cell_counts: Dict[Tuple[int, int], int] = {}
        for e in entries:
            dr, dc = (0, 1) if e["direction"] == "across" else (1, 0)
            for i in range(len(e["answer"])):
                key = (e["row"] + i * dr, e["col"] + i * dc)
                cell_counts[key] = cell_counts.get(key, 0) + 1
        inter_cells = [k for k, v in cell_counts.items() if v >= 2]
        rng.shuffle(inter_cells)
        chosen: List[Tuple[int, int]] = []
        for rc in inter_cells:
            if len(chosen) >= initial_reveals:
                break
            if all(abs(rc[0] - x[0]) + abs(rc[1] - x[1]) > 1 for x in chosen):
                chosen.append(rc)
        revealed = [[r, c] for r, c in chosen]

    puzzle_obj = {
        "id": puzzle_id,
        "level": level,
        "title": title,
        "difficulty": difficulty,
        "rows": rows,
        "cols": cols,
        "revealed": revealed,
        "entries": entries,
    }
    validate_puzzle(puzzle_obj)
    return puzzle_obj


def validate_puzzle(puzzle: dict) -> None:
    rows = puzzle["rows"]
    cols = puzzle["cols"]
    grid = [["" for _ in range(cols)] for _ in range(rows)]

    across_map: Dict[Tuple[int, int], str] = {}
    down_map: Dict[Tuple[int, int], str] = {}

    for e in puzzle["entries"]:
        r, c, ans, d = e["row"], e["col"], e["answer"], e["direction"]
        dr, dc = (0, 1) if d == "across" else (1, 0)
        if d == "across":
            assert (r, c) not in across_map, f"Çift across başlangıcı: {puzzle['id']}"
            across_map[(r, c)] = ans
        else:
            assert (r, c) not in down_map, f"Çift down başlangıcı: {puzzle['id']}"
            down_map[(r, c)] = ans

        for i, ch in enumerate(ans):
            rr, cc = r + i * dr, c + i * dc
            assert 0 <= rr < rows and 0 <= cc < cols, f"Sınır dışı: {puzzle['id']}"
            if grid[rr][cc] != "":
                assert grid[rr][cc] == ch, f"Harf çakışması ({rr},{cc}): {puzzle['id']}"
            grid[rr][cc] = ch

    found_across: Dict[Tuple[int, int], str] = {}
    for r in range(rows):
        c = 0
        while c < cols:
            if grid[r][c] != "":
                start_c = c
                chars = []
                while c < cols and grid[r][c] != "":
                    chars.append(grid[r][c])
                    c += 1
                if len(chars) >= 2:
                    found_across[(r, start_c)] = "".join(chars)
            else:
                c += 1

    found_down: Dict[Tuple[int, int], str] = {}
    for c in range(cols):
        r = 0
        while r < rows:
            if grid[r][c] != "":
                start_r = r
                chars = []
                while r < rows and grid[r][c] != "":
                    chars.append(grid[r][c])
                    r += 1
                if len(chars) >= 2:
                    found_down[(start_r, c)] = "".join(chars)
            else:
                r += 1

    assert found_across == across_map, (
        f"Yatay tutarsızlık {puzzle['id']}: bulunan={found_across} beklenen={across_map}"
    )
    assert found_down == down_map, (
        f"Dikey tutarsızlık {puzzle['id']}: bulunan={found_down} beklenen={down_map}"
    )

    active = {(r, c) for r in range(rows) for c in range(cols) if grid[r][c] != ""}
    assert active, f"Boş bulmaca: {puzzle['id']}"
    start = next(iter(active))
    visited = {start}
    q = deque([start])
    while q:
        cr, cc = q.popleft()
        for nr, nc in ((cr + 1, cc), (cr - 1, cc), (cr, cc + 1), (cr, cc - 1)):
            if (nr, nc) in active and (nr, nc) not in visited:
                visited.add((nr, nc))
                q.append((nr, nc))
    assert visited == active, f"Kopuk bileşen var: {puzzle['id']}"

    for rr, cc in puzzle["revealed"]:
        assert (rr, cc) in active, f"Geçersiz açık hücre: {puzzle['id']}"


def dedupe_pool(raw: List[Tuple[str, str, int]], lang: str) -> List[Tuple[str, str, int]]:
    seen: Set[str] = set()
    cleaned: List[Tuple[str, str, int]] = []
    for word, clue, tier in raw:
        nw = normalize_word(word, lang)
        if nw in seen:
            continue
        seen.add(nw)
        cleaned.append((nw, clue.strip(), tier))
    return cleaned


def generate_pack(
    pack_id: str,
    name: str,
    subtitle: str,
    description: str,
    lang: str,
    icon_name: str,
    primary_hex: str,
    secondary_hex: str,
    surface_hex: str,
    raw_words: List[Tuple[str, str, int]],
    level_titles: List[str],
    seed: int,
) -> dict:
    assert len(level_titles) == len(LEVEL_BLUEPRINTS), f"{pack_id} başlık sayısı 20 olmalı"
    rng = random.Random(seed)
    pool = dedupe_pool(raw_words, lang)
    used_counts: Dict[str, int] = {}
    levels = []

    for idx, (lvl, rows, cols, min_w, max_w, rev, diff_label, tier) in enumerate(LEVEL_BLUEPRINTS):
        tier_allowed = {1} if tier == 1 else ({1, 2} if tier == 2 else {1, 2, 3})
        eligible = [(w, c, t) for (w, c, t) in pool if t in tier_allowed]
        # En az kullanılan kelimelere öncelik ver (20 seviye boyunca maksimum çeşitlilik)
        min_use = min((used_counts.get(w, 0) for (w, _, _) in eligible), default=0)
        primary = [
            (w, c) for (w, c, t) in eligible
            if used_counts.get(w, 0) <= min_use
        ]
        if tier == 3:
            hard = [(w, c) for (w, c, t) in eligible if t == 3 and used_counts.get(w, 0) <= min_use]
            med = [(w, c) for (w, c, t) in eligible if t == 2 and used_counts.get(w, 0) <= min_use]
            short_conn = [(w, c) for (w, c, t) in eligible if len(w) <= 5]
            rng.shuffle(short_conn)
            primary = hard + med + short_conn[:35]

        fallback = [(w, c) for (w, c, _) in eligible]

        _, placements = build_single_puzzle(
            rows=rows,
            cols=cols,
            min_words=min_w,
            max_words=max_w,
            primary_pool=primary,
            fallback_pool=fallback,
            rng=rng,
            trials=320,
        )

        for w, _, _, _, _ in placements:
            used_counts[w] = used_counts.get(w, 0) + 1

        puzzle = assign_numbers_and_format(
            puzzle_id=f"{pack_id}_{lvl:02d}",
            level=lvl,
            title=level_titles[idx],
            difficulty=diff_label,
            rows=rows,
            cols=cols,
            placements=placements,
            initial_reveals=rev,
            rng=rng,
        )
        levels.append(puzzle)

    return {
        "id": pack_id,
        "name": name,
        "subtitle": subtitle,
        "description": description,
        "language": lang,
        "icon": icon_name,
        "primaryColor": primary_hex,
        "secondaryColor": secondary_hex,
        "surfaceColor": surface_hex,
        "levels": levels,
    }


def generate_daily_bank(
    tr_pools: List[Tuple[str, List[Tuple[str, str, int]]]],
    seed: int = 202611,
) -> dict:
    rng = random.Random(seed)
    combined: List[Tuple[str, str]] = []
    seen: Set[str] = set()
    for tag, raw in tr_pools:
        for w, c, _ in dedupe_pool(raw, "tr"):
            if w not in seen:
                seen.add(w)
                combined.append((w, f"[{tag}] {c}"))

    used_daily: Set[str] = set()
    daily_puzzles = []

    daily_configs = [
        (6, 6, 5, 7, 1, "Kolay"),
        (7, 7, 6, 8, 1, "Orta"),
        (7, 7, 7, 9, 0, "Zorlu"),
    ]

    for i in range(1, 16):
        rows, cols, min_w, max_w, rev, diff = daily_configs[(i - 1) % len(daily_configs)]
        primary = [(w, c) for (w, c) in combined if w not in used_daily]
        if len(primary) < 35:
            used_daily.clear()
            primary = list(combined)
        _, placements = build_single_puzzle(
            rows=rows,
            cols=cols,
            min_words=min_w,
            max_words=max_w,
            primary_pool=primary,
            fallback_pool=combined,
            rng=rng,
            trials=240,
        )
        for w, _, _, _, _ in placements:
            used_daily.add(w)
        puzzle = assign_numbers_and_format(
            puzzle_id=f"daily_{i:02d}",
            level=i,
            title=f"Günün Bulmacası #{i}",
            difficulty=diff,
            rows=rows,
            cols=cols,
            placements=placements,
            initial_reveals=rev,
            rng=rng,
        )
        daily_puzzles.append(puzzle)

    return {
        "id": "daily",
        "name": "Günün Bulmacası",
        "language": "tr",
        "puzzles": daily_puzzles,
    }


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    packs_spec = [
        (
            "yesilcam",
            "Yeşilçam Klasikleri",
            "Efsane filmler, replikler ve yıldızlar",
            "Hababam'dan Al Yazmalım'a, Tosun Paşa'dan Neşeli Günler'e 20 bölümlük nostaljik sinema yolculuğu.",
            "tr",
            "movie",
            "#B45309",
            "#7C2D12",
            "#FFFBEB",
            YESILCAM_WORDS,
            [
                "İlk Perde", "Hababam Zili", "Yazlık Sinema", "Turşu Kavgası",
                "Beyaz Perde", "Çamlıca Lisesi", "Mavi Boncuk", "Süt Kardeşler",
                "Çiçek Abbas", "Yeşil Vadi", "Gülen Gözler", "Banker Bilo",
                "Kibar Feyzo", "Dört Yapraklı Yonca", "Taçsız Kral", "Turist Ömer",
                "Vesikalı Yarim", "Usta Yönetmenler", "Beyoğlu Nostaljisi", "Yeşilçam Galası",
            ],
            101,
        ),
        (
            "ingilizce",
            "İngilizce Kelime Avı",
            "A1'den basit B1'e keyifli İngilizce",
            "Günlük hayattan tanıdık, zorlamadan geliştiren A1-A2-B1 İngilizce kelimelerle 20 keyifli bölüm.",
            "en",
            "translate",
            "#1D4ED8",
            "#1E3A8A",
            "#EFF6FF",
            INGILIZCE_WORDS,
            [
                "İlk Kelimeler (A1)", "Günlük Hayat (A1)", "Renkler ve Doğa (A1)", "Ev ve Eşyalar (A1)",
                "Yemek ve Kafe (A1-A2)", "Aile ve Dostluk (A2)", "Okul ve Dersler (A2)", "Mevsimler ve Hava (A2)",
                "Şehirde Bir Gün (A2)", "Yolculuk Zamanı (A2)", "Müzik ve Sinema (A2)", "Spor ve Oyun (A2)",
                "Mutfak ve Lezzet (A2)", "Dijital Dünya (A2-B1)", "Hayvanlar Alemi (A2-B1)", "İş ve Ofis (B1)",
                "Duygular ve Hayaller (B1)", "Kültür ve Sanat (B1)", "Bilim ve Gelecek (B1)", "İngilizce Ustası (B1)",
            ],
            202,
        ),
        (
            "turkiye",
            "Türkiye & Mutfak",
            "İller, yöresel lezzetler ve miras",
            "Ege'den Karadeniz'e, baklavadan antik kentlere Türkiye'nin dört bir yanından 20 özel bulmaca.",
            "tr",
            "explore",
            "#0F766E",
            "#115E59",
            "#F0FDFA",
            TURKIYE_WORDS,
            [
                "Sabah Sofrası", "Ege Rüzgarı", "Karadeniz Çayı", "Anadolu Lezzetleri",
                "Dört Deniz", "Kahve Molası", "Yöresel Tatlar", "Şehir Turu",
                "Tarihi İzler", "Zanaat ve Kültür", "Akdeniz Güneşi", "İç Anadolu",
                "Doğu'nun İncileri", "Zirveler ve Nehirler", "Ege Koyları", "Antik Kentler",
                "Gastronomi Şöleni", "Kadim Miras", "Kervan Yolları", "Büyük Türkiye Turu",
            ],
            303,
        ),
        (
            "genel_kultur",
            "Genel Kültür & Bilim",
            "Uzay, teknoloji, sanat ve spor",
            "Gezegenlerden teknolojiye, edebiyattan spora her seviyede keyifle çözülecek 20 genel kültür bölümü.",
            "tr",
            "psychology",
            "#6D28D9",
            "#4C1D95",
            "#F5F3FF",
            GENEL_KULTUR_WORDS,
            [
                "Temel Bilgi", "Yıldızlara Bakış", "Sanat Atölyesi", "Spor Sahası",
                "Doğanın Gücü", "Müzik ve Ritim", "Dijital Çağ", "İnsan ve Sağlık",
                "Bilim Laboratuvarı", "Dünya Coğrafyası", "Tarih Sahnesi", "Gezegenler",
                "Edebiyat Dünyası", "Oyun ve Strateji", "Keşifler Çağı", "Akıl ve Mantık",
                "Teknoloji Üssü", "Klasik Sanatlar", "Derin Evren", "Büyük Usta",
            ],
            404,
        ),
    ]

    manifest_packs = []
    for spec in packs_spec:
        pack = generate_pack(*spec)
        out_path = OUT_DIR / f"{pack['id']}.json"
        out_path.write_text(json.dumps(pack, ensure_ascii=False, indent=2), encoding="utf-8")
        word_counts = [len(lvl["entries"]) for lvl in pack["levels"]]
        sizes = [f"{lvl['rows']}x{lvl['cols']}" for lvl in pack["levels"]]
        print(f"[OK] {pack['id']:14s} -> {len(pack['levels'])} seviye | boyutlar: {sizes[0]}..{sizes[-1]} | kelimeler: {word_counts}")
        manifest_packs.append(f"assets/puzzles/{pack['id']}.json")

    daily = generate_daily_bank([
        ("Yeşilçam", YESILCAM_WORDS),
        ("Türkiye", TURKIYE_WORDS),
        ("Genel Kültür", GENEL_KULTUR_WORDS),
    ])
    daily_path = OUT_DIR / "daily.json"
    daily_path.write_text(json.dumps(daily, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[OK] {'daily':14s} -> {len(daily['puzzles'])} günlük bulmaca üretildi ve doğrulandı!")

    manifest_path = OUT_DIR / "manifest.json"
    manifest_path.write_text(
        json.dumps({"packs": manifest_packs, "daily": "assets/puzzles/daily.json"}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"\nToplam 95 bulmaca başarıyla {OUT_DIR} içine yazıldı.")


if __name__ == "__main__":
    main()
