const { env } = require('../../config/env');

const isRateLimited = (status) => status === 429 || status === 402;

const isUsableKey = (key) =>
  key &&
  !key.startsWith('mock-') &&
  !key.startsWith('replace-') &&
  key.length > 20;

const callOpenRouter = async (messages, options = {}) => {
  const keys = [
    { label: 'primary', key: env.openRouter.primaryApiKey },
    { label: 'fallback', key: env.openRouter.fallbackApiKey },
  ].filter((entry) => isUsableKey(entry.key));

  let lastError = null;

  for (const entry of keys) {
    try {
      const response = await fetch(`${env.openRouter.baseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${entry.key}`,
          'Content-Type': 'application/json',
          'HTTP-Referer': 'http://localhost:3000',
          'X-Title': 'CardWise',
        },
        body: JSON.stringify({
          model: env.openRouter.model,
          messages,
          temperature: options.temperature ?? 0,
          max_tokens: options.maxTokens || 400,
          ...(options.responseFormat === false
            ? {}
            : { response_format: options.responseFormat || { type: 'json_object' } }),
        }),
      });

      if (!response.ok) {
        lastError = new Error(`OpenRouter ${entry.label} failed with ${response.status}`);
        if (isRateLimited(response.status)) {
          continue;
        }
        continue;
      }

      const data = await response.json();
      return {
        provider: `openrouter:${entry.label}`,
        content: data.choices?.[0]?.message?.content || '',
      };
    } catch (error) {
      lastError = error;
    }
  }

  if (lastError) {
    lastError.openRouterFailed = true;
    throw lastError;
  }

  const error = new Error('OpenRouter keys are not configured');
  error.openRouterFailed = true;
  throw error;
};

module.exports = { callOpenRouter };
