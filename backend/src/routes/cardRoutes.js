const { Router } = require('express');
const cardController = require('../controllers/cardController');
const { requireAuth } = require('../middleware/auth');

const router = Router();

router.post('/catalog/seed', cardController.seedCatalog);
router.get('/catalog', cardController.listCatalog);
router.get('/mine', requireAuth, cardController.listUserCards);
router.post('/mine', requireAuth, cardController.addUserCard);
router.patch('/mine/:id', requireAuth, cardController.updateUserCard);
router.delete('/mine/:id', requireAuth, cardController.removeUserCard);

module.exports = router;
