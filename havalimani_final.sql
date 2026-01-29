-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Anamakine: 127.0.0.1
-- Üretim Zamanı: 29 Oca 2026, 19:29:21
-- Sunucu sürümü: 10.4.32-MariaDB
-- PHP Sürümü: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Veritabanı: `havalimani_final`
--

DELIMITER $$
--
-- Yordamlar
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `bosKoltuklariGetir` (IN `ucusID` INT)   BEGIN
    SELECT k.* FROM koltuklar k
    JOIN ucuslar u ON k.ucak_id = u.ucak_id
    WHERE u.ucus_id = ucusID AND k.koltuk_id NOT IN (SELECT koltuk_id FROM biletler);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `bugunkuUcusSayisi` ()   BEGIN
    SELECT COUNT(*) AS bugunku_toplam_sefer FROM ucuslar WHERE tarih = CURDATE();
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `girisKontrol` (IN `mail` VARCHAR(50), IN `sifre` VARCHAR(100))   BEGIN
    SELECT kullanici_id FROM kullanicilar 
    WHERE kullanici_mail = mail AND kullanici_sifre = sifre;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `havaalanlariGetir` ()   BEGIN
    SELECT havaalani_ad, havaalani_kod, havaalani_sehir, havaalani_ulke FROM havaalanlari;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `havalimaniTrafikRapor` ()   BEGIN
    SELECT 
        h.havaalani_ad,
        h.havaalani_sehir,
        (SELECT COUNT(*) FROM ucuslar WHERE kalkis_havaalani_id = h.havaalani_id) AS toplam_kalkan_ucus,
        (SELECT COUNT(*) FROM ucuslar WHERE varis_havaalani_id = h.havaalani_id) AS toplam_inen_ucus,
        SUM(t.kapasite) AS toplam_terminal_kapasitesi
    FROM havaalanlari h
    LEFT JOIN terminalbilgileri t ON h.havaalani_id = t.havaalani_id
    GROUP BY h.havaalani_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `kullaniciBilgisiGetir` (IN `id` INT)   BEGIN
    SELECT * FROM kullanicilar WHERE kullanici_id = id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `kullaniciKayit` (IN `ad` VARCHAR(20), IN `soyad` VARCHAR(20), IN `mail` VARCHAR(50), IN `sifre` VARCHAR(100))   BEGIN
    INSERT INTO kullanicilar ( kullanici_adi, kullanici_soyad, kullanici_mail, kullanici_sifre )
    VALUES ( ad,soyad,mail,sifre ); 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `kullaniciRezervasyonlari` (IN `id` INT)   BEGIN
    SELECT ucus_id, tarih, durum FROM rezervasyonlar WHERE kullanici_id = id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `mailVarMi` (IN `mail` VARCHAR(50))   BEGIN
    SELECT kullanici_id FROM kullanicilar WHERE kullanici_mail = mail;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sifreGuncelle` (IN `mail` VARCHAR(50), IN `yeni_sifre` VARCHAR(100))   BEGIN
    UPDATE kullanicilar SET kullanici_sifre = yeni_sifre WHERE kullanici_mail = mail;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_BiletsizRezervasyonlar` ()   BEGIN
    SELECT 
        r.rezervasyon_id,
        k.kullanici_mail,
        r.tarih AS Rezervasyon_Tarihi,
        r.durum
    FROM rezervasyonlar r
    JOIN kullanicilar k ON r.kullanici_id = k.kullanici_id
    WHERE r.rezervasyon_id NOT IN (SELECT rezervasyon_id FROM biletler);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_BusinessClassKoltuklar` ()   BEGIN
    SELECT 
        uc.model,
        kol.koltuk_no,
        kol.sinif,
        h.havaalani_ad AS Kalkis_Yeri
    FROM koltuklar kol
    JOIN ucaklar uc ON kol.ucak_id = uc.ucak_id
    JOIN ucuslar u ON uc.ucak_id = u.ucak_id
    JOIN havaalanlari h ON u.kalkis_havaalani_id = h.havaalani_id
    WHERE kol.sinif = 'Business'
    ORDER BY uc.model;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_HavaalaniCiroAnalizi` ()   BEGIN
    SELECT 
        h.havaalani_ad,
        COUNT(u.ucus_id) AS Toplam_Ucus_Sayisi,
        SUM(u.fiyat) AS Toplam_Ciro
    FROM ucuslar u
    JOIN havaalanlari h ON u.kalkis_havaalani_id = h.havaalani_id
    GROUP BY h.havaalani_ad
    ORDER BY Toplam_Ciro DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_KullaniciBiletDetaylari` (IN `kul_id` INT)   BEGIN
    SELECT 
        k.kullanici_adi,
        b.bilet_no,
        kol.koltuk_no,
        kol.sinif,
        b.kesim_tarihi
    FROM kullanicilar k
    JOIN rezervasyonlar r ON k.kullanici_id = r.kullanici_id
    JOIN biletler b ON r.rezervasyon_id = b.rezervasyon_id
    JOIN koltuklar kol ON b.koltuk_id = kol.koltuk_id
    WHERE k.kullanici_id = kul_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_LimitUstuOdemeler` (IN `limit_tutar` DECIMAL(10,2))   BEGIN
    SELECT 
        k.kullanici_adi,
        k.kullanici_soyad,
        r.rezervasyon_id,
        o.tutar AS Odenen_Miktar,
        o.odeme_tipi
    FROM kullanicilar k
    JOIN rezervasyonlar r ON k.kullanici_id = r.kullanici_id
    JOIN odeme o ON r.rezervasyon_id = o.rezervasyon_id
    WHERE o.tutar > limit_tutar
    ORDER BY o.tutar DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_SehireGoreGelenUcuslar` (IN `sehir_adi` VARCHAR(50))   BEGIN
    SELECT 
        u.ucus_id,
        uc.model AS Ucak_Modeli,
        h.havaalani_sehir AS Varis_Sehri,
        u.varis_saati
    FROM ucuslar u
    JOIN ucaklar uc ON u.ucak_id = uc.ucak_id
    JOIN havaalanlari h ON u.varis_havaalani_id = h.havaalani_id
    WHERE h.havaalani_sehir LIKE CONCAT('%', sehir_adi, '%');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_TarihAraliginaGoreUcuslar` (IN `baslangic_tarihi` DATE, IN `bitis_tarihi` DATE)   BEGIN
    SELECT 
        u.ucus_id,
        h1.havaalani_ad AS Kalkis_Yeri,
        h2.havaalani_ad AS Varis_Yeri,
        u.tarih,
        u.fiyat
    FROM ucuslar u
    INNER JOIN havaalanlari h1 ON u.kalkis_havaalani_id = h1.havaalani_id
    INNER JOIN havaalanlari h2 ON u.varis_havaalani_id = h2.havaalani_id
    WHERE u.tarih BETWEEN baslangic_tarihi AND bitis_tarihi
    ORDER BY u.tarih ASC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UcakModeliOrtalamaFiyat` ()   BEGIN
    SELECT 
        uc.model,
        uc.koltuk_sayisi,
        AVG(u.fiyat) AS Ortalama_Bilet_Fiyati
    FROM ucuslar u
    JOIN ucaklar uc ON u.ucak_id = uc.ucak_id
    GROUP BY uc.model;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_UlkeTerminalKapasitesi` (IN `ulke_adi` VARCHAR(50))   BEGIN
    SELECT 
        h.havaalani_ad,
        h.havaalani_sehir,
        t.terminal_adi,
        t.kapasite
    FROM havaalanlari h
    JOIN terminalbilgileri t ON h.havaalani_id = t.havaalani_id
    WHERE h.havaalani_ulke = ulke_adi;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_VipMusteriler` ()   BEGIN
    SELECT 
        k.kullanici_adi,
        k.kullanici_soyad,
        SUM(o.tutar) AS Toplam_Harcama
    FROM kullanicilar k
    JOIN rezervasyonlar r ON k.kullanici_id = r.kullanici_id
    JOIN odeme o ON r.rezervasyon_id = o.rezervasyon_id
    GROUP BY k.kullanici_id
    HAVING SUM(o.tutar) > 5000;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `toplamFiyat` (IN `sayi` INT, INOUT `toplam` INT)   BEGIN
    SET toplam = toplam + sayi;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `toplamKullaniciSayisi` ()   BEGIN
    SELECT count(kullanici_id) as Toplam_Kullanici FROM kullanicilar;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `toplamUcusSayisi` ()   BEGIN
    SELECT count(ucus_id) as Toplam_Ucus FROM ucuslar;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ucusAra` (IN `havaAlaniAd` VARCHAR(50))   BEGIN
    SELECT 
        u.ucus_id, 
        h.havaalani_kod, 
        h.havaalani_ad, 
        u.tarih, 
        u.kalkis_saati, 
        u.varis_saati 
    FROM havaalanlari h
    JOIN ucuslar u ON h.havaalani_id = u.kalkis_havaalani_id
    WHERE h.havaalani_ad LIKE CONCAT('%', havaAlaniAd, '%');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `yolcuYasyAnalizi` ()   BEGIN
    SELECT 
        CASE 
           WHEN dogum_tarihi IS NULL THEN 'Bilinmiyor'
            WHEN TIMESTAMPDIFF(YEAR, dogum_tarihi, CURDATE()) < 18 THEN 'Çocuk'
            WHEN TIMESTAMPDIFF(YEAR, dogum_tarihi, CURDATE()) BETWEEN 18 AND 60 THEN 'Yetişkin'
            ELSE 'Yaşlı'
        END AS yas_grubu,
        COUNT(*) AS yolcu_sayisi
    FROM kullanicilar
    GROUP BY yas_grubu;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `biletler`
--

CREATE TABLE `biletler` (
  `bilet_id` int(11) NOT NULL,
  `rezervasyon_id` int(11) DEFAULT NULL,
  `koltuk_id` int(11) DEFAULT NULL,
  `bilet_no` varchar(50) DEFAULT NULL,
  `kesim_tarihi` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `biletler`
--

INSERT INTO `biletler` (`bilet_id`, `rezervasyon_id`, `koltuk_id`, `bilet_no`, `kesim_tarihi`) VALUES
(3, 3, 4, 'TK-34', '2025-12-19 16:00:01'),
(5, 5, 28, 'TK-528', '2025-12-19 16:40:58'),
(6, 6, 13, 'TK-613', '2025-12-19 16:50:05'),
(7, 7, 29, 'TK-729', '2025-12-19 16:56:21'),
(9, 9, 9, 'TK-99', '2025-12-19 18:30:28'),
(10, 10, 25, 'TK-1025', '2025-12-23 20:42:04'),
(11, 11, 1, 'TK-111', '2025-12-30 08:57:13');

--
-- Tetikleyiciler `biletler`
--
DELIMITER $$
CREATE TRIGGER `trg_BiletIptali` AFTER DELETE ON `biletler` FOR EACH ROW BEGIN
    UPDATE rezervasyonlar 
    SET durum = 'İptal Edildi'
    WHERE rezervasyon_id = OLD.rezervasyon_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `havaalanlari`
--

CREATE TABLE `havaalanlari` (
  `havaalani_id` int(11) NOT NULL,
  `havaalani_kod` varchar(3) NOT NULL,
  `havaalani_ad` varchar(50) NOT NULL,
  `havaalani_ulke` varchar(50) NOT NULL,
  `havaalani_sehir` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `havaalanlari`
--

INSERT INTO `havaalanlari` (`havaalani_id`, `havaalani_kod`, `havaalani_ad`, `havaalani_ulke`, `havaalani_sehir`) VALUES
(1, 'IST', 'İstanbul Havalimanı', 'Türkiye', 'İstanbul'),
(2, 'ADB', 'Adnan Menderes Havalimanı', 'Türkiye', 'İzmir'),
(3, 'ESB', 'Esenboğa Havalimanı', 'Türkiye', 'Ankara'),
(4, 'AYT', 'Antalya Havalimanı', 'Türkiye', 'Antalya'),
(5, 'JFK', 'John F. Kennedy Int. Airport', 'ABD', 'New York'),
(6, 'LHR', 'London Heathrow Airport', 'İngiltere', 'Londra'),
(7, 'SAW', 'İstanbul Sabiha Gökçen Havalimanı', 'Türkiye', 'İstanbul'),
(8, 'TZX', 'Trabzon Havalimanı', 'Türkiye', 'Trabzon'),
(9, 'DLM', 'Muğla Dalaman Havalimanı', 'Türkiye', 'Muğla'),
(10, 'BJV', 'Muğla Milas-Bodrum Havalimanı', 'Türkiye', 'Muğla'),
(11, 'ADA', 'Adana Şakirpaşa Havalimanı', 'Türkiye', 'Adana'),
(12, 'GZT', 'Gaziantep Havalimanı', 'Türkiye', 'Gaziantep'),
(13, 'ASR', 'Kayseri Havalimanı', 'Türkiye', 'Kayseri'),
(14, 'HTY', 'Hatay Havalimanı', 'Türkiye', 'Hatay'),
(15, 'SZF', 'Samsun Çarşamba Havalimanı', 'Türkiye', 'Samsun'),
(16, 'XHQ', 'Denizli Çardak Havalimanı', 'Türkiye', 'Denizli'),
(17, 'MLX', 'Malatya Erhaç Havalimanı', 'Türkiye', 'Malatya'),
(18, 'DIY', 'Diyarbakır Havalimanı', 'Türkiye', 'Diyarbakır'),
(19, 'VAS', 'Sivas Nuri Demirağ Havalimanı', 'Türkiye', 'Sivas'),
(20, 'EZS', 'Elazığ Havalimanı', 'Türkiye', 'Elazığ'),
(43, 'CDG', 'Charles de Gaulle Havalimanı', 'Fransa', 'Paris'),
(44, 'BER', 'Berlin Brandenburg Havalimanı', 'Almanya', 'Berlin'),
(45, 'KYA', 'Konya Havalimanı', 'Türkiye', 'Konya'),
(46, 'VAN', 'Van Ferit Melen Havalimanı', 'Türkiye', 'Van'),
(47, 'DXB', 'Dubai International Airport', 'BAE', 'Dubai');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `koltuklar`
--

CREATE TABLE `koltuklar` (
  `koltuk_id` int(11) NOT NULL,
  `ucak_id` int(11) DEFAULT NULL,
  `koltuk_no` varchar(5) DEFAULT NULL,
  `sinif` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `koltuklar`
--

INSERT INTO `koltuklar` (`koltuk_id`, `ucak_id`, `koltuk_no`, `sinif`) VALUES
(1, 1, '1A', 'Business'),
(2, 1, '1B', 'Business'),
(3, 1, '10F', 'Ekonomi'),
(4, 1, '12A', 'Ekonomi'),
(5, 2, '1A', 'Business'),
(6, 2, '5C', 'Ekonomi'),
(7, 2, '15D', 'Ekonomi'),
(8, 2, '20A', 'Ekonomi'),
(9, 3, '1A', 'First Class'),
(10, 3, '2A', 'First Class'),
(11, 3, '10B', 'Business'),
(12, 3, '40C', 'Ekonomi'),
(13, 1, '1A', 'Business'),
(14, 1, '1B', 'Business'),
(15, 1, '10A', 'Ekonomi'),
(16, 1, '10B', 'Ekonomi'),
(17, 2, '1A', 'Business'),
(18, 2, '5C', 'Ekonomi'),
(19, 2, '15D', 'Ekonomi'),
(20, 3, '1A', 'First Class'),
(21, 3, '10B', 'Business'),
(22, 3, '40C', 'Ekonomi'),
(23, 1, '1A', 'Business'),
(24, 1, '1B', 'Business'),
(25, 1, '10A', 'Ekonomi'),
(26, 1, '10B', 'Ekonomi'),
(27, 2, '1A', 'Business'),
(28, 2, '5C', 'Ekonomi'),
(29, 2, '15D', 'Ekonomi'),
(30, 3, '1A', 'First Class'),
(31, 3, '10B', 'Business'),
(32, 3, '40C', 'Ekonomi'),
(33, 4, '1A', 'Business'),
(34, 4, '1K', 'Business'),
(35, 4, '2A', 'Business'),
(36, 4, '2K', 'Business'),
(37, 4, '10A', 'Ekonomi'),
(38, 4, '10B', 'Ekonomi'),
(39, 4, '10C', 'Ekonomi'),
(40, 5, '1A', 'First Class'),
(41, 5, '10F', 'Business'),
(42, 5, '20A', 'Ekonomi'),
(43, 5, '20B', 'Ekonomi'),
(44, 5, '20C', 'Ekonomi');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `kullanicilar`
--

CREATE TABLE `kullanicilar` (
  `kullanici_id` int(11) NOT NULL,
  `kullanici_adi` varchar(20) NOT NULL,
  `kullanici_soyad` varchar(20) NOT NULL,
  `kullanici_sifre` varchar(100) NOT NULL,
  `kullanici_telefon` varchar(10) DEFAULT NULL,
  `kullanici_mail` varchar(50) NOT NULL,
  `dogum_tarihi` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `kullanicilar`
--

INSERT INTO `kullanicilar` (`kullanici_id`, `kullanici_adi`, `kullanici_soyad`, `kullanici_sifre`, `kullanici_telefon`, `kullanici_mail`, `dogum_tarihi`) VALUES
(2, 'Deneme Ad', 'DENEME SOYAD', 'DENEM ŞİFRE', '1234567890', 'DENEME MAIL', '0000-00-00'),
(3, 'AYKAN', 'KARA', '123', '0532123456', 'AYKANMAIL', '2006-01-01'),
(4, 'admin', '1', '12', '', 'admin', '1999-01-01'),
(5, 'deneme1', 'deneme1', '1', '1234524212', 'd123', '2000-01-01'),
(6, 'a', 'a', '1', NULL, 'a', NULL),
(8, 'kSorgu1', 'kSorgu1', 'kSorgu1', NULL, 'kSorgu1', NULL),
(10, 'Burak', 'Evrentug', '123456', NULL, 'burak@example.com', NULL);

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `odeme`
--

CREATE TABLE `odeme` (
  `odeme_id` int(11) NOT NULL,
  `rezervasyon_id` int(11) DEFAULT NULL,
  `tutar` decimal(10,2) DEFAULT NULL,
  `odeme_tarihi` datetime DEFAULT NULL,
  `odeme_tipi` varchar(20) DEFAULT NULL,
  `durum` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `odeme`
--

INSERT INTO `odeme` (`odeme_id`, `rezervasyon_id`, `tutar`, `odeme_tarihi`, `odeme_tipi`, `durum`) VALUES
(1, 5, 950.00, '2025-12-19 16:40:58', 'Kart', 'Başarılı'),
(2, 6, 4464.00, '2025-12-19 16:50:05', 'Kart', 'Başarılı'),
(3, 7, 1471.00, '2025-12-19 16:56:21', 'Kart', 'Başarılı'),
(5, 9, 3865.00, '2025-12-19 18:30:28', 'Kart', 'Başarılı'),
(6, 10, 2986.00, '2025-12-23 20:42:04', 'Kart', 'Başarılı'),
(7, 11, 2684.00, '2025-12-30 08:57:13', 'Kart', 'Başarılı');

--
-- Tetikleyiciler `odeme`
--
DELIMITER $$
CREATE TRIGGER `trg_OdemeSonrasiOnay` AFTER INSERT ON `odeme` FOR EACH ROW BEGIN
    IF NEW.durum = 'Başarılı' THEN
        UPDATE rezervasyonlar 
        SET durum = 'Onaylandı' 
        WHERE rezervasyon_id = NEW.rezervasyon_id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `rezervasyonlar`
--

CREATE TABLE `rezervasyonlar` (
  `rezervasyon_id` int(11) NOT NULL,
  `kullanici_id` int(11) DEFAULT NULL,
  `ucus_id` int(11) DEFAULT NULL,
  `tarih` datetime DEFAULT NULL,
  `durum` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `rezervasyonlar`
--

INSERT INTO `rezervasyonlar` (`rezervasyon_id`, `kullanici_id`, `ucus_id`, `tarih`, `durum`) VALUES
(2, 3, 2, '2025-12-19 15:56:23', 'İptal Edildi'),
(3, 3, 4, '2025-12-19 16:00:01', 'Uçuş İptal Edildi'),
(4, 3, 1, '2025-12-19 16:19:06', 'Uçuş İptal Edildi'),
(5, 4, 2, '2025-12-19 16:40:58', 'Onaylandı'),
(6, 4, 35, '2025-12-19 16:50:05', 'Onaylandı'),
(7, 4, 68, '2025-12-19 16:56:21', 'Onaylandı'),
(9, 5, 97, '2025-12-19 18:30:28', 'Onaylandı'),
(10, 4, 70, '2025-12-23 20:42:04', 'Uçuş İptal Edildi'),
(11, 10, 7, '2025-12-30 08:57:13', 'Onaylandı');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `terminalbilgileri`
--

CREATE TABLE `terminalbilgileri` (
  `terminal_id` int(11) NOT NULL,
  `havaalani_id` int(11) DEFAULT NULL,
  `terminal_adi` varchar(50) DEFAULT NULL,
  `yurt_ici_mi` tinyint(1) DEFAULT NULL,
  `kapasite` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `terminalbilgileri`
--

INSERT INTO `terminalbilgileri` (`terminal_id`, `havaalani_id`, `terminal_adi`, `yurt_ici_mi`, `kapasite`) VALUES
(1, 1, 'Terminal A (Dış Hatlar)', 0, 5000),
(2, 1, 'Terminal B (İç Hatlar)', 1, 3000),
(3, 2, 'Ana Terminal', 1, 4000),
(4, 43, 'Terminal 2E', 0, 12000),
(5, 45, 'İç Hatlar Terminali', 1, 2500),
(6, 47, 'Terminal 3 (Emirates)', 0, 15000),
(7, 3, 'Esenboğa İç-Dış Hatlar', 1, 15000),
(8, 4, 'Antalya T1 ve T2', 0, 35000),
(9, 5, 'Terminal 4 (Int)', 0, 40000),
(10, 6, 'Heathrow T5', 0, 45000),
(11, 7, 'Sabiha Gökçen Ana Terminal', 1, 25000),
(12, 8, 'Trabzon Dış Hatlar', 0, 6000),
(13, 9, 'Dalaman Dış Hatlar', 0, 12000),
(14, 10, 'Milas-Bodrum Ana Terminal', 1, 10000),
(15, 11, 'Şakirpaşa İç Hatlar', 1, 5500),
(16, 12, 'Gaziantep Ana Terminal', 1, 6000),
(17, 13, 'Kayseri Erkilet', 1, 4500),
(18, 14, 'Hatay Terminali', 1, 3000),
(19, 15, 'Çarşamba Terminali', 1, 3500),
(20, 16, 'Çardak Terminali', 1, 2000),
(21, 17, 'Erhaç Terminali', 1, 2500),
(22, 18, 'Diyarbakır Yeni Terminal', 1, 5000),
(23, 19, 'Nuri Demirağ Terminali', 1, 3000),
(24, 20, 'Elazığ Terminali', 1, 2800),
(25, 44, 'Berlin Brandenburg T1', 0, 28000),
(26, 46, 'Van Ferit Melen', 1, 3200);

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `ucaklar`
--

CREATE TABLE `ucaklar` (
  `ucak_id` int(11) NOT NULL,
  `model` varchar(50) NOT NULL,
  `seri_no` varchar(10) NOT NULL,
  `koltuk_sayisi` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `ucaklar`
--

INSERT INTO `ucaklar` (`ucak_id`, `model`, `seri_no`, `koltuk_sayisi`) VALUES
(1, 'Boeing 737-800', 'B737-TK1', 180),
(2, 'Airbus A320', 'A320-PC1', 150),
(3, 'Boeing 777-300ER', 'B777-THY', 350),
(4, 'Boeing 787-9 Dreamliner', 'B787-TR9', 290),
(5, 'Airbus A350-900', 'A350-LH1', 325);

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `ucuslar`
--

CREATE TABLE `ucuslar` (
  `ucus_id` int(11) NOT NULL,
  `ucak_id` int(11) DEFAULT NULL,
  `kalkis_havaalani_id` int(11) DEFAULT NULL,
  `varis_havaalani_id` int(11) DEFAULT NULL,
  `tarih` date NOT NULL,
  `kalkis_saati` datetime DEFAULT NULL,
  `varis_saati` datetime DEFAULT NULL,
  `fiyat` decimal(10,2) DEFAULT NULL,
  `durum` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `ucuslar`
--

INSERT INTO `ucuslar` (`ucus_id`, `ucak_id`, `kalkis_havaalani_id`, `varis_havaalani_id`, `tarih`, `kalkis_saati`, `varis_saati`, `fiyat`, `durum`) VALUES
(1, 1, 1, 2, '2025-12-20', '2025-12-20 14:00:00', '2025-12-20 15:00:00', 1650.00, 'İptal'),
(2, 2, 3, 4, '2025-12-21', '2025-12-21 10:30:00', '2025-12-21 11:45:00', 950.00, 'Aktif'),
(3, 3, 1, 6, '2025-12-22', '2025-12-22 08:00:00', '2025-12-22 12:30:00', 4500.00, 'Aktif'),
(4, 1, 2, 5, '2025-12-23', '2025-12-23 22:15:00', '2025-12-24 09:30:00', 12200.00, 'İptal'),
(5, 3, 2, 11, '2025-12-27', '2025-12-20 03:19:06', '2025-12-20 09:19:06', 3996.00, 'Aktif'),
(6, 1, 13, 11, '2026-01-10', '2025-12-20 08:19:06', '2025-12-19 20:19:06', 2724.00, 'Aktif'),
(7, 1, 4, 11, '2025-12-22', '2025-12-19 20:19:06', '2025-12-20 08:19:06', 2684.00, 'Aktif'),
(8, 2, 10, 11, '2025-12-28', '2025-12-20 14:19:06', '2025-12-20 12:19:06', 1220.00, 'Aktif'),
(9, 1, 18, 11, '2026-01-01', '2025-12-20 12:19:06', '2025-12-20 14:19:06', 3692.00, 'Aktif'),
(10, 1, 9, 11, '2025-12-22', '2025-12-20 00:19:06', '2025-12-20 04:19:06', 1169.00, 'Aktif'),
(11, 1, 3, 11, '2026-01-07', '2025-12-20 07:19:06', '2025-12-20 01:19:06', 2954.00, 'Aktif'),
(12, 3, 20, 11, '2026-01-01', '2025-12-20 12:19:06', '2025-12-20 15:19:06', 4672.00, 'Aktif'),
(13, 1, 12, 11, '2026-01-08', '2025-12-19 16:19:06', '2025-12-19 19:19:06', 1624.00, 'Aktif'),
(14, 3, 14, 11, '2026-01-12', '2025-12-20 00:19:06', '2025-12-20 03:19:06', 4430.00, 'Aktif'),
(15, 2, 1, 11, '2026-01-17', '2025-12-20 14:19:06', '2025-12-20 11:19:06', 3838.00, 'Aktif'),
(16, 2, 5, 11, '2026-01-17', '2025-12-20 14:19:06', '2025-12-20 11:19:06', 4529.00, 'Aktif'),
(17, 2, 6, 11, '2025-12-27', '2025-12-19 20:19:06', '2025-12-19 19:19:06', 3554.00, 'Aktif'),
(18, 1, 17, 11, '2026-01-01', '2025-12-20 00:19:06', '2025-12-20 05:19:06', 1901.00, 'Aktif'),
(19, 3, 7, 11, '2026-01-15', '2025-12-20 08:19:06', '2025-12-20 11:19:06', 3414.00, 'Aktif'),
(20, 1, 15, 11, '2025-12-24', '2025-12-20 11:19:06', '2025-12-20 07:19:06', 2315.00, 'Aktif'),
(21, 1, 8, 11, '2026-01-11', '2025-12-20 01:19:06', '2025-12-20 08:19:06', 4022.00, 'Aktif'),
(22, 1, 19, 11, '2026-01-11', '2025-12-19 19:19:06', '2025-12-20 02:19:06', 2105.00, 'Aktif'),
(23, 2, 16, 11, '2025-12-20', '2025-12-20 01:19:06', '2025-12-20 12:19:06', 3854.00, 'Aktif'),
(24, 2, 11, 2, '2025-12-22', '2025-12-19 17:19:06', '2025-12-19 19:19:06', 1441.00, 'Aktif'),
(25, 2, 13, 2, '2025-12-29', '2025-12-19 17:19:06', '2025-12-19 22:19:06', 4068.00, 'Aktif'),
(26, 2, 4, 2, '2025-12-21', '2025-12-20 14:19:06', '2025-12-20 04:19:06', 2189.00, 'Aktif'),
(27, 2, 10, 2, '2025-12-22', '2025-12-19 21:19:06', '2025-12-20 16:19:06', 4240.00, 'Aktif'),
(28, 2, 18, 2, '2025-12-22', '2025-12-20 13:19:06', '2025-12-19 22:19:06', 1416.00, 'Aktif'),
(29, 1, 9, 2, '2026-01-14', '2025-12-20 06:19:06', '2025-12-20 04:19:06', 2404.00, 'Aktif'),
(30, 2, 3, 2, '2025-12-19', '2025-12-19 19:19:06', '2025-12-20 10:19:06', 983.00, 'Aktif'),
(31, 1, 20, 2, '2026-01-03', '2025-12-19 21:19:06', '2025-12-20 08:19:06', 2150.00, 'Aktif'),
(32, 3, 12, 2, '2025-12-27', '2025-12-20 10:19:06', '2025-12-19 19:19:06', 4770.00, 'Aktif'),
(33, 3, 14, 2, '2026-01-14', '2025-12-19 19:19:06', '2025-12-19 21:19:06', 1502.00, 'Aktif'),
(34, 2, 1, 2, '2026-01-13', '2025-12-20 10:19:06', '2025-12-20 03:19:06', 3605.00, 'Aktif'),
(35, 1, 5, 2, '2025-12-26', '2025-12-20 01:19:06', '2025-12-19 23:19:06', 4464.00, 'Aktif'),
(36, 3, 6, 2, '2026-01-16', '2025-12-20 12:19:06', '2025-12-20 06:19:06', 890.00, 'Aktif'),
(37, 2, 17, 2, '2026-01-07', '2025-12-20 05:19:06', '2025-12-20 14:19:06', 3443.00, 'Aktif'),
(38, 3, 7, 2, '2026-01-05', '2025-12-20 09:19:06', '2025-12-20 15:19:06', 2243.00, 'Aktif'),
(39, 1, 15, 2, '2025-12-29', '2025-12-20 02:19:06', '2025-12-19 23:19:06', 3955.00, 'Aktif'),
(68, 2, 2, 11, '2026-01-15', '2025-12-19 18:20:20', '2025-12-20 10:20:20', 1471.00, 'Aktif'),
(69, 3, 13, 11, '2025-12-30', '2025-12-20 07:20:20', '2025-12-20 17:20:20', 830.00, 'Aktif'),
(70, 1, 4, 11, '2026-01-01', '2025-12-20 15:20:20', '2025-12-20 05:20:20', 2986.00, 'İptal'),
(71, 1, 10, 11, '2026-01-08', '2025-12-20 05:20:20', '2025-12-20 14:20:20', 2945.00, 'Aktif'),
(72, 1, 18, 11, '2025-12-19', '2025-12-20 10:20:20', '2025-12-20 10:20:20', 1618.00, 'Aktif'),
(73, 3, 9, 11, '2025-12-21', '2025-12-20 06:20:20', '2025-12-20 14:20:20', 2283.00, 'Aktif'),
(74, 1, 3, 11, '2026-01-01', '2025-12-19 22:20:20', '2025-12-20 17:20:20', 1532.00, 'Aktif'),
(75, 3, 20, 11, '2025-12-22', '2025-12-20 11:20:20', '2025-12-20 09:20:20', 4295.00, 'Aktif'),
(76, 2, 12, 11, '2025-12-29', '2025-12-20 07:20:20', '2025-12-19 19:20:20', 2221.00, 'Aktif'),
(77, 2, 14, 11, '2025-12-22', '2025-12-20 06:20:20', '2025-12-20 12:20:20', 4549.00, 'Aktif'),
(78, 2, 1, 11, '2025-12-27', '2025-12-19 20:20:20', '2025-12-19 21:20:20', 1429.00, 'Aktif'),
(79, 1, 5, 11, '2025-12-22', '2025-12-20 07:20:20', '2025-12-20 13:20:20', 1653.00, 'Aktif'),
(80, 2, 6, 11, '2025-12-28', '2025-12-20 13:20:20', '2025-12-20 03:20:20', 2347.00, 'Aktif'),
(81, 3, 17, 11, '2025-12-31', '2025-12-20 15:20:20', '2025-12-20 07:20:20', 4180.00, 'Aktif'),
(82, 2, 7, 11, '2025-12-30', '2025-12-19 20:20:20', '2025-12-20 13:20:20', 2634.00, 'Aktif'),
(83, 3, 15, 11, '2026-01-16', '2025-12-19 19:20:20', '2025-12-20 16:20:20', 1822.00, 'Aktif'),
(84, 2, 8, 11, '2025-12-31', '2025-12-20 10:20:20', '2025-12-20 07:20:20', 2963.00, 'Aktif'),
(85, 1, 19, 11, '2025-12-31', '2025-12-19 18:20:20', '2025-12-19 22:20:20', 3474.00, 'Aktif'),
(86, 3, 16, 11, '2026-01-14', '2025-12-19 17:20:20', '2025-12-20 08:20:20', 4473.00, 'Aktif'),
(87, 3, 11, 2, '2025-12-19', '2025-12-20 11:20:20', '2025-12-19 20:20:20', 4609.00, 'Aktif'),
(88, 2, 13, 2, '2026-01-07', '2025-12-20 08:20:20', '2025-12-20 06:20:20', 2953.00, 'Aktif'),
(89, 1, 4, 2, '2025-12-20', '2025-12-20 13:20:20', '2025-12-19 23:20:20', 3160.00, 'Aktif'),
(90, 1, 10, 2, '2025-12-26', '2025-12-20 07:20:20', '2025-12-20 06:20:20', 3134.00, 'Aktif'),
(91, 2, 18, 2, '2025-12-25', '2025-12-20 11:20:20', '2025-12-20 07:20:20', 1989.00, 'Aktif'),
(92, 3, 9, 2, '2025-12-23', '2025-12-20 00:20:20', '2025-12-20 02:20:20', 3460.00, 'Aktif'),
(93, 1, 3, 2, '2025-12-29', '2025-12-20 13:20:20', '2025-12-20 05:20:20', 3378.00, 'Aktif'),
(94, 3, 20, 2, '2025-12-24', '2025-12-20 01:20:20', '2025-12-20 05:20:20', 1619.00, 'Aktif'),
(95, 2, 12, 2, '2025-12-27', '2025-12-20 09:20:20', '2025-12-20 12:20:20', 3464.00, 'Aktif'),
(96, 1, 14, 2, '2025-12-21', '2025-12-19 23:20:20', '2025-12-20 02:20:20', 4009.00, 'Aktif'),
(97, 3, 1, 2, '2026-01-01', '2025-12-19 22:20:20', '2025-12-19 21:20:20', 3865.00, 'Aktif'),
(98, 2, 5, 2, '2026-01-16', '2025-12-20 02:20:20', '2025-12-20 02:20:20', 2723.00, 'Aktif'),
(99, 1, 6, 2, '2025-12-21', '2025-12-20 04:20:20', '2025-12-20 00:20:20', 4367.00, 'Aktif'),
(100, 2, 17, 2, '2025-12-30', '2025-12-19 17:20:20', '2025-12-19 21:20:20', 2967.00, 'Aktif'),
(101, 1, 7, 2, '2026-01-12', '2025-12-19 19:20:20', '2025-12-20 03:20:20', 2452.00, 'Aktif'),
(102, 3, 15, 2, '2026-01-01', '2025-12-20 00:20:20', '2025-12-20 07:20:20', 3573.00, 'Aktif'),
(146, 1, 1, 43, '2026-02-14', '2026-02-14 08:00:00', '2026-02-14 11:30:00', 4500.00, 'Aktif'),
(147, 1, 43, 1, '2026-02-14', '2026-02-14 13:00:00', '2026-02-14 17:30:00', 4200.00, 'Aktif'),
(148, 2, 1, 45, '2026-02-15', '2026-02-15 09:00:00', '2026-02-15 10:15:00', 1200.00, 'Aktif'),
(149, 2, 45, 1, '2026-02-15', '2026-02-15 11:00:00', '2026-02-15 12:15:00', 1150.00, 'Aktif'),
(150, 1, 2, 44, '2026-03-01', '2026-03-01 14:00:00', '2026-03-01 17:00:00', 3800.00, 'Aktif'),
(151, 2, 3, 46, '2026-03-05', '2026-03-05 10:30:00', '2026-03-05 12:00:00', 1450.00, 'Aktif'),
(152, 4, 1, 47, '2026-04-10', '2026-04-10 20:00:00', '2026-04-11 01:30:00', 8500.00, 'Aktif'),
(153, 1, 4, 6, '2026-06-01', '2026-06-01 06:00:00', '2026-06-01 10:00:00', 5200.00, 'Aktif'),
(154, 2, 8, 1, '2026-02-20', '2026-02-20 05:45:00', '2026-02-20 07:30:00', 1600.00, 'Aktif'),
(155, 2, 9, 7, '2026-05-15', '2026-05-15 15:00:00', '2026-05-15 16:15:00', 1350.00, 'Aktif'),
(156, 5, 5, 1, '2026-03-20', '2026-03-20 18:00:00', '2026-03-21 11:00:00', 15000.00, 'Aktif'),
(157, 2, 11, 2, '2026-02-25', '2026-02-25 12:00:00', '2026-02-25 13:30:00', 1100.00, 'Aktif'),
(158, 2, 12, 3, '2026-02-26', '2026-02-26 08:30:00', '2026-02-26 09:45:00', 950.00, 'Aktif'),
(159, 1, 1, 13, '2026-01-20', '2026-01-20 07:00:00', '2026-01-20 08:20:00', 2100.00, 'Aktif'),
(160, 2, 19, 1, '2026-01-22', '2026-01-22 16:00:00', '2026-01-22 17:30:00', 1250.00, 'Aktif');

--
-- Tetikleyiciler `ucuslar`
--
DELIMITER $$
CREATE TRIGGER `trg_UcusIptalRezervasyonGuncelle` AFTER UPDATE ON `ucuslar` FOR EACH ROW BEGIN
   
    IF NEW.durum = 'İptal' AND OLD.durum != 'İptal' THEN
        
        UPDATE rezervasyonlar
        SET durum = 'Uçuş İptal Edildi'
        WHERE ucus_id = OLD.ucus_id;
        
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `yolcu_bilgileri`
--

CREATE TABLE `yolcu_bilgileri` (
  `yolcu_id` int(11) NOT NULL,
  `bilet_id` int(11) DEFAULT NULL,
  `ad` varchar(20) DEFAULT NULL,
  `soyad` varchar(20) DEFAULT NULL,
  `dogum_tarihi` date DEFAULT NULL,
  `tc_pasaport` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `yolcu_bilgileri`
--

INSERT INTO `yolcu_bilgileri` (`yolcu_id`, `bilet_id`, `ad`, `soyad`, `dogum_tarihi`, `tc_pasaport`) VALUES
(1, 6, 'Admin', '1', '1999-01-01', '12345678909'),
(2, 7, 'admin', '1', '1999-01-01', '12345678900'),
(4, 9, 'a', 'a', NULL, '123214143'),
(5, 10, 'ADMIN_DENEME', 'DENEME', NULL, '1234567854'),
(6, 11, 'burak', 'evrentuğ', NULL, '12345678912');

--
-- Dökümü yapılmış tablolar için indeksler
--

--
-- Tablo için indeksler `biletler`
--
ALTER TABLE `biletler`
  ADD PRIMARY KEY (`bilet_id`),
  ADD UNIQUE KEY `bilet_no` (`bilet_no`),
  ADD KEY `fk_biletler_rezervasyon` (`rezervasyon_id`),
  ADD KEY `fk_biletler_koltuklar` (`koltuk_id`);

--
-- Tablo için indeksler `havaalanlari`
--
ALTER TABLE `havaalanlari`
  ADD PRIMARY KEY (`havaalani_id`),
  ADD UNIQUE KEY `havaalani_kod` (`havaalani_kod`),
  ADD UNIQUE KEY `havaalani_ad` (`havaalani_ad`);

--
-- Tablo için indeksler `koltuklar`
--
ALTER TABLE `koltuklar`
  ADD PRIMARY KEY (`koltuk_id`),
  ADD KEY `FK_UCAK_KOLTUK` (`ucak_id`);

--
-- Tablo için indeksler `kullanicilar`
--
ALTER TABLE `kullanicilar`
  ADD PRIMARY KEY (`kullanici_id`),
  ADD UNIQUE KEY `kullanici_mail` (`kullanici_mail`),
  ADD UNIQUE KEY `kullanici_telefon` (`kullanici_telefon`);

--
-- Tablo için indeksler `odeme`
--
ALTER TABLE `odeme`
  ADD PRIMARY KEY (`odeme_id`),
  ADD KEY `fk_odeme_rezervasyon` (`rezervasyon_id`);

--
-- Tablo için indeksler `rezervasyonlar`
--
ALTER TABLE `rezervasyonlar`
  ADD PRIMARY KEY (`rezervasyon_id`),
  ADD KEY `fk_kullanici_rezervasyon` (`kullanici_id`),
  ADD KEY `fk_ucuslar_rezarvasyon` (`ucus_id`);

--
-- Tablo için indeksler `terminalbilgileri`
--
ALTER TABLE `terminalbilgileri`
  ADD PRIMARY KEY (`terminal_id`),
  ADD KEY `fk_terminal_havaalani` (`havaalani_id`);

--
-- Tablo için indeksler `ucaklar`
--
ALTER TABLE `ucaklar`
  ADD PRIMARY KEY (`ucak_id`);

--
-- Tablo için indeksler `ucuslar`
--
ALTER TABLE `ucuslar`
  ADD PRIMARY KEY (`ucus_id`),
  ADD KEY `FK_UCAKLAR_UCUSLAR` (`ucak_id`),
  ADD KEY `FK_KALKIS_HAVALIMANI` (`kalkis_havaalani_id`),
  ADD KEY `FK_VARIS_HAVALIMANI` (`varis_havaalani_id`);

--
-- Tablo için indeksler `yolcu_bilgileri`
--
ALTER TABLE `yolcu_bilgileri`
  ADD PRIMARY KEY (`yolcu_id`),
  ADD KEY `fk_yolcuBilgileri_bilet` (`bilet_id`);

--
-- Dökümü yapılmış tablolar için AUTO_INCREMENT değeri
--

--
-- Tablo için AUTO_INCREMENT değeri `biletler`
--
ALTER TABLE `biletler`
  MODIFY `bilet_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- Tablo için AUTO_INCREMENT değeri `havaalanlari`
--
ALTER TABLE `havaalanlari`
  MODIFY `havaalani_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=48;

--
-- Tablo için AUTO_INCREMENT değeri `koltuklar`
--
ALTER TABLE `koltuklar`
  MODIFY `koltuk_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- Tablo için AUTO_INCREMENT değeri `kullanicilar`
--
ALTER TABLE `kullanicilar`
  MODIFY `kullanici_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- Tablo için AUTO_INCREMENT değeri `odeme`
--
ALTER TABLE `odeme`
  MODIFY `odeme_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- Tablo için AUTO_INCREMENT değeri `rezervasyonlar`
--
ALTER TABLE `rezervasyonlar`
  MODIFY `rezervasyon_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- Tablo için AUTO_INCREMENT değeri `terminalbilgileri`
--
ALTER TABLE `terminalbilgileri`
  MODIFY `terminal_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- Tablo için AUTO_INCREMENT değeri `ucaklar`
--
ALTER TABLE `ucaklar`
  MODIFY `ucak_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Tablo için AUTO_INCREMENT değeri `ucuslar`
--
ALTER TABLE `ucuslar`
  MODIFY `ucus_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=161;

--
-- Tablo için AUTO_INCREMENT değeri `yolcu_bilgileri`
--
ALTER TABLE `yolcu_bilgileri`
  MODIFY `yolcu_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Dökümü yapılmış tablolar için kısıtlamalar
--

--
-- Tablo kısıtlamaları `biletler`
--
ALTER TABLE `biletler`
  ADD CONSTRAINT `fk_biletler_koltuklar` FOREIGN KEY (`koltuk_id`) REFERENCES `koltuklar` (`koltuk_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_biletler_rezervasyon` FOREIGN KEY (`rezervasyon_id`) REFERENCES `rezervasyonlar` (`rezervasyon_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `koltuklar`
--
ALTER TABLE `koltuklar`
  ADD CONSTRAINT `FK_UCAK_KOLTUK` FOREIGN KEY (`ucak_id`) REFERENCES `ucaklar` (`ucak_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `odeme`
--
ALTER TABLE `odeme`
  ADD CONSTRAINT `fk_odeme_rezervasyon` FOREIGN KEY (`rezervasyon_id`) REFERENCES `rezervasyonlar` (`rezervasyon_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `rezervasyonlar`
--
ALTER TABLE `rezervasyonlar`
  ADD CONSTRAINT `fk_kullanici_rezervasyon` FOREIGN KEY (`kullanici_id`) REFERENCES `kullanicilar` (`kullanici_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucuslar_rezarvasyon` FOREIGN KEY (`ucus_id`) REFERENCES `ucuslar` (`ucus_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `terminalbilgileri`
--
ALTER TABLE `terminalbilgileri`
  ADD CONSTRAINT `fk_terminal_havaalani` FOREIGN KEY (`havaalani_id`) REFERENCES `havaalanlari` (`havaalani_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `ucuslar`
--
ALTER TABLE `ucuslar`
  ADD CONSTRAINT `FK_KALKIS_HAVALIMANI` FOREIGN KEY (`kalkis_havaalani_id`) REFERENCES `havaalanlari` (`havaalani_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `FK_UCAKLAR_UCUSLAR` FOREIGN KEY (`ucak_id`) REFERENCES `ucaklar` (`ucak_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `FK_VARIS_HAVALIMANI` FOREIGN KEY (`varis_havaalani_id`) REFERENCES `havaalanlari` (`havaalani_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `yolcu_bilgileri`
--
ALTER TABLE `yolcu_bilgileri`
  ADD CONSTRAINT `fk_yolcuBilgileri_bilet` FOREIGN KEY (`bilet_id`) REFERENCES `biletler` (`bilet_id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
