const recommendationService = require('../services/recommendationService');
const { asyncHandler } = require('../utils/asyncHandler');

const recommendManual = asyncHandler(async (req, res) => {
  const recommendation = await recommendationService.buildRecommendation(
    req.user._id,
    req.body,
  );
  res.json({ recommendation });
});

const recommendChat = asyncHandler(async (req, res) => {
  const result = await recommendationService.recommendFromChat(
    req.user._id,
    req.body.message,
    req.body.sessionContext,
  );
  res.json(result);
});

const confirm = asyncHandler(async (req, res) => {
  const event = await recommendationService.confirmRecommendation(
    req.user._id,
    req.body,
  );
  res.status(201).json({ event });
});

module.exports = { recommendManual, recommendChat, confirm };
