const { Router } = require('express');
const recommendationController = require('../controllers/recommendationController');
const { requireAuth } = require('../middleware/auth');

const router = Router();

router.post('/', requireAuth, recommendationController.recommendManual);
router.post('/chat', requireAuth, recommendationController.recommendChat);
router.post('/confirm', requireAuth, recommendationController.confirm);

module.exports = router;
