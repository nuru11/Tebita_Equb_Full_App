const { Router } = require('express');
const fs = require('fs');
const path = require('path');
const { requireAuth } = require('../../middleware/auth');

const uploadRoutes = Router();

uploadRoutes.post('/payment', requireAuth, (req, res) => {
  const { imageBase64 } = req.body || {};

  if (!imageBase64 || typeof imageBase64 !== 'string') {
    res.status(400).json({ error: 'imageBase64 is required' });
    return;
  }

  // Expect data URL or plain base64; strip prefix if present
  const base64Data = imageBase64.includes(',')
    ? imageBase64.split(',')[1]
    : imageBase64;

  let buffer;
  try {
    buffer = Buffer.from(base64Data, 'base64');
  } catch {
    res.status(400).json({ error: 'Invalid base64 image data' });
    return;
  }

  const uploadsRoot = path.join(__dirname, '..', '..', '..', 'uploads');
  const paymentsDir = path.join(uploadsRoot, 'payments');

  try {
    fs.mkdirSync(paymentsDir, { recursive: true });
  } catch {
    // ignore mkdir errors, attempt to write anyway
  }

  const filename = `payment_${Date.now()}.png`;
  const filePath = path.join(paymentsDir, filename);

  fs.writeFile(filePath, buffer, (err) => {
    if (err) {
      // eslint-disable-next-line no-console
      console.error('Failed to save payment screenshot', err);
      res.status(500).json({ error: 'Failed to save image' });
      return;
    }

    const urlPath = `/uploads/payments/${filename}`;
    res.status(201).json({ url: urlPath });
  });
});

module.exports = uploadRoutes;

