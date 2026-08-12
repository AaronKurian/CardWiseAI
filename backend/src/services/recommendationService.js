const { UserCard } = require('../models/UserCard');
const { RecommendationEvent } = require('../models/RecommendationEvent');
const mongoose = require('mongoose');
const { httpError } = require('../utils/httpError');
const { normalizeMerchant } = require('./merchantService');
const { calculateReward } = require('./rewardEngine');
const { parsePurchaseIntent } = require('./ai/intentParser');
const { buildAssistantReply } = require('./ai/chatAssistant');

const normalizeSessionContext = (sessionContext = {}) => {
  const recommendations = Array.isArray(sessionContext.recommendations)
    ? sessionContext.recommendations
    : [];

  const cleanRecommendations = recommendations
    .map((item) => ({
      amount: Number(item.amount || 0),
      merchant: String(item.merchant || ''),
      category: String(item.category || ''),
      recommendedCard: String(item.recommendedCard || ''),
      estimatedReward: Number(item.estimatedReward || 0),
    }))
    .filter((item) => item.amount > 0);

  return {
    recommendations: cleanRecommendations,
    totals: {
      count: cleanRecommendations.length,
      expenditure: cleanRecommendations.reduce((sum, item) => sum + item.amount, 0),
      estimatedRewards: cleanRecommendations.reduce(
        (sum, item) => sum + item.estimatedReward,
        0,
      ),
    },
  };
};

const buildRecommendation = async (userId, input) => {
  const amount = Number(input.amount || 0);
  if (!amount || amount <= 0) {
    throw httpError(400, 'Valid amount is required');
  }

  const normalized = await normalizeMerchant(input.merchant);
  const category = input.category || normalized.category;
  const merchant = normalized.merchant || input.category || 'Selected category';
  const merchantSlug = normalized.merchantSlug || input.category || 'selected-category';
  const userCards = await UserCard.find({ userId }).populate('cardId');

  if (userCards.length === 0) {
    throw httpError(400, 'Add at least one card before requesting recommendations');
  }

  const alternatives = userCards
    .filter((userCard) => userCard.cardId?.recommendationEnabled)
    .map((userCard) => {
      const calculation = calculateReward({
        amount,
        card: userCard.cardId,
        merchantSlug,
        category,
      });

      return {
        userCardId: userCard._id,
        cardId: userCard.cardId._id,
        cardName: userCard.cardId.name,
        issuer: userCard.cardId.issuer,
        nickname: userCard.nickname,
        last4: userCard.last4,
        visual: userCard.cardId.visual,
        estimatedReward: calculation.expectedReward,
        rewardRate: calculation.rewardRate,
        reason: calculation.reason,
        capApplied: calculation.capApplied || false,
      };
    })
    .sort((a, b) => b.estimatedReward - a.estimatedReward);

  if (alternatives.length === 0) {
    throw httpError(400, 'No recommendation-enabled cards found for this user');
  }

  return {
    input: {
      amount,
      merchant,
      merchantSlug,
      category,
      currency: input.currency || 'INR',
      merchantMatched: normalized.matched,
    },
    recommendedCard: alternatives[0],
    alternatives,
  };
};

const recommendFromChat = async (userId, message, sessionContext) => {
  const normalizedSessionContext = normalizeSessionContext(sessionContext);
  const intent = await parsePurchaseIntent(message);

  if (!intent.amount || (!intent.merchant && !intent.category)) {
    const assistantReply = await buildAssistantReply({
      message,
      intent,
      sessionContext: normalizedSessionContext,
    });

    return {
      ...assistantReply,
      missingFields: intent.missingFields,
      suggestedInput: {
        amount: intent.amount,
        merchant: intent.merchant,
        category: intent.category,
        currency: intent.currency,
      },
    };
  }

  const recommendation = await buildRecommendation(userId, intent);

  return {
    needsManualInput: false,
    parser: intent.parser,
    recommendation,
  };
};

const confirmRecommendation = async (userId, payload) => {
  if (!payload.recommendedUserCardId || !payload.recommendedCatalogCardId) {
    throw httpError(400, 'recommendedUserCardId and recommendedCatalogCardId are required');
  }

  if (!mongoose.Types.ObjectId.isValid(payload.recommendedUserCardId)) {
    throw httpError(400, 'Invalid recommendedUserCardId');
  }

  const userCard = await UserCard.findOne({
    _id: payload.recommendedUserCardId,
    userId,
  });

  if (!userCard) {
    throw httpError(404, 'Recommended card was not found in this user wallet');
  }

  if (userCard.cardId.toString() !== payload.recommendedCatalogCardId) {
    throw httpError(400, 'Recommended card does not match the catalog card');
  }

  const amount = Number(payload.amount || 0);
  const estimatedReward = Number(payload.estimatedReward || 0);
  if (amount <= 0 || estimatedReward < 0) {
    throw httpError(400, 'Valid amount and estimatedReward are required');
  }

  const event = await RecommendationEvent.create({
    userId,
    merchant: payload.merchant,
    category: payload.category || 'other',
    amount,
    recommendedUserCardId: payload.recommendedUserCardId,
    recommendedCatalogCardId: payload.recommendedCatalogCardId,
    estimatedReward,
    usedRecommendedCard: Boolean(payload.usedRecommendedCard),
    source: payload.source || 'chat',
  });

  return event;
};

module.exports = { buildRecommendation, recommendFromChat, confirmRecommendation };
