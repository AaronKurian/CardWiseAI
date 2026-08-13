const { parsePurchaseIntent } = require('../services/ai/intentParser');
const { asyncHandler } = require('../utils/asyncHandler');

const parseIntent = asyncHandler(async (req, res) => {
  const intent = await parsePurchaseIntent(req.body.message);
  res.json({ intent });
});

module.exports = { parseIntent };
