const mongoose = require('mongoose');

const userCardSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    cardId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'CardCatalog',
      required: true,
    },
    nickname: { type: String, trim: true, default: '' },
    last4: {
      type: String,
      trim: true,
      validate: {
        validator: (value) => !value || /^\d{4}$/.test(value),
        message: 'last4 must contain exactly four digits',
      },
    },
    network: { type: String, trim: true, default: '' },
  },
  { timestamps: true },
);

userCardSchema.index({ userId: 1, cardId: 1 }, { unique: true });

const UserCard = mongoose.model('UserCard', userCardSchema);

module.exports = { UserCard };
