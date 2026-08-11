const profileService = require('../services/profileService');
const { asyncHandler } = require('../utils/asyncHandler');

const updateProfile = asyncHandler(async (req, res) => {
  const user = await profileService.updateProfile(req.user._id, req.body);
  res.json({ user });
});

const rewardStats = asyncHandler(async (req, res) => {
  const stats = await profileService.getRewardStats(req.user._id, req.query.period);
  res.json({ stats });
});

module.exports = { updateProfile, rewardStats };
