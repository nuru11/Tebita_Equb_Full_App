/**
 * Validate req.body against a schema (e.g. Zod).
 * If no schema lib yet, this is a no-op; add Zod later and use schema.parse(req.body).
 */
function validateBody(schema) {
  return (req, res, next) => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Validation failed';
      res.status(400).json({ error: message });
    }
  };
}

module.exports = { validateBody };
