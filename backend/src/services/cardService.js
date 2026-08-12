const { CardCatalog } = require('../models/CardCatalog');
const { UserCard } = require('../models/UserCard');
const { httpError } = require('../utils/httpError');

const seedCardCatalog = async () => {
  return CardCatalog.find().sort({ issuer: 1, name: 1 });
};

const normalizeSearchText = (value = '') =>
  value
    .toString()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();

const levenshteinDistance = (left, right) => {
  if (left === right) return 0;
  if (!left) return right.length;
  if (!right) return left.length;

  const previous = Array.from({ length: right.length + 1 }, (_, index) => index);
  const current = Array(right.length + 1).fill(0);

  for (let i = 1; i <= left.length; i += 1) {
    current[0] = i;
    for (let j = 1; j <= right.length; j += 1) {
      const cost = left[i - 1] === right[j - 1] ? 0 : 1;
      current[j] = Math.min(
        current[j - 1] + 1,
        previous[j] + 1,
        previous[j - 1] + cost,
      );
    }
    for (let j = 0; j <= right.length; j += 1) previous[j] = current[j];
  }

  return previous[right.length];
};

const tokenScore = (queryToken, targetToken) => {
  if (!queryToken || !targetToken) return 0;
  if (targetToken === queryToken) return 1;
  if (targetToken.startsWith(queryToken)) return 0.92;
  if (targetToken.includes(queryToken)) return 0.84;

  const distance = levenshteinDistance(queryToken, targetToken);
  const longest = Math.max(queryToken.length, targetToken.length);
  const similarity = 1 - distance / longest;
  const tolerance = queryToken.length <= 4 ? 0.74 : 0.66;
  return similarity >= tolerance ? similarity : 0;
};

const scoreCatalogCard = (card, query) => {
  const normalizedQuery = normalizeSearchText(query);
  if (!normalizedQuery) return 1;

  const target = normalizeSearchText([
    card.name,
    card.issuer,
    card.slug,
    ...(card.categoryTags || []),
    ...(card.networkOptions || []),
    card.visual?.brandLabel,
    card.visual?.issuerLabel,
  ].join(' '));

  if (target.includes(normalizedQuery)) return 2;

  const queryTokens = normalizedQuery.split(' ').filter(Boolean);
  const targetTokens = target.split(' ').filter(Boolean);
  if (queryTokens.length === 0 || targetTokens.length === 0) return 0;

  let total = 0;
  for (const queryToken of queryTokens) {
    const best = Math.max(
      ...targetTokens.map((targetToken) => tokenScore(queryToken, targetToken)),
    );
    if (best === 0) return 0;
    total += best;
  }

  return total / queryTokens.length;
};

const listCatalog = async ({ q, issuer }) => {
  const filter = {};

  if (issuer) {
    filter.issuer = issuer;
  }

  const cards = await CardCatalog.find(filter).sort({ issuer: 1, name: 1 });
  if (!q || !q.trim()) {
    return cards;
  }

  return cards
    .map((card) => ({ card, score: scoreCatalogCard(card, q) }))
    .filter((result) => result.score > 0)
    .sort((left, right) => {
      if (right.score !== left.score) return right.score - left.score;
      return left.card.name.localeCompare(right.card.name);
    })
    .slice(0, 50)
    .map((result) => result.card);
};

const listUserCards = (userId) =>
  UserCard.find({ userId }).populate('cardId').sort({ createdAt: -1 });

const addUserCard = async (userId, payload) => {
  if (!payload.cardId) {
    throw httpError(400, 'cardId is required');
  }

  const catalogCard = await CardCatalog.findById(payload.cardId);
  if (!catalogCard) {
    throw httpError(404, 'Card catalog item not found');
  }

  let userCard;
  try {
    userCard = await UserCard.create({
      userId,
      cardId: payload.cardId,
      nickname: payload.nickname || '',
      last4: payload.last4 || '',
      network: payload.network || '',
    });
  } catch (error) {
    if (error.code === 11000) {
      throw httpError(409, 'This card is already in your wallet');
    }
    throw error;
  }

  return userCard.populate('cardId');
};

const updateUserCard = async (userId, userCardId, payload) => {
  const userCard = await UserCard.findOneAndUpdate(
    { _id: userCardId, userId },
    {
      $set: {
        nickname: payload.nickname || '',
        last4: payload.last4 || '',
        network: payload.network || '',
      },
    },
    { returnDocument: 'after', runValidators: true },
  ).populate('cardId');

  if (!userCard) {
    throw httpError(404, 'User card not found');
  }

  return userCard;
};

const removeUserCard = async (userId, userCardId) => {
  const deleted = await UserCard.findOneAndDelete({ _id: userCardId, userId });
  if (!deleted) {
    throw httpError(404, 'User card not found');
  }
};

module.exports = {
  seedCardCatalog,
  listCatalog,
  listUserCards,
  addUserCard,
  updateUserCard,
  removeUserCard,
};
