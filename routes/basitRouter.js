// router.js (önceki kodla büyük ölçüde aynı)

const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();

// --- Veritabanı Bağlantısı (Öncekiyle aynı) ---


// --- Mongoose Şeması ve Modeli (Öncekiyle aynı) ---
const KelimeDetaySchema = new mongoose.Schema({
  benzerler: [String],
  cumle: { tam: String, eksik: String }
}, { _id: false });

const BasitSchema = new mongoose.Schema({
  words: { type: Map, of: KelimeDetaySchema }
}, { collection: 'basit' });

const BasitModel = mongoose.model('BasitModel', BasitSchema);

// --- Router Tanımı ---
router.get('/', async (req, res) => {
  try {
    const document = await BasitModel.findOne().select('words');

    if (!document || !document.words || document.words.size === 0) {
      console.log("Veritabanında 'basit' koleksiyonunda 'words' verisi bulunamadı.");
      // Hata mesajı veya boş veri ile render edilebilir.
      // EJS tarafında kontrol edilecek olsa da, burada da göndermemek daha iyi olabilir.
      return res.render('basit', {
          sozcukler: {}, // Boş obje gönder
          error: "Kelime verisi bulunamadı." // Opsiyonel hata mesajı
        });
    }

    const wordsData = document.words;
    const wordsObject = Object.fromEntries(wordsData); // Düz JS objesine çevir

    // 'basit.ejs' şablonunu render et ve tüm kelime objesini gönder.
    res.render('basit', { sozcukler: wordsObject, error: null }); // Hata yok

  } catch (err) {
    console.error("Veri çekme veya render sırasında hata:", err);
    res.render('basit', {
        sozcukler: {},
        error: "Sunucu hatası oluştu. Veriler yüklenemedi." // Hata mesajı gönder
    });
  }
});

module.exports = router;