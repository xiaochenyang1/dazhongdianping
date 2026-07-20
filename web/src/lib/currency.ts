const CURRENCY_SYMBOLS: Record<string, string> = {
  CNY: '¥',
  EUR: '€',
  GBP: '£',
}

export function formatMoney(amount: number, currency: string, fractionDigits?: number) {
  const code = currency.trim().toUpperCase()
  const symbol = CURRENCY_SYMBOLS[code] ?? ''
  const separator = symbol ? '' : ' '
  const formattedAmount = fractionDigits == null ? String(amount) : amount.toFixed(fractionDigits)
  return `${symbol}${separator}${formattedAmount} ${code}`.trim()
}
