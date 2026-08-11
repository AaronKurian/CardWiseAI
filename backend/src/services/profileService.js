const { User } = require('../models/User');
const { RecommendationEvent } = require('../models/RecommendationEvent');
const { httpError } = require('../utils/httpError');

const updateProfile = async (userId, payload) => {
  const user = await User.findByIdAndUpdate(
    userId,
    {
      $set: {
        'profile.name': payload.name || '',
        'profile.avatarUrl': payload.avatarUrl || '',
        'profile.avatarSvg': payload.avatarSvg || '',
      },
    },
    { returnDocument: 'after' },
  ).select('-passwordHash');

  if (!user) {
    throw httpError(404, 'User not found');
  }

  return user;
};

const getRewardStats = async (userId, period = 'month') => {
  const now = new Date();
  const start = new Date(now);

  if (period === 'week') {
    start.setDate(now.getDate() - 7);
  } else if (period === 'year') {
    start.setFullYear(now.getFullYear() - 1);
  } else {
    start.setMonth(now.getMonth() - 1);
  }

  const events = await RecommendationEvent.find({
    userId,
    usedRecommendedCard: true,
    createdAt: { $gte: start },
  }).sort({ createdAt: 1 });

  const totalEstimatedRewards = events.reduce(
    (sum, event) => sum + event.estimatedReward,
    0,
  );

  return {
    period,
    totalEstimatedRewards: Number(totalEstimatedRewards.toFixed(2)),
    count: events.length,
    points: events.map((event) => ({
      date: event.createdAt,
      amount: event.amount,
      estimatedReward: event.estimatedReward,
      merchant: event.merchant,
    })),
  };
};

module.exports = { updateProfile, getRewardStats };
