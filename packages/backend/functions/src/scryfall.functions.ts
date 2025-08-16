//api functions to connect to https://scryfall.com/docs/api

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

export const getScryfallCard = onCall({ region: "europe-west3" }, async (request) => {
    const { cardId } = request.data;

    if (!cardId || typeof cardId !== 'string') {
        throw new HttpsError(
            'invalid-argument',
            'cardId is required and must be a string'
        );
    }

    try {
        logger.info(`Fetching Scryfall card data for ID: ${cardId}`);

        const response = await fetch(`https://api.scryfall.com/cards/${cardId}`);

        if (!response.ok) {
            if (response.status === 404) {
                throw new HttpsError('not-found', 'Card not found');
            }
            throw new HttpsError(
                'internal',
                `Scryfall API error: ${response.status} ${response.statusText}`
            );
        }

        const cardData = await response.json();

        logger.info(`Successfully fetched card data for: ${cardData.name}`);

        return cardData;
    } catch (error) {
        if (error instanceof HttpsError) {
            throw error;
        }

        logger.error('Error fetching Scryfall card data:', error);
        throw new HttpsError(
            'internal',
            'Failed to fetch card data from Scryfall API'
        );
    }
});