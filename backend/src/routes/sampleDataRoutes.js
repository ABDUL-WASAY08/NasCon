import { Router } from 'express';
import {
  getFixtures,
  getLeagueStandings,
  getLeagues,
  getProduct,
  getProducts,
  getStandings,
} from '../controllers/sampleDataController.js';

const router = Router();
router.get('/fixtures', getFixtures);
router.get('/standings', getStandings);
router.get('/store/products', getProducts);
router.get('/leagues', getLeagues);
router.get('/leagues/:leagueId/standings', getLeagueStandings);
router.get('/products', getProducts);
router.get('/products/:productId', getProduct);

export default router;
