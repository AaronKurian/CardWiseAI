const { Merchant } = require('../models/Merchant');

const escapeRegExp = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const aliasCache = { loadedAt: 0, items: [] };
const aliasCacheTtlMs = 5 * 60 * 1000;

const getMerchantAliases = async () => {
  if (Date.now() - aliasCache.loadedAt < aliasCacheTtlMs && aliasCache.items.length) {
    return aliasCache.items;
  }

  const merchants = await Merchant.find().select('name slug aliases category').lean();
  aliasCache.items = merchants
    .flatMap((item) => [
      { merchant: item, alias: item.slug },
      { merchant: item, alias: item.name.toLowerCase() },
      ...(item.aliases || []).map((alias) => ({ merchant: item, alias })),
    ])
    .filter((item) => item.alias)
    .sort((a, b) => b.alias.length - a.alias.length);
  aliasCache.loadedAt = Date.now();
  return aliasCache.items;
};

const seedMerchants = async () => {
  aliasCache.loadedAt = 0;
  aliasCache.items = [];
  return Merchant.find().sort({ name: 1 });
};

const normalizeMerchant = async (merchantName) => {
  const raw = String(merchantName || '').trim();
  if (!raw) {
    return { merchant: '', merchantSlug: '', category: 'other', matched: false };
  }

  const lowered = raw.toLowerCase();
  const merchant = await Merchant.findOne({
    $or: [
      { slug: lowered },
      { aliases: lowered },
      { name: new RegExp(`^${escapeRegExp(raw)}$`, 'i') },
    ],
  });

  if (!merchant) {
    const aliases = await getMerchantAliases();
    const substringMatch = aliases.find((item) => lowered.includes(item.alias));

    if (substringMatch) {
      return {
        merchant: substringMatch.merchant.name,
        merchantSlug: substringMatch.merchant.slug,
        category: substringMatch.merchant.category,
        matched: true,
      };
    }

    return {
      merchant: raw,
      merchantSlug: lowered.replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, ''),
      category: 'other',
      matched: false,
    };
  }

  return {
    merchant: merchant.name,
    merchantSlug: merchant.slug,
    category: merchant.category,
    matched: true,
  };
};

module.exports = { seedMerchants, normalizeMerchant };
