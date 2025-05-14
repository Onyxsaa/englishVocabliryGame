const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();

// --- Veritabanı Şeması ---
const KelimeDetaySchema = new mongoose.Schema({
  benzerler: [String],
  cumle: { tam: String, eksik: String }
}, { _id: false });

const HardSchema = new mongoose.Schema({
  words: { type: Map, of: KelimeDetaySchema }
}, { collection: 'hard' });

// --- MODEL TANIMI ---
const HardModel = mongoose.models.HardModel || mongoose.model('HardModel', HardSchema);

// --- Router Tanımı ---
router.get('/', async (req, res) => {
  try {
    const document = await HardModel.findOne().select('words');

    if (!document || !document.words || document.words.size === 0) {
      console.log("Veritabanında 'hard' koleksiyonunda 'words' verisi bulunamadı.");
      return res.render('hard', {
        sozcukler: {},
        error: "Kelime verisi bulunamadı."
      });
    }

    const wordsData = document.words;
    const wordsObject = Object.fromEntries(wordsData);

    res.render('hard', { sozcukler: wordsObject, error: null });

  } catch (err) {
    console.error("Veri çekme veya render sırasında hata:", err);
    res.render('hard', {
      sozcukler: {},
      error: "Sunucu hatası oluştu. Veriler yüklenemedi."
    });
  }
});

module.exports = router;
