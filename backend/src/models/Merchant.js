const mongoose = require('mongoose');

const merchantSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    slug: { type: String, required: true, unique: true, trim: true, index: true },
    aliases: [{ type: String, trim: true, lowercase: true }],
    category: { type: String, required: true, trim: true, index: true },
  },
  { timestamps: true },
);

const Merchant = mongoose.model('Merchant', merchantSchema);

module.exports = { Merchant };
