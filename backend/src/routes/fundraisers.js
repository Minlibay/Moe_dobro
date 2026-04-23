const express = require('express');
const router = express.Router();
const fundraiserController = require('../controllers/fundraiserController');
const authMiddleware = require('../middleware/auth');
const upload = require('../middleware/upload');
const logger = require('../utils/logger');

router.get('/', fundraiserController.getAllFundraisers);
router.get('/my', authMiddleware, fundraiserController.getMyFundraisers);
router.get('/:id', fundraiserController.getFundraiserById);
router.post('/', authMiddleware, upload.array('images', 5), fundraiserController.createFundraiser);
router.patch('/:id/close', authMiddleware, fundraiserController.closeFundraiser);
router.post('/:id/completion-proof', authMiddleware, (req, res, next) => {
  logger.info('Completion-proof endpoint hit', { params: req.params, files: req.file, body: req.body });
  next();
}, upload.single('proof'), fundraiserController.submitCompletionProof);

module.exports = router;
