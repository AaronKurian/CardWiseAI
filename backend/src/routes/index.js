const { Router } = require('express');

const authRoutes = require('./authRoutes');
const cardRoutes = require('./cardRoutes');
const recommendationRoutes = require('./recommendationRoutes');
const profileRoutes = require('./profileRoutes');
const aiRoutes = require('./aiRoutes');

const router = Router();

router.use('/auth', authRoutes);
router.use('/cards', cardRoutes);
router.use('/recommendations', recommendationRoutes);
router.use('/profile', profileRoutes);
router.use('/ai', aiRoutes);

module.exports = router;
