const selectRule = (rules = [], merchantSlug, category) => {
  const cardRules = Array.isArray(rules) ? rules : [];

  return (
    cardRules.find((rule) => rule.merchant && rule.merchant === merchantSlug) ||
    cardRules.find((rule) => rule.category && rule.category === category) ||
    cardRules.find((rule) => rule.category === '*') ||
    null
  );
};

const calculateReward = ({ amount, card, merchantSlug, category }) => {
  const rule = selectRule(card?.recommendationRules, merchantSlug, category);

  if (!rule || !amount) {
    return {
      expectedReward: 0,
      rewardRate: 0,
      reason: 'No verified rule available for this card and merchant.',
      rule: null,
    };
  }

  const rawReward = (amount * rule.rate) / 100;
  const expectedReward = rule.cap == null ? rawReward : Math.min(rawReward, rule.cap);

  return {
    expectedReward: Number(expectedReward.toFixed(2)),
    rewardRate: rule.rate,
    reason: rule.label,
    capApplied: rule.cap != null && rawReward > rule.cap,
    rule,
  };
};

module.exports = { calculateReward };
