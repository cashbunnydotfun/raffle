import * as ethers from 'ethers';
import * as dotenv from 'dotenv';
import TelegramBot from 'node-telegram-bot-api';
import { readFileSync } from 'fs';
import { formatRemainingTime, commify } from './utils.js';
dotenv.config();

const { formatEther, JsonRpcProvider, Contract } = ethers;

// Configuración del nodo Web3
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL, undefined, {
    staticNetwork: ethers.Network.from(56),
    polling: true
  });
  
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
const handleEnterRaffle = async (participant, tickets, event) => {
    // ... (tu lógica existente para el manejo del evento)
    // Por ejemplo:
    const remainingTime = await raffleContract.getTimeLeftToDraw();
    const ticketCost = await raffleContract.getTicketCost();
    const totalTickets = await raffleContract.getTotalTickets();
    const totalParticipants = await raffleContract.getTotalParticipants();
    const balance = await provider.getBalance(raffleContractAddress);

    const totalSupply = await bunnyContract.totalSupply();
    const symbol = await bunnyContract.symbol();
    const name = await bunnyContract.name();
    const decimals = await bunnyContract.decimals();

    const balanceInBNB = ethers.formatUnits(balance, 'ether');
    const BalanceBNB = balanceInBNB;
    const balanceAfterReduction = BalanceBNB * 0.9;

    const fiftyPercent = (balanceAfterReduction * 0.5).toFixed(4);
    const twentyFivePercent1 = (balanceAfterReduction * 0.25).toFixed(4);
    const twentyFivePercent2 = (balanceAfterReduction * 0.25).toFixed(4);
    const RolloverBNB = (BalanceBNB * 0.10).toFixed(4);
    const totalPrizeBalance = parseFloat(BalanceBNB).toFixed(5);

    const formattedTicketAmount = tickets;
    const formattedTicketCost = commify(formatEther(`${ticketCost * tickets}`), 2);
    const formattedTotalTicket = totalTickets;
    const formattedTotalParticipants = totalParticipants;
    const formattedTotalSupply = commify(Number(formatEther(totalSupply)), 2);
    const truncatedParticipant = `${participant.slice(0, 6)}...${participant.slice(-4)}`;
    const oldSupply = totalSupply - (ticketCost * tickets);
    const formattedOldSupply = commify(Number(formatEther(`${oldSupply}`)), 2);

    const formattedTime = formatRemainingTime(remainingTime);
    const twitterLink = 'https://x.com/CashBunnydotfun';
    const bscScanTransactionsLink = `https://bscscan.com/address/${raffleContractAddress}`;
    const rafflelink = 'https://cashbunny.fun/raffle';

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
💰**Total Supply was:** ${formattedTotalSupply} 👈
💰**Total Supply now:** ${formattedOldSupply} 🔥🔥🔥


[🎰▶️ Play Now](${rafflelink}) | [🔗 Tx](${bscScanTransactionsLink}) | [🌐 X](${twitterLink})
    `;

    const imageUrl = './video.mp4';

    try {
        await bot.sendVideo(chatId, imageUrl, { caption: message, parse_mode: 'Markdown' });
        console.log('✅ Notificación enviada con imagen');
    } catch (error) {
        console.error('❌ Error al enviar el mensaje con imagen a Telegram:', error);
    }
};

// Función para iniciar la escucha de eventos con reinicio en caso de error
const listenEvents = async () => {
    console.log('🚀 Bot de monitoreo iniciado. Esperando eventos...');
    try {
        // Escucha el evento "RaffleEntered"
        raffleContract.on("RaffleEntered", handleEnterRaffle);
    } catch (error) {
        console.error('❌ Error al escuchar eventos:', error);
        console.log('Reiniciando la escucha en 5 segundos...');
        // Remover listeners para evitar duplicados (si fuera necesario)
        raffleContract.removeAllListeners("RaffleEntered");
        setTimeout(listenEvents, 5000);
    }
};

// Manejar errores globales para reiniciar el script en caso de excepciones no capturadas
process.on('uncaughtException', (error) => {
    console.error('❌ Excepción no capturada:', error);
    console.log('Reiniciando el script en 5 segundos...');
    // Aquí se pueden agregar pasos de limpieza si es necesario
    setTimeout(() => process.exit(1), 5000);
});

listenEvents();
