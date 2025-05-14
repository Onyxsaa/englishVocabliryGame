const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();

// --- Veritabanı Şeması ---
const KelimeDetaySchema = new mongoose.Schema({
  benzerler: [String],
  cumle: { tam: String, eksik: String }
}, { _id: false });

const OrtaSchema = new mongoose.Schema({
  words: { type: Map, of: KelimeDetaySchema }
}, { collection: 'orta' });

// --- MODEL TANIMI ---
const OrtaModel = mongoose.models.OrtaModel || mongoose.model('OrtaModel', OrtaSchema);

// --- Router Tanımı ---
router.get('/', async (req, res) => {
  try {
    const document = await OrtaModel.findOne().select('words');

    if (!document || !document.words || document.words.size === 0) {
      console.log("Veritabanında 'orta' koleksiyonunda 'words' verisi bulunamadı.");
      return res.render('orta', {
        sozcukler: {},
        error: "Kelime verisi bulunamadı."
      });
    }

    const wordsData = document.words;
    const wordsObject = Object.fromEntries(wordsData);

    res.render('orta', { sozcukler: wordsObject, error: null });

  } catch (err) {
    console.error("Veri çekme veya render sırasında hata:", err);
    res.render('orta', {
      sozcukler: {},
      error: "Sunucu hatası oluştu. Veriler yüklenemedi."
    });
  }
});

module.exports = router;
