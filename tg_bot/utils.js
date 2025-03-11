// Formatear el tiempo restante de manera legible
export function formatRemainingTime(seconds) {
    const secondsNumber = Number(seconds); // Convertir BigInt a Number

    const days = Math.floor(secondsNumber / 86400);
    const hours = Math.floor((secondsNumber % 86400) / 3600);
    const minutes = Math.floor((secondsNumber % 3600) / 60);
    const remainingSeconds = secondsNumber % 60;

    return `${days}d ${hours}h ${minutes}m ${remainingSeconds}s`;
}

export function commify(value, decimals = 4) {
  if (value === null || value === undefined) return "0";

  // Convert value to a string safely
  let numStr = String(value); // Ensure it's a string

  // Handle scientific notation (e.g., 1.23e-10)
  if (numStr.includes("e") || numStr.includes("E")) {
      numStr = Number(numStr).toFixed(18).replace(/\.?0+$/, ""); // Convert to full decimal format
  }

  // Convert to fixed decimal places if decimals is provided
  if (decimals !== null) {
      numStr = Number(numStr).toFixed(decimals);
  }

  // Split into integer and decimal parts
  let [integerPart, decimalPart] = numStr.split(".");

  // Handle negative numbers
  let isNegative = integerPart.startsWith("-");
  if (isNegative) integerPart = integerPart.substring(1);

  // Add commas to the integer part
  integerPart = integerPart.replace(/\B(?=(\d{3})+(?!\d))/g, ",");

  // Reattach the sign if negative
  let formattedNumber = isNegative ? "-" + integerPart : integerPart;

  // Append decimal part if present and decimals is not explicitly set to 0
  if (decimalPart !== undefined && decimals !== 0) {
      formattedNumber += "." + decimalPart;
  }

  return formattedNumber;
}