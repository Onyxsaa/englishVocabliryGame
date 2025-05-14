const mongoose = require('mongoose');

const cumleSchema = new mongoose.Schema({
  tam: String,
  eksik: String
}, { _id: false });

const wordDetailSchema = new mongoose.Schema({
  benzerler: [String],
  cumle: cumleSchema
}, { _id: false });

const basitSchema = new mongoose.Schema({
  words: {
    type: Map,
    of: wordDetailSchema
  }
}, { collection: 'orta' });

module.exports = mongoose.model('Orta', basitSchema);
