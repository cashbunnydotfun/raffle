import * as ethers from 'ethers';
import * as dotenv from 'dotenv';
import TelegramBot from 'node-telegram-bot-api';
import { readFileSync } from 'fs';
import { formatRemainingTime, commify } from './utils.js';
dotenv.config();

const {formatEther, JsonRpcProvider, Contract} = ethers;

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


// Función para manejar contribuciones
const  handleEnterRaffle = async (participant, tickets, event) => {

     // Obtener el total de contribuciones y el número de contribuyentes
     const remainingTime = await raffleContract.getTimeLeftToDraw();
     const ticketCost = await raffleContract.getTicketCost();
     const totalTickets = await raffleContract.getTotalTickets();
     const totalParticipants = await raffleContract.getTotalParticipants();
     const balance = await provider.getBalance(raffleContractAddress);

     const totalSupply = await bunnyContract.totalSupply();
     const symbol = await bunnyContract.symbol();
     const name = await bunnyContract.name();
     const decimals = await bunnyContract.decimals();

     // Convertir el balance de wei a BNB
     const balanceInBNB = ethers.formatUnits(balance, 'ether');  
     
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
    const formattedTicketCost = commify(formatEther(`${ticketCost * tickets}`), 2);
    const formattedTotalTicket = totalTickets;
    const formattedTotalParticipants = totalParticipants;
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