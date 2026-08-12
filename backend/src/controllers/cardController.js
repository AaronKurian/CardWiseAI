const cardService = require('../services/cardService');
const { asyncHandler } = require('../utils/asyncHandler');

const seedCatalog = asyncHandler(async (_req, res) => {
  const cards = await cardService.seedCardCatalog();
  res.json({ cards });
});

const listCatalog = asyncHandler(async (req, res) => {
  const cards = await cardService.listCatalog(req.query);
  res.json({ cards });
});

const listUserCards = asyncHandler(async (req, res) => {
  const cards = await cardService.listUserCards(req.user._id);
  res.json({ cards });
});

const addUserCard = asyncHandler(async (req, res) => {
  const card = await cardService.addUserCard(req.user._id, req.body);
  res.status(201).json({ card });
});

const updateUserCard = asyncHandler(async (req, res) => {
  const card = await cardService.updateUserCard(req.user._id, req.params.id, req.body);
  res.json({ card });
});

const removeUserCard = asyncHandler(async (req, res) => {
  await cardService.removeUserCard(req.user._id, req.params.id);
  res.status(204).send();
});

module.exports = {
  seedCatalog,
  listCatalog,
  listUserCards,
  addUserCard,
  updateUserCard,
  removeUserCard,
};
