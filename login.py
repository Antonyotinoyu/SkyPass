from tkinter import *
from tkinter import messagebox
import mysql.connector


def baglan():
    try:
        baglanti = mysql.connector.connect(
            host="127.0.0.1",
            port=3306,
            user="root",
            password="",
            database="havalimani_final"
        )
        print("Veri Tabanı Bağlantısı Başarılı")
        return baglanti
    except mysql.connector.Error as error:
        print(f"Hata Mesajı: {error}")
        return None



# --- RENK PALETİ ---
ANA_MAVI = "#3498db"
KOYU_MAVI = "#2980b9"
ARKA_PLAN = "#f0f2f5"
KART_BEYAZ = "#ffffff"
YAZI_GRI = "#7f8c8d"
KOYU_YAZI = "#2c3e50"


def ekranin_ortasina_al(pencere, genislik, yukseklik):
    ekran_genisligi = pencere.winfo_screenwidth()
    ekran_yuksekligi = pencere.winfo_screenheight()
    x = (ekran_genisligi // 2) - (genislik // 2)
    y = (ekran_yuksekligi // 2) - (yukseklik // 2)
    pencere.geometry(f"{genislik}x{yukseklik}+{x}+{y}")


# --- ANA UYGULAMA PENCERESİ ---
root = Tk()
root.title("SkyPass | Giriş Sistemi")
ekranin_ortasina_al(root, 450, 680)
root.configure(bg=ARKA_PLAN)
root.resizable(False, False)


def sayfa_degistir(suanki, hedef):
    suanki.pack_forget()
    hedef.pack(expand=True, fill=BOTH)


# --- HOVER VE PLACEHOLDER FONKSİYONLARI ---
def btn_on_enter(e, btn): btn.config(bg=KOYU_MAVI)


def btn_on_leave(e, btn): btn.config(bg=ANA_MAVI)


def link_on_enter(e, label): label.config(fg=ANA_MAVI)


def link_on_leave(e, label): label.config(fg=YAZI_GRI)


def placeholder_ayar(entry, text, mode="in"):
    if mode == "in":
        if entry.get() == text:
            entry.delete(0, END)
            entry.config(fg=KOYU_YAZI)
            if "Şifre" in text: entry.config(show="●")
    else:
        if entry.get() == "":
            entry.insert(0, text)
            entry.config(fg="#bdc3c7")
            if "Şifre" in text: entry.config(show="")



# --- GİRİŞ İŞLEMİ ---
def login_islem():
    mail = entry_u_l.get().strip()
    sif = entry_p_l.get().strip()

    # Placeholder veya boşluk kontrolü
    if mail in ("", "E-posta Adresi") or sif in ("", "Şifre"):
        messagebox.showwarning("Hata", "Lütfen tüm alanları eksiksiz doldurunuz.")
        return

    baglanti = None
    try:
        baglanti = baglan()
        if baglanti:
            cursor = baglanti.cursor()

            # SQL'deki girisKontrol procedure'ünü çağırıyoruz
            # Procedure Tanımı: girisKontrol(mail VARCHAR, sifre VARCHAR)
            cursor.callproc("girisKontrol", (mail, sif))

            # callproc sonrası sonuçları almak için stored_results kullanılır
            result = None
            for res in cursor.stored_results():
                result = res.fetchone()


                if result:
                    kullanici_id = result[0]
                    messagebox.showinfo("Başarılı", f"Hoş geldiniz! Dashboard açılıyor...")

                    root.destroy()
                    try:
                        import index

                        index.ana_sayfa_ac(kullanici_id)
                    except ImportError:
                        messagebox.showerror("Hata", "index.py dosyası bulunamadı!")
            else:
                messagebox.showerror("Başarısız", "E-posta adresi veya şifre hatalı!")

            cursor.close()
        else:
            messagebox.showerror("Bağlantı Hatası", "Veritabanı bağlantısı kurulamadı.")

    except mysql.connector.Error as err:
        messagebox.showerror("Sistem Hatası", f"Giriş yapılırken bir hata oluştu: {err}")
    finally:
        if baglanti and baglanti.is_connected():
            baglanti.close()


# --- 1. GİRİŞ EKRANI (LOGIN) ---
login_frame = Frame(root, bg=KART_BEYAZ)
login_frame.pack(expand=True, fill=BOTH, padx=40, pady=40)

Frame(login_frame, bg=ANA_MAVI, height=8).pack(side=TOP, fill=X)
Label(login_frame, text="✈", font=("Arial", 50), bg=KART_BEYAZ, fg=ANA_MAVI).pack(pady=(30, 0))
Label(login_frame, text="SkyPass", font=("Helvetica", 24, "bold"), bg=KART_BEYAZ, fg=KOYU_YAZI).pack()

entry_u_l = Entry(login_frame, font=("Helvetica", 11), bg="#f8f9fa", fg="#bdc3c7", bd=0, highlightthickness=1,
                  highlightbackground="#dcdde1", highlightcolor=ANA_MAVI)
entry_u_l.insert(0, "E-posta Adresi")
entry_u_l.bind('<FocusIn>', lambda e: placeholder_ayar(entry_u_l, "E-posta Adresi", "in"))
entry_u_l.bind('<FocusOut>', lambda e: placeholder_ayar(entry_u_l, "E-posta Adresi", "out"))
entry_u_l.pack(pady=10, ipady=10, ipadx=15)

entry_p_l = Entry(login_frame, font=("Helvetica", 11), bg="#f8f9fa", fg="#bdc3c7", bd=0, highlightthickness=1,
                  highlightbackground="#dcdde1", highlightcolor=ANA_MAVI)
entry_p_l.insert(0, "Şifre")
entry_p_l.bind('<FocusIn>', lambda e: placeholder_ayar(entry_p_l, "Şifre", "in"))
entry_p_l.bind('<FocusOut>', lambda e: placeholder_ayar(entry_p_l, "Şifre", "out"))
entry_p_l.pack(pady=5, ipady=10, ipadx=15)

lbl_forgot = Label(login_frame, text="Şifremi Unuttum?", font=("Helvetica", 9), bg=KART_BEYAZ, fg=YAZI_GRI,
                   cursor="hand2")
lbl_forgot.pack(anchor=E, padx=35)
lbl_forgot.bind("<Button-1>", lambda e: sayfa_degistir(login_frame, forgot_frame))
lbl_forgot.bind("<Enter>", lambda e: link_on_enter(e, lbl_forgot))
lbl_forgot.bind("<Leave>", lambda e: link_on_leave(e, lbl_forgot))

btn_l = Button(login_frame, text="GİRİŞ YAP", bg=ANA_MAVI, fg="white", font=("Helvetica", 11, "bold"), bd=0,
               cursor="hand2", command=login_islem)
btn_l.pack(pady=30, ipadx=75, ipady=12)
btn_l.bind("<Enter>", lambda e: btn_on_enter(e, btn_l))
btn_l.bind("<Leave>", lambda e: btn_on_leave(e, btn_l))

alt_l = Frame(login_frame, bg=KART_BEYAZ)
alt_l.pack(side=BOTTOM, pady=20)
Label(alt_l, text="Hesabınız yok mu?", bg=KART_BEYAZ, fg=KOYU_YAZI).pack(side=LEFT)
lbl_to_reg = Label(alt_l, text="Kayıt Ol", font=("Helvetica", 10, "bold"), bg=KART_BEYAZ, fg=ANA_MAVI, cursor="hand2")
lbl_to_reg.pack(side=LEFT, padx=5)
lbl_to_reg.bind("<Button-1>", lambda e: sayfa_degistir(login_frame, register_frame))
lbl_to_reg.bind("<Enter>", lambda e: link_on_enter(e, lbl_to_reg))
lbl_to_reg.bind("<Leave>", lambda e: link_on_leave(e, lbl_to_reg))


def kayitOl():
    # Entry'lerden verileri al ve kenar boşluklarını temizle
    ad = entry_ad_r.get().strip()
    soyad = entry_soyad_r.get().strip()
    mail = entry_mail_r.get().strip()
    sifre = entry_sifre_r.get().strip()

    # Placeholder değerleri veya boş giriş kontrolü
    if ad in ("", "Ad") or soyad in ("", "Soyad") or mail in ("", "Email") or sifre in ("", "Şifre"):
        messagebox.showwarning("Hata", "Lütfen tüm alanları eksiksiz doldurunuz.")
        return

    baglanti = None
    try:
        baglanti = baglan()  # login.py içindeki mevcut baglan fonksiyonu
        if baglanti:
            cursor = baglanti.cursor()

            # Cursor sql sorgularını çalıştırmak ve sonuçları satır satır okumaya yarar

            # Güncel Stored Procedure çağrısı (4 parametre: ad, soyad, mail, sifre)
            # args = Parametreler
            args = (ad, soyad, mail, sifre)
            # callproc -> veri tabanındaki prosedürü kullanmak için kullanılır
            cursor.callproc("kullaniciKayit", args)

            baglanti.commit()
            cursor.close()

            messagebox.showinfo("Başarılı", f"Hoş geldiniz {ad} {soyad}! Kaydınız başarıyla tamamlandı.")
            # Kayıt sonrası giriş ekranına yönlendir
            sayfa_degistir(register_frame, login_frame)
        else:
            messagebox.showerror("Bağlantı Hatası", "Veritabanına bağlanılamadı.")

    except mysql.connector.Error as hata:
        # Mail adresi UNIQUE olduğu için çakışma durumunda hata verir
        messagebox.showerror("Sistem Hatası", f"Kayıt oluşturulamadı: {hata}")
    finally:
        if baglanti and baglanti.is_connected():
            baglanti.close()


# --- 2. KAYIT EKRANI (REGISTER) ---
register_frame = Frame(root, bg=KART_BEYAZ)

# Üst Dekoratif Çizgi ve Başlık
Frame(register_frame, bg=ANA_MAVI, height=8).pack(side=TOP, fill=X)
Label(register_frame, text="👤", font=("Arial", 45), bg=KART_BEYAZ, fg=ANA_MAVI).pack(pady=(20, 0))
Label(register_frame, text="Yeni Hesap Oluştur", font=("Helvetica", 18, "bold"), bg=KART_BEYAZ, fg=KOYU_YAZI).pack(pady=(0, 15))

# --- GİRİŞ ALANLARI (ENTRY) ---

# Ad Girişi
entry_ad_r = Entry(register_frame, font=("Helvetica", 11), bg="#f8f9fa", fg="#bdc3c7", bd=0,
                   highlightthickness=1, highlightbackground="#dcdde1", highlightcolor=ANA_MAVI)
entry_ad_r.insert(0, "Ad")
entry_ad_r.bind('<FocusIn>', lambda e: placeholder_ayar(entry_ad_r, "Ad", "in"))
entry_ad_r.bind('<FocusOut>', lambda e: placeholder_ayar(entry_ad_r, "Ad", "out"))
entry_ad_r.pack(pady=8, ipady=8, ipadx=15)

# Soyad Girişi
entry_soyad_r = Entry(register_frame, font=("Helvetica", 11), bg="#f8f9fa", fg="#bdc3c7", bd=0,
                      highlightthickness=1, highlightbackground="#dcdde1", highlightcolor=ANA_MAVI)
entry_soyad_r.insert(0, "Soyad")
entry_soyad_r.bind('<FocusIn>', lambda e: placeholder_ayar(entry_soyad_r, "Soyad", "in"))
entry_soyad_r.bind('<FocusOut>', lambda e: placeholder_ayar(entry_soyad_r, "Soyad", "out"))
entry_soyad_r.pack(pady=8, ipady=8, ipadx=15)

# Email Girişi
entry_mail_r = Entry(register_frame, font=("Helvetica", 11), bg="#f8f9fa", fg="#bdc3c7", bd=0,
                     highlightthickness=1, highlightbackground="#dcdde1", highlightcolor=ANA_MAVI)
entry_mail_r.insert(0, "Email")
entry_mail_r.bind('<FocusIn>', lambda e: placeholder_ayar(entry_mail_r, "Email", "in"))
entry_mail_r.bind('<FocusOut>', lambda e: placeholder_ayar(entry_mail_r, "Email", "out"))
entry_mail_r.pack(pady=8, ipady=8, ipadx=15)

# Şifre Girişi
entry_sifre_r = Entry(register_frame, font=("Helvetica", 11), bg="#f8f9fa", fg="#bdc3c7", bd=0,
                      highlightthickness=1, highlightbackground="#dcdde1", highlightcolor=ANA_MAVI)
entry_sifre_r.insert(0, "Şifre")
entry_sifre_r.bind('<FocusIn>', lambda e: placeholder_ayar(entry_sifre_r, "Şifre", "in"))
entry_sifre_r.bind('<FocusOut>', lambda e: placeholder_ayar(entry_sifre_r, "Şifre", "out"))
entry_sifre_r.pack(pady=8, ipady=8, ipadx=15)

# --- İŞLEM BUTONU ---
btn_r = Button(register_frame, text="KAYIT OL", bg=ANA_MAVI, fg="white",
               font=("Helvetica", 11, "bold"), bd=0, cursor="hand2", command=kayitOl)
btn_r.pack(pady=20, ipadx=85, ipady=12)
btn_r.bind("<Enter>", lambda e: btn_on_enter(e, btn_r))
btn_r.bind("<Leave>", lambda e: btn_on_leave(e, btn_r))

# --- ALT NAVİGASYON ---
lbl_back_l = Label(register_frame, text="← Giriş Ekranına Dön", font=("Helvetica", 9),
                   bg=KART_BEYAZ, fg=YAZI_GRI, cursor="hand2")
lbl_back_l.pack(pady=10)
lbl_back_l.bind("<Button-1>", lambda e: sayfa_degistir(register_frame, login_frame))
lbl_back_l.bind("<Enter>", lambda e: link_on_enter(e, lbl_back_l))
lbl_back_l.bind("<Leave>", lambda e: link_on_leave(e, lbl_back_l))




# --- 3. ŞİFREMİ UNUTTUM EKRANI ---

sifirlanacak_mail = ""
def sifre_sifirla_dogrula():
    global sifirlanacak_mail
    mail = f_mail_ent.get().strip()

    if mail == "" or mail == "Email Adresiniz":
        messagebox.showwarning("Hata", "Lütfen mail adresinizi giriniz.")
        return

    baglanti = baglan()  #
    if baglanti:
        try:
            cursor = baglanti.cursor()
            # mailVarMi procedure'ünü çağırıyoruz
            cursor.execute("CALL mailVarMi(%s)", (mail,))
            row = cursor.fetchone()

            if row:
                sifirlanacak_mail = mail
                # Önceki ekrandaki veriyi temizle ve geçiş yap
                entry_new_p.delete(0, END)
                entry_new_p.insert(0, "Yeni Şifre")
                entry_new_p.config(show="", fg="#bdc3c7")

                entry_new_p_confirm.delete(0, END)
                entry_new_p_confirm.insert(0, "Yeni Şifre Tekrar")
                entry_new_p_confirm.config(show="", fg="#bdc3c7")

                sayfa_degistir(forgot_frame, reset_password_frame)
            else:
                messagebox.showerror("Hata", "Bu mail adresi sistemde kayıtlı değil.")
        except mysql.connector.Error as err:
            messagebox.showerror("Hata", f"Sorgu hatası: {err}")
        finally:
            cursor.close()
            baglanti.close()


def yeni_sifre_kaydet():
    global sifirlanacak_mail
    yeni_s = entry_new_p.get().strip()
    yeni_s_tekrar = entry_new_p_confirm.get().strip()

    # Boş alan ve placeholder kontrolü
    if yeni_s in ("", "Yeni Şifre") or yeni_s_tekrar in ("", "Yeni Şifre Tekrar"):
        messagebox.showwarning("Hata", "Lütfen yeni şifre alanlarını doldurun.")
        return

    # Şifre eşleşme kontrolü
    if yeni_s != yeni_s_tekrar:
        messagebox.showerror("Hata", "Şifreler birbiriyle uyuşmuyor!")
        return

    baglanti = baglan()  #
    if baglanti:
        try:
            cursor = baglanti.cursor()

            # ÖNEMLİ: SQL Procedure parametre sırası -> (mail, yeni_sifre)
            # Sizin SQL dosyanızda: sifreGuncelle(IN mail, IN yeni_sifre)
            params = (sifirlanacak_mail, yeni_s)

            # callproc -> veri tabanındaki prosedürü kullanmak için kullanılır
            cursor.callproc("sifreGuncelle", params)

            # Değişiklikleri kaydet
            baglanti.commit()  #

            messagebox.showinfo("Başarılı", "Şifreniz başarıyla güncellendi.")

            # Giriş ekranına yönlendir
            sayfa_degistir(reset_password_frame, login_frame)

        except mysql.connector.Error as err:
            messagebox.showerror("Hata", f"Veritabanı hatası: {err}")
        finally:
            cursor.close()
            baglanti.close()


# --- 4. YENİ ŞİFRE BELİRLEME EKRANI (RESET PASSWORD) ---
reset_password_frame = Frame(root, bg=KART_BEYAZ)

Frame(reset_password_frame, bg=ANA_MAVI, height=8).pack(side=TOP, fill=X)
Label(reset_password_frame, text="🔒", font=("Arial", 45), bg=KART_BEYAZ, fg=ANA_MAVI).pack(pady=(40, 0))
Label(reset_password_frame, text="Yeni Şifre Belirle", font=("Helvetica", 18, "bold"), bg=KART_BEYAZ,
      fg=KOYU_YAZI).pack(pady=10)

# Yeni Şifre Entry
entry_new_p = Entry(reset_password_frame, font=("Helvetica", 11), bg="#f8f9fa", fg="#bdc3c7", bd=0,
                    highlightthickness=1, highlightbackground="#dcdde1", highlightcolor=ANA_MAVI)
entry_new_p.insert(0, "Yeni Şifre")
entry_new_p.bind('<FocusIn>', lambda e: placeholder_ayar(entry_new_p, "Yeni Şifre", "in"))
entry_new_p.bind('<FocusOut>', lambda e: placeholder_ayar(entry_new_p, "Yeni Şifre", "out"))
entry_new_p.pack(pady=10, ipady=10, ipadx=15)

# Yeni Şifre Tekrar Entry
entry_new_p_confirm = Entry(reset_password_frame, font=("Helvetica", 11), bg="#f8f9fa", fg="#bdc3c7", bd=0,
                            highlightthickness=1, highlightbackground="#dcdde1", highlightcolor=ANA_MAVI)
entry_new_p_confirm.insert(0, "Yeni Şifre Tekrar")
entry_new_p_confirm.bind('<FocusIn>', lambda e: placeholder_ayar(entry_new_p_confirm, "Yeni Şifre Tekrar", "in"))
entry_new_p_confirm.bind('<FocusOut>', lambda e: placeholder_ayar(entry_new_p_confirm, "Yeni Şifre Tekrar", "out"))
entry_new_p_confirm.pack(pady=10, ipady=10, ipadx=15)

btn_save = Button(reset_password_frame, text="ŞİFREYİ GÜNCELLE", bg=ANA_MAVI, fg="white",
                  font=("Helvetica", 11, "bold"), bd=0, cursor="hand2", command=yeni_sifre_kaydet)
btn_save.pack(pady=25, ipadx=60, ipady=12)
btn_save.bind("<Enter>", lambda e: btn_on_enter(e, btn_save))
btn_save.bind("<Leave>", lambda e: btn_on_leave(e, btn_save))

# --- 3. ŞİFREMİ UNUTTUM EKRANI (FORGOT PASSWORD) ---
forgot_frame = Frame(root, bg=KART_BEYAZ)
Frame(forgot_frame, bg=ANA_MAVI, height=8).pack(side=TOP, fill=X)
Label(forgot_frame, text="🔑", font=("Arial", 45), bg=KART_BEYAZ, fg=ANA_MAVI).pack(pady=(40, 0))
Label(forgot_frame, text="Şifre Kurtarma", font=("Helvetica", 20, "bold"), bg=KART_BEYAZ, fg=KOYU_YAZI).pack()

f_mail_ent = Entry(forgot_frame, font=("Helvetica", 11), bg="#f8f9fa", fg="#bdc3c7", bd=0, highlightthickness=1,
                   highlightbackground="#dcdde1", highlightcolor=ANA_MAVI)
f_mail_ent.insert(0, "Email Adresiniz")
f_mail_ent.bind('<FocusIn>', lambda e: placeholder_ayar(f_mail_ent, "Email Adresiniz", "in"))
f_mail_ent.bind('<FocusOut>', lambda e: placeholder_ayar(f_mail_ent, "Email Adresiniz", "out"))
f_mail_ent.pack(pady=20, ipady=10, ipadx=15)

btn_res = Button(forgot_frame, text="DOĞRULA", bg=ANA_MAVI, fg="white", font=("Helvetica", 11, "bold"), bd=0,
                 cursor="hand2", command=sifre_sifirla_dogrula)
btn_res.pack(pady=10, ipadx=80, ipady=12)

lbl_back_l2 = Label(forgot_frame, text="← Giriş Ekranına Dön", font=("Helvetica", 9), bg=KART_BEYAZ, fg=YAZI_GRI,
                    cursor="hand2")
lbl_back_l2.pack(pady=10)
lbl_back_l2.bind("<Button-1>", lambda e: sayfa_degistir(forgot_frame, login_frame))
root.mainloop()