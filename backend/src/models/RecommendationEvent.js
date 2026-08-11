const mongoose = require('mongoose');

const recommendationEventSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    merchant: { type: String, required: true, trim: true },
    category: { type: String, required: true, trim: true },
    amount: { type: Number, required: true, min: 0 },
    recommendedUserCardId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'UserCard',
      required: true,
    },
    recommendedCatalogCardId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'CardCatalog',
      required: true,
    },
    estimatedReward: { type: Number, required: true, min: 0 },
    usedRecommendedCard: { type: Boolean, required: true },
    source: { type: String, enum: ['chat', 'manual'], default: 'chat' },
  },
  { timestamps: true },
);

recommendationEventSchema.index({ userId: 1, createdAt: -1 });

const RecommendationEvent = mongoose.model(
  'RecommendationEvent',
  recommendationEventSchema,
);

module.exports = { RecommendationEvent };
