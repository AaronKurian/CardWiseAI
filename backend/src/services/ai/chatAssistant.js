const { callOpenRouter } = require('./openRouterService');

const fallbackAssistantReply = (intent = {}) => {
  const sessionContext = intent.sessionContext || {};
  const totals = sessionContext.totals;
  const asksTotal = /\b(total|sum|how much|spent|expenditure|reward|rewards|earned)\b/i.test(
    intent.message || '',
  );
  if (asksTotal && totals?.count) {
    return `In this chat, you have checked ${totals.count} spends totaling ₹${totals.expenditure.toFixed(0)}, with estimated rewards of ₹${totals.estimatedRewards.toFixed(0)}.`;
  }

  const missing = new Set(intent.missingFields || []);
  if (missing.has('amount') && missing.has('merchant')) {
    return 'I am CardWise. Tell me the purchase amount and merchant, like "I am spending ₹12,000 on Swiggy", and I will check your saved cards.';
  }
  if (missing.has('amount')) {
    return 'Please share the amount for this purchase so I can check your saved cards.';
  }
  if (missing.has('merchant')) {
    return 'Please share the merchant name for this purchase so I can check your saved cards.';
  }
  return 'I am CardWise. I can help with credit-card spend questions when you share the amount and merchant.';
};

const buildAssistantReply = async ({ message, intent, sessionContext }) => {
  try {
    const result = await callOpenRouter(
      [
        {
          role: 'system',
          content: [
            'You are CardWise, a concise assistant inside a credit-card rewards app.',
            'Answer greetings, identity questions, app usage questions, and incomplete purchase requests naturally.',
            'If the user wants a card recommendation but amount or merchant is missing, ask only for the missing details.',
            'Do not recommend a specific card, calculate rewards, invent issuer data, or provide financial advice.',
            'When the user provides both amount and merchant, tell them you will check their saved cards; do not choose the card yourself.',
            'Use currentSessionContext to answer questions about totals in this current chat only.',
            'If currentSessionContext has no recommendations, say there are no checked spends in this chat yet.',
            'Never claim these totals are bank transactions or all-time profile history.',
            'Keep replies under 45 words.',
          ].join(' '),
        },
        {
          role: 'user',
          content: JSON.stringify({
            userMessage: message,
            parsedPurchaseIntent: intent || null,
            currentSessionContext: sessionContext || null,
          }),
        },
      ],
      { responseFormat: false, temperature: 0.2 },
    );

    return {
      type: 'assistant_reply',
      needsManualInput: false,
      parser: result.provider,
      message:
        result.content.trim() ||
        fallbackAssistantReply({ ...intent, message, sessionContext }),
    };
  } catch (_error) {
    return {
      type: 'assistant_reply',
      needsManualInput: false,
      parser: 'assistant_fallback',
      message: fallbackAssistantReply({ ...intent, message, sessionContext }),
    };
  }
};

module.exports = { buildAssistantReply };
