import * as ethers from 'ethers';
import TelegramBot from 'node-telegram-bot-api';
import { readFileSync } from 'fs';
import * as dotenv from 'dotenv';

const {parseEther, formatEther, JsonRpcProvider, Contract} = ethers;
dotenv.config();

// Configuración del nodo Web3
const provider = new JsonRpcProvider(process.env.RPC_URL);
 
// Cargar el ABI desde el archivo JSON
const rawData = JSON.parse(readFileSync('./BaseRaffle.json', 'utf8'));
const contractABI = rawData.abi;

const bunnyArtifact = JSON.parse(readFileSync('./CashBunny.json', 'utf8'));
const bunnyABI = bunnyArtifact.abi;
  
// Dirección del contrato
const raffleContractAddress = process.env.RAFFLE_ADDRESS;
const bunnyContractAddress = process.env.BUNNY_ADDRESS;
// Crear una instancia del contrato
const raffleContract = new Contract(raffleContractAddress, contractABI, provider);
const bunnyContract = new Contract(bunnyContractAddress, bunnyABI, provider);

// Configuración del bot de Telegram
const bot = new TelegramBot(process.env.TELEGRAM_TOKEN, { polling: true });
const chatId = process.env.CHAT_ID;


// Formatear el tiempo restante de manera legible
function formatRemainingTime(seconds) {
    const secondsNumber = Number(seconds); // Convertir BigInt a Number

    const days = Math.floor(secondsNumber / 86400);
    const hours = Math.floor((secondsNumber % 86400) / 3600);
    const minutes = Math.floor((secondsNumber % 3600) / 60);
    const remainingSeconds = secondsNumber % 60;

    return `${days}d ${hours}h ${minutes}m ${remainingSeconds}s`;
}

function commify(value, decimals = 4) {
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

// Función para manejar contribuciones
const  handleEnterRaffle = async (participant, tickets, event) => {

     // Obtener el total de contribuciones y el número de contribuyentes
     const remainingTime = await raffleContract.getTimeLeftToDraw();
     const ticketCost = await raffleContract.getTicketCost();
     const totalTickets = await raffleContract.getTotalTickets();
     const TotalParticipants = await raffleContract.getTotalParticipants();
     const balance = await provider.getBalance(raffleContractAddress);

     const totalSupply = await bunnyContract.totalSupply();
     const symbol = await bunnyContract.symbol();
     const name = await bunnyContract.name();
     const decimals = await bunnyContract.decimals();


     // Convertir el balance de wei a BNB
     const balanceInBNB = ethers.formatUnits(balance, 'ether');  // 'ether' se usa porque BNB tiene la misma unidad base que Ether
     
     const BalanceBNB = balanceInBNB;
     const balanceAfterReduction = BalanceBNB * 0.9;

     // Calcular el 50% y el 25% del balance restante
    const fiftyPercent = (balanceAfterReduction * 0.5).toFixed(4);
    const twentyFivePercent1 = (balanceAfterReduction * 0.25).toFixed(4);
    const twentyFivePercent2 = (balanceAfterReduction * 0.25).toFixed(4);
    const RolloverBNB = (BalanceBNB * 0.10).toFixed(4);
    const totalPrizeBalance = parseFloat(BalanceBNB).toFixed(5)

    // Convertir wei a ETH
    const formattedTicketAmount = tickets;
    const formattedTicketCost = commify(formatEther(`${ticketCost * tickets}`), 2); //commify(Number(formatEther(TicketCost)) * formatEther(tickets), 4);
    const formattedTotalTicket = totalTickets;
    const formattedTotalParticipants = TotalParticipants;
    const formattedTotalSupply = commify(Number(formatEther(totalSupply)), 2);
    const truncatedParticipant = `${participant.slice(0, 6)}...${participant.slice(-4)}`;
    const tokensReceived = Number(formattedTicketCost); // Tokens recibidos por la cantidad de BNB enviada


    // Formatted time (para el mensaje)
    const formattedTime = formatRemainingTime(remainingTime);

    const twitterLink = 'https://x.com/CashBunnydotfun'; // Enlace de Twitter
    const bscScanTransactionsLink = `https://bscscan.com/address/${raffleContractAddress}`; // Enlace a las transacciones del contrato
    const rafflelink = 'https://cashbunny.fun/raffle'; // Enlace de Twitter

    const message = `
📢**New Tickets Bought**
      
🧑**Player:** ${truncatedParticipant}
✅**Tickets Bought:** ${formattedTicketAmount} 
💸**Spent:** ${formattedTicketCost} BUNNY
🔥**$BUNNY Burned:** ${formattedTicketCost} BUNNY
🔢**Total Tickets:** ${formattedTotalTicket}
🧑‍🤝‍🧑**Total Players:** ${formattedTotalParticipants}
⏳**Time Left:** ${formattedTime}

**🏆Current Prizes Values🏆**

💰**Total Prize:** ${totalPrizeBalance} BNB
🥇**Fist Prize:** ${fiftyPercent} BNB
🥈**Second Prize:** ${twentyFivePercent1} BNB
🥉**Third Prize:** ${twentyFivePercent2} BNB
🔄**Rollover Prize:** ${RolloverBNB} BNB

**📑Token Details📑**

🏷️**Name:** ${name}
💠**Symbol:** ${symbol}
🔢 **Decimals:** ${decimals}
💰**Total Supply:** ${formattedTotalSupply}


[🎰▶️ Play Now](${rafflelink}) | [🔗 Tx](${bscScanTransactionsLink}) | [🌐 X](${twitterLink})
 
    `;

     const imageUrl = './video.mp4'; // Reemplaza con la URL de la imagen


    try {
        // Enviar una foto con el mensaje como descripción
        await bot.sendVideo(chatId, imageUrl, { caption: message, parse_mode: 'Markdown' });
        console.log('✅ Notificación enviada con imagen');
    } catch (error) {
        console.error('❌ Error al enviar el mensaje con imagen a Telegram:', error);
    }
}

const listenEvents = async () => {
    console.log('🚀 Bot de monitoreo iniciado. Esperando eventos...');

    raffleContract.on("RaffleEntered", handleEnterRaffle); // Escuchar evento
}

listenEvents();