const mongoose = require('mongoose');

const profileSchema = new mongoose.Schema(
  {
    name: { type: String, trim: true, default: '' },
    avatarUrl: { type: String, trim: true, default: '' },
    avatarSvg: { type: String, default: '' },
  },
  { _id: false },
);

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    passwordHash: { type: String, required: true },
    profile: { type: profileSchema, default: () => ({}) },
  },
  { timestamps: true },
);

const User = mongoose.model('User', userSchema);

module.exports = { User };
