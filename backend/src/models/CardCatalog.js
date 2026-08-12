const mongoose = require('mongoose');

const visualSchema = new mongoose.Schema(
  {
    backgroundColor: { type: String, default: '#1F2937' },
    textColor: { type: String, default: '#FFFFFF' },
    accentColor: { type: String, default: '#22C55E' },
    issuerLabel: { type: String, trim: true },
    brandLabel: { type: String, trim: true },
    logoMode: { type: String, enum: ['text', 'svg', 'url'], default: 'text' },
    logoValue: { type: String, default: '' },
  },
  { _id: false },
);

const recommendationRuleSchema = new mongoose.Schema(
  {
    merchant: { type: String, trim: true },
    category: { type: String, trim: true },
    rate: { type: Number, required: true },
    cap: { type: Number, default: null },
    label: { type: String, required: true, trim: true },
  },
  { _id: false },
);

const cardCatalogSchema = new mongoose.Schema(
  {
    issuer: { type: String, required: true, trim: true, index: true },
    name: { type: String, required: true, trim: true },
    slug: { type: String, required: true, unique: true, trim: true, index: true },
    networkOptions: [{ type: String, trim: true }],
    categoryTags: [{ type: String, trim: true }],
    catalogStatus: {
      type: String,
      enum: ['verified', 'needs_verification', 'inactive_or_unclear'],
      default: 'needs_verification',
    },
    rulesStatus: {
      type: String,
      enum: ['verified', 'partial', 'insufficient'],
      default: 'insufficient',
    },
    recommendationEnabled: { type: Boolean, default: false },
    visual: { type: visualSchema, default: () => ({}) },
    sourceUrls: [{ type: String, trim: true }],
    recommendationRules: { type: [recommendationRuleSchema], default: [] },
    rewardDetails: { type: mongoose.Schema.Types.Mixed, default: () => ({}) },
    verification: { type: mongoose.Schema.Types.Mixed, default: () => ({}) },
  },
  { timestamps: true },
);

const CardCatalog = mongoose.model('CardCatalog', cardCatalogSchema);

module.exports = { CardCatalog };
