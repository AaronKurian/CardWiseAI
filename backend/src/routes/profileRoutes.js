const { Router } = require('express');
const profileController = require('../controllers/profileController');
const { requireAuth } = require('../middleware/auth');

const router = Router();

router.patch('/', requireAuth, profileController.updateProfile);
router.get('/reward-stats', requireAuth, profileController.rewardStats);

module.exports = router;
