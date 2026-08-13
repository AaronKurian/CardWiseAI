const { callOpenRouter } = require('./openRouterService');
const { Merchant } = require('../../models/Merchant');

const aliasCache = { loadedAt: 0, items: [] };
const aliasCacheTtlMs = 5 * 60 * 1000;
const categoryHints = [
  { category: 'dining', terms: ['restaurant', 'restaurants', 'cafe', 'coffee shop', 'eatery', 'dine', 'dining'] },
  { category: 'food_delivery', terms: ['food delivery', 'ordered food', 'takeaway'] },
  { category: 'grocery', terms: ['grocery', 'groceries', 'supermarket', 'vegetables', 'fruits'] },
  { category: 'transport', terms: ['taxi', 'cab', 'auto', 'ride', 'bike taxi'] },
  { category: 'hotel', terms: ['hotel', 'resort', 'stay', 'room booking'] },
  { category: 'airlines', terms: ['flight', 'airline', 'air ticket', 'plane ticket'] },
  { category: 'travel', terms: ['travel', 'trip', 'holiday', 'tour', 'booking'] },
  { category: 'hospital', terms: ['hospital', 'clinic', 'doctor'] },
  { category: 'pharmacy', terms: ['medicine', 'pharmacy', 'chemist', 'medical store'] },
  { category: 'diagnostics', terms: ['lab test', 'blood test', 'scan', 'diagnostic'] },
  { category: 'cinema', terms: ['movie', 'cinema', 'theatre', 'multiplex'] },
  { category: 'fuel', terms: ['fuel', 'petrol', 'diesel'] },
  { category: 'utilities', terms: ['electricity', 'water bill', 'gas bill', 'utility bill'] },
  { category: 'telecom', terms: ['mobile recharge', 'phone recharge', 'telecom'] },
  { category: 'online_shopping', terms: ['online shopping', 'shopping website', 'marketplace'] },
];

const getMerchantAliases = async () => {
  if (Date.now() - aliasCache.loadedAt < aliasCacheTtlMs && aliasCache.items.length) {
    return aliasCache.items;
  }

  const merchants = await Merchant.find().select('name slug aliases').lean();
  aliasCache.items = merchants
    .flatMap((merchant) => [
      { alias: merchant.slug, slug: merchant.slug },
      { alias: merchant.name.toLowerCase(), slug: merchant.slug },
      ...(merchant.aliases || []).map((alias) => ({ alias, slug: merchant.slug })),
    ])
    .sort((a, b) => b.alias.length - a.alias.length);
  aliasCache.loadedAt = Date.now();
  return aliasCache.items;
};

const parseWithRegex = async (message) => {
  const text = String(message || '');
  const amountMatch = text.match(
    /(?:₹|rs\.?|inr)?\s*([0-9][0-9,]*(?:\.\d+)?)\s*(k|thousand|lakh|lac)?/i,
  );
  let amount = amountMatch ? Number(amountMatch[1].replace(/,/g, '')) : null;
  const unit = amountMatch?.[2]?.toLowerCase();
  if (amount && unit) {
    if (unit === 'k' || unit === 'thousand') amount *= 1000;
    if (unit === 'lakh' || unit === 'lac') amount *= 100000;
  }
  const lower = text.toLowerCase();
  const merchantAliases = await getMerchantAliases();
  const merchant = merchantAliases.find((item) => lower.includes(item.alias))?.slug || '';
  const category =
    categoryHints.find((hint) => hint.terms.some((term) => lower.includes(term)))
      ?.category || '';

  return {
    amount,
    merchant,
    category,
    confidence: amount && (merchant || category) ? 'fallback_structured' : 'needs_clarification',
    parser: 'regex_fallback',
  };
};

const parsePurchaseIntent = async (message) => {
  const fallback = await parseWithRegex(message);

  try {
    const result = await callOpenRouter([
      {
        role: 'system',
        content:
          [
            'You are CardWise input parser, not a financial advisor and not a rewards calculator.',
            'Extract only purchase intent from the user message for a credit-card recommendation workflow.',
            'Return valid JSON only. Do not wrap it in Markdown.',
            'Required JSON shape: {"amount": number|null, "merchant": string, "category": string, "currency": "INR", "missingFields": string[]}.',
            'If amount is not explicitly stated, set amount to null and include "amount" in missingFields.',
            'If merchant is not explicitly stated, set merchant to "".',
            'If the user provides a generic place type instead of a brand, infer category and do not mark merchant missing.',
            'Normalize rupees, INR, Rs, ₹, k, thousand, lakh and lac into numeric INR amount.',
            'Use category when obvious from the merchant, place type, or message; examples: restaurant/cafe -> dining, taxi/cab -> transport, hospital/clinic -> hospital, pharmacy/medicine -> pharmacy, hotel/resort -> hotel, flight/airline -> airlines, movie/cinema -> cinema, grocery/supermarket -> grocery.',
            'For unknown named restaurants or cafes such as Kerala Cafe, keep merchant as given and set category to dining.',
            'For missingFields, include "merchant" only when both merchant and category are unavailable.',
            'Never invent reward rates, card names, eligibility, caps, issuer data, or final recommendations.',
          ].join(' '),
      },
      { role: 'user', content: message },
    ]);
    const parsed = JSON.parse(result.content);

    return {
      amount: Number(parsed.amount || fallback.amount || 0) || null,
      merchant: parsed.merchant || fallback.merchant || '',
      category: parsed.category || fallback.category || '',
      currency: parsed.currency || 'INR',
      missingFields: [
        ...new Set(
          (parsed.missingFields || []).filter(
            (field) => field !== 'merchant' || !(parsed.category || fallback.category),
          ),
        ),
      ],
      parser: result.provider,
    };
  } catch (_error) {
    return {
      ...fallback,
      currency: 'INR',
      missingFields: [
        ...(!fallback.amount ? ['amount'] : []),
        ...(!fallback.merchant && !fallback.category ? ['merchant'] : []),
      ],
    };
  }
};

module.exports = { parsePurchaseIntent };
