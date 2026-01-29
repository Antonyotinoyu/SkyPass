from tkinter import *
from tkinter import ttk, messagebox
import mysql.connector
from datetime import datetime
import os


# --- VERİTABANI BAĞLANTISI ---
def baglan():
    try:
        baglanti = mysql.connector.connect(
            host="127.0.0.1",
            port=3306,
            user="root",
            password="",
            database="havalimani_final"
        )
        return baglanti
    except mysql.connector.Error as error:
        print(f"Bağlantı Hatası: {error}")
        return None


# --- RENK PALETİ ---
ANA_MAVI = "#3498db"
HOVER_MAVI = "#2980b9"
KOYU_LACIVERT = "#1e272e"
ARKA_PLAN = "#f5f6fa"
BEYAZ = "#ffffff"
TEXT_GRI = "#7f8c8d"
SUCCESS_GREEN = "#2ecc71"
DANGER_RED = "#e74c3c"
HOVER_RED = "#c0392b"
KOYU_YAZI = "#2c3e50"

# GLOBAL DEĞİŞKEN (Oturum bilgisi için)
session_user = {"id": None}


def ana_sayfa_ac(kullanici_id=3):
    session_user["id"] = kullanici_id

    index_root = Tk()
    index_root.title("SkyPass | Uçuş Yönetim Sistemi")
    index_root.state('zoomed')
    index_root.configure(bg=ARKA_PLAN)

    # --- YARDIMCI FONKSİYONLAR ---
    def icerigi_temizle():
        for widget in content.winfo_children(): widget.destroy()

    def buton_olustur(parent, text, bg_color, hover_color, command):
        btn = Button(parent, text=text, bg=bg_color, fg="white", font=("Helvetica", 10, "bold"), bd=0, cursor="hand2",
                     command=command)
        btn.bind("<Enter>", lambda e: btn.config(bg=hover_color))
        btn.bind("<Leave>", lambda e: btn.config(bg=bg_color))
        return btn

    def placeholder_ekle(entry, placeholder_text):
        # Placeholder yazısı eklenir
        entry.insert(0, placeholder_text)
        entry.config(fg=TEXT_GRI)

        def on_focus_in(event):
            # Entry tıklanınca placeholder silinir
            if entry.get() == placeholder_text:
                entry.delete(0, END)
                entry.config(fg=KOYU_YAZI)

        def on_focus_out(event):
            # Boş kalırsa placeholder geri gelir
            if entry.get() == "":
                entry.insert(0, placeholder_text)
                entry.config(fg=TEXT_GRI)

        entry.bind("<FocusIn>", on_focus_in)
        entry.bind("<FocusOut>", on_focus_out)

    def cikis_yap():
        if messagebox.askyesno("Çıkış", "Oturumu kapatmak istediğinize emin misiniz?"):
            index_root.destroy()
            os.system("python login.py")

    # --- UI ANA YAPI ---
    header = Frame(index_root, bg=BEYAZ, height=65, bd=0, highlightthickness=1, highlightbackground="#dcdde1")
    header.pack(side=TOP, fill=X)
    Label(header, text="SKYPASS ✈", font=("Helvetica", 18, "bold"), bg=BEYAZ, fg=ANA_MAVI).pack(side=LEFT, padx=30)

    btn_logout = Button(header, text="Çıkış Yap", bg=DANGER_RED, fg="white", font=("Helvetica", 9, "bold"),
                        bd=0, cursor="hand2", padx=15, pady=5, command=cikis_yap)
    btn_logout.pack(side=RIGHT, padx=30)

    sidebar = Frame(index_root, bg=KOYU_LACIVERT, width=100)
    sidebar.pack(side=LEFT, fill=Y)
    content = Frame(index_root, bg=ARKA_PLAN)
    content.pack(side=RIGHT, expand=True, fill=BOTH, padx=40, pady=30)

    # =========================================================================
    # SAYFALAR
    # =========================================================================

    def sayfa_anasayfa():
        icerigi_temizle()
        search_f = Frame(content, bg=BEYAZ, padx=30, pady=30)
        search_f.pack(fill=X, pady=(0, 20))
        Label(search_f, text="Nereye Uçmak İstersiniz?", font=("Helvetica", 16, "bold"), bg=BEYAZ).pack(anchor=W)

        ent_ara = Entry(search_f, font=("Helvetica", 12), bg=ARKA_PLAN, bd=0, highlightthickness=1,
                        highlightbackground="#dcdde1")
        ent_ara.pack(side=LEFT, expand=True, fill=X, ipady=10, padx=(0, 10))
        placeholder_ekle(ent_ara, "Havalimanı adı girin...")

        def arama_tetikle():
            query = ent_ara.get().strip()
            if query in ("", "Havalimanı adı girin..."):
                messagebox.showwarning("Uyarı", "Lütfen bir havalimanı adı girin.")
                return
            sayfa_ucuslar(query)

        buton_olustur(search_f, "UÇUŞ ARA", ANA_MAVI, HOVER_MAVI, arama_tetikle).pack(side=LEFT, padx=5, ipady=8)

        cards_frame = Frame(content, bg=ARKA_PLAN)
        cards_frame.pack(fill=X, pady=20)
        conn = baglan()
        stats = {"u": "0", "k": "0"}
        if conn:
            cur = conn.cursor()
            cur.callproc("toplamUcusSayisi")
            # Fetchone 1 tane veri için
            for r in cur.stored_results(): stats["u"] = r.fetchone()[0]
            cur.callproc("toplamKullaniciSayisi")
            for r in cur.stored_results(): stats["k"] = r.fetchone()[0]
            conn.close()

        def card_stat(t, v, i, c):
            f = Frame(cards_frame, bg=BEYAZ, padx=20, pady=20)
            f.pack(side=LEFT, expand=True, fill=BOTH, padx=5)
            Label(f, text=i, font=("Arial", 25), fg=c, bg=BEYAZ).pack(anchor=W)
            Label(f, text=v, font=("Helvetica", 20, "bold"), bg=BEYAZ).pack(anchor=W)
            Label(f, text=t, fg=TEXT_GRI, bg=BEYAZ).pack(anchor=W)

        card_stat("Toplam Sefer", stats["u"], "✈", ANA_MAVI)
        card_stat("Kayıtlı Yolcu", stats["k"], "👥", SUCCESS_GREEN)
        card_stat("Havalimanı Sayısı", "20", "🏢", "#9b59b6")

    def sayfa_ucuslar(filtre=""):
        icerigi_temizle()
        Label(content, text="Müsait Uçuşlar", font=("Helvetica", 20, "bold"), bg=ARKA_PLAN).pack(anchor=W, pady=10)
        tree_f = Frame(content, bg=BEYAZ, padx=10, pady=10)
        tree_f.pack(fill=BOTH, expand=True)

        cols = ("id", "kod", "havalimani", "tarih", "kalkis", "varis")
        tree = ttk.Treeview(tree_f, columns=cols, show="headings")
        for c in cols: tree.heading(c, text=c.upper())
        tree.column("id", width=50)

        conn = baglan()
        if conn:
            cur = conn.cursor()
            if filtre and filtre != "Havalimanı adı girin...":
                cur.callproc("ucusAra", (filtre,))
                results = cur.stored_results()
            else:
                cur.execute(
                    "SELECT u.ucus_id, h.havaalani_kod, h.havaalani_ad, u.tarih, u.kalkis_saati, u.varis_saati FROM ucuslar u JOIN havaalanlari h ON u.kalkis_havaalani_id = h.havaalani_id")
                results = [cur]

            for r in results:
                for row in r.fetchall(): tree.insert("", END, values=row)
            conn.close()
        tree.pack(fill=BOTH, expand=True)

        def bilet_al(kid, kno, uid, y_ad, y_soyad, y_tc, y_win, s_win):
            conn = baglan()
            if not conn: return
            try:
                cur = conn.cursor()
                cur.execute("SELECT fiyat FROM ucuslar WHERE ucus_id=%s", (uid,))
                # Fetchone 1 tane veri için
                fiyat = cur.fetchone()[0]
                cur.execute(
                    "INSERT INTO rezervasyonlar (kullanici_id, ucus_id, tarih, durum) VALUES (%s,%s,NOW(),'Onaylandı')",
                    (session_user['id'], uid))
                rid = cur.lastrowid
                cur.execute(
                    "INSERT INTO odeme (rezervasyon_id, tutar, odeme_tarihi, odeme_tipi, durum) VALUES (%s,%s,NOW(),'Kart','Başarılı')",
                    (rid, fiyat))
                b_no = f"TK-{rid}{kid}"
                cur.execute(
                    "INSERT INTO biletler (rezervasyon_id, koltuk_id, bilet_no, kesim_tarihi) VALUES (%s,%s,%s,NOW())",
                    (rid, kid, b_no))

                # Son eklenen biletin id'sini çekmek için
                bid = cur.lastrowid
                cur.execute("INSERT INTO yolcu_bilgileri (bilet_id, ad, soyad, tc_pasaport) VALUES (%s, %s, %s, %s)",
                            (bid, y_ad, y_soyad, y_tc))
                conn.commit()
                messagebox.showinfo("Başarılı", f"Bilet No: {b_no}")
                y_win.destroy();
                s_win.destroy();
                sayfa_biletlerim()
            except Exception as e:

                # Rollback -> yukarı bir transaction yapısı var ve hata çıkması sonucuna karşılık rollback ile işlemi iptal ediyoruz.
                conn.rollback();
                messagebox.showerror("Hata", str(e))
            finally:
                conn.close()

        def yolcu_bilgileri_formu(kid, kno, uid, seat_win):
            y_win = Toplevel(seat_win)
            y_win.title("Yolcu Bilgileri")
            y_win.geometry("400x500")
            y_win.configure(bg=BEYAZ)
            Label(y_win, text="Yolcu Detayları", font=("Helvetica", 14, "bold"), bg=BEYAZ, fg=ANA_MAVI).pack(pady=20)

            fields = [("Yolcu Adı:", "ad"), ("Yolcu Soyadı:", "soyad"), ("TC / Pasaport No:", "tc")]
            ents = {}
            for label, key in fields:
                f = Frame(y_win, bg=BEYAZ, pady=10);
                f.pack(fill=X, padx=40)
                Label(f, text=label, bg=BEYAZ).pack(anchor=W)
                e = Entry(f, font=("Helvetica", 11), bd=1, relief=SOLID);
                e.pack(fill=X, ipady=5);
                ents[key] = e

            def islemi_bitir():
                if not all([ents[k].get().strip() for k in ents]):
                    messagebox.showwarning("Hata", "Tüm alanları doldurun.");
                    return
                bilet_al(kid, kno, uid, ents["ad"].get(), ents["soyad"].get(), ents["tc"].get(), y_win, seat_win)

            Button(y_win, text="ÖDEME VE KAYDI TAMAMLA", bg=SUCCESS_GREEN, fg="white", font=("Helvetica", 10, "bold"),
                   command=islemi_bitir).pack(pady=30, padx=40, fill=X)

        def koltuk_win():
            sel = tree.selection()
            if not sel: messagebox.showwarning("Uyarı", "Uçuş seçin!"); return
            u_id = tree.item(sel)["values"][0]
            win = Toplevel(index_root);
            win.geometry("600x700");
            win.title("Koltuklar");
            win.configure(bg=BEYAZ)
            seat_f = Frame(win, bg=BEYAZ);
            seat_f.pack(expand=True, fill=BOTH, padx=20, pady=20)
            c = baglan();
            cur = c.cursor()
            cur.callproc("bosKoltuklariGetir", (u_id,))
            count = 0;
            found = False
            for r in cur.stored_results():
                # Fetchall - birden fazla listeleme için
                for s in r.fetchall():
                    found = True
                    Button(seat_f, text=f"{s[2]}\n{s[3]}", width=10, height=3,
                           # lambda: Fonksiyonun program açılır açılmaz çalışmasını engeller, butona "tıklanınca" çalış der.
    # sid ve sno: Döngü dönerken, o anki 0. ve 2. sütundaki verileri "o butona özel olarak kaydetmek" için kullandığımız değişkenler.
                           command=lambda sid=s[0], sno=s[2]: yolcu_bilgileri_formu(sid, sno, u_id, win)).grid(
                        row=count // 5, column=count % 5, padx=5, pady=5)
                    count += 1
            if not found: Label(seat_f, text="Boş koltuk yok.").pack()
            c.close()

        buton_olustur(content, "KOLTUKLARI GÖR VE SATIN AL", SUCCESS_GREEN, "#27ae60", koltuk_win).pack(pady=20)

    def sayfa_biletlerim():
        icerigi_temizle()
        Label(content, text="Biletlerim", font=("Helvetica", 20, "bold"), bg=ARKA_PLAN).pack(anchor=W, pady=10)
        table_f = Frame(content, bg=BEYAZ, padx=10, pady=10);
        table_f.pack(fill=BOTH, expand=True)
        cols = ("bilet_no", "rota", "koltuk", "tarih", "tutar", "durum")
        # Veritabanından çekilen verileri excel tablosu gibi göstermek için kullanılır
        tablo = ttk.Treeview(table_f, columns=cols, show="headings")
        for c in cols: tablo.heading(c, text=c.upper())

        def yenile():
            for i in tablo.get_children(): tablo.delete(i)
            conn = baglan()
            if conn:
                cur = conn.cursor()
                sql = """SELECT b.bilet_no, CONCAT(h1.havaalani_ad, ' - ', h2.havaalani_ad), k.koltuk_no, u.tarih, CONCAT(o.tutar, ' TL'), r.durum 
                         FROM biletler b JOIN rezervasyonlar r ON b.rezervasyon_id = r.rezervasyon_id JOIN odeme o ON r.rezervasyon_id = o.rezervasyon_id
                         JOIN koltuklar k ON b.koltuk_id = k.koltuk_id JOIN ucuslar u ON r.ucus_id = u.ucus_id
                         JOIN havaalanlari h1 ON u.kalkis_havaalani_id = h1.havaalani_id JOIN havaalanlari h2 ON u.varis_havaalani_id = h2.havaalani_id
                         WHERE r.kullanici_id = %s"""
                cur.execute(sql, (session_user['id'],))
                for row in cur.fetchall(): tablo.insert("", END, values=row)
                conn.close()

        def iptal():
            sel = tablo.selection()
            if not sel: return
            b_no = tablo.item(sel)["values"][0]
            if tablo.item(sel)["values"][5] == "İptal Edildi": return
            if messagebox.askyesno("Onay", "İptal edilsin mi?"):
                conn = baglan();
                cur = conn.cursor()
                cur.execute(
                    "UPDATE rezervasyonlar r JOIN biletler b ON r.rezervasyon_id = b.rezervasyon_id SET r.durum = 'İptal Edildi' WHERE b.bilet_no = %s",
                    (b_no,))
                conn.commit();
                conn.close();
                yenile()

        yenile();
        tablo.pack(fill=BOTH, expand=True)
        buton_olustur(content, "SEÇİLİ BİLETİ İPTAL ET ❌", DANGER_RED, HOVER_RED, iptal).pack(pady=20)

    def sayfa_profil():
        icerigi_temizle()
        p_frame = Frame(content, bg=BEYAZ, padx=30, pady=30)
        p_frame.pack(fill=BOTH, expand=True)
        conn = baglan()
        if not conn: return
        try:
            cur = conn.cursor()
            cur.callproc("kullaniciBilgisiGetir", (session_user['id'],))
            u = None
            for r in cur.stored_results(): u = r.fetchone()
            if not u: return
            fields = [("Ad", u[1]), ("Soyad", u[2]), ("E-posta", u[5]), ("Telefon", u[4]),
                      ("Doğum Tarihi", str(u[6]) if u[6] is not None else "")]
            ents = {}
            for l, v in fields:
                f = Frame(p_frame, bg=BEYAZ, pady=5);
                f.pack(fill=X)
                Label(f, text=l, width=25, anchor=W, bg=BEYAZ, font=("Helvetica", 10, "bold")).pack(side=LEFT)
                e = Entry(f, font=("Helvetica", 10), bd=1);
                e.insert(0, v if v and v != "None" else "");
                e.pack(side=LEFT, fill=X, expand=True);
                ents[l] = e

            def kaydet():
                c = baglan()
                if not c: return
                try:
                    cr = c.cursor()
                    sql = "UPDATE kullanicilar SET kullanici_adi=%s, kullanici_soyad=%s, kullanici_mail=%s, kullanici_telefon=%s, dogum_tarihi=%s WHERE kullanici_id=%s"
                    cr.execute(sql,
                               (ents["Ad"].get(), ents["Soyad"].get(), ents["E-posta"].get(), ents["Telefon"].get(),
                                ents["Doğum Tarihi"].get() if ents["Doğum Tarihi"].get() != "" else None,
                                session_user['id']))
                    c.commit();
                    messagebox.showinfo("Başarılı", "Güncellendi.");
                    sayfa_profil()
                except Exception as e:
                    messagebox.showerror("Hata", str(e))
                finally:
                    c.close()

            buton_olustur(p_frame, "BİLGİLERİ KAYDET ✅", SUCCESS_GREEN, "#27ae60", kaydet).pack(pady=20)
        except Exception as e:
            messagebox.showerror("Hata", str(e))
        finally:
            conn.close()

    # --- SIDEBAR NAV ---
    def nav(t, i, c):
        f = Frame(sidebar, bg=KOYU_LACIVERT, pady=10);
        f.pack(fill=X)
        Button(f, text=i, font=("Arial", 18), bg=KOYU_LACIVERT, fg="white", bd=0, command=c).pack()
        Label(f, text=t, font=("Helvetica", 8), bg=KOYU_LACIVERT, fg=TEXT_GRI).pack()

    nav("Anasayfa", "🏠", sayfa_anasayfa)
    nav("Uçuşlar", "✈", sayfa_ucuslar)
    nav("Biletlerim", "🎫", sayfa_biletlerim)
    nav("Profilim", "👤", sayfa_profil)

    sayfa_anasayfa()
    index_root.mainloop()

# doğrudan çalıştırıldığında açılan ilk pencere olsun kontrolü
if __name__ == "__main__":
    ana_sayfa_ac()