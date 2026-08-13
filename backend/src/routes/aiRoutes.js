const { Router } = require('express');
const aiController = require('../controllers/aiController');
const { requireAuth } = require('../middleware/auth');

const router = Router();

router.post('/parse-intent', requireAuth, aiController.parseIntent);

module.exports = router;
