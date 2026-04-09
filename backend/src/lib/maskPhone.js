/**
 * Mask a phone for public/member display: first 2 + middle x + last 2 (e.g. 0912345678 → 09xxxxxx78).
 * @param {string|null|undefined} phone
 * @returns {string|null}
 */
function maskPhone(phone) {
  if (phone == null || phone === '') return null;
  const digits = String(phone).replace(/\D/g, '');
  if (digits.length < 4) {
    return 'x'.repeat(digits.length || 4);
  }
  const first = digits.slice(0, 2);
  const last = digits.slice(-2);
  const midLen = digits.length - 4;
  return `${first}${'x'.repeat(midLen)}${last}`;
}

module.exports = { maskPhone };
