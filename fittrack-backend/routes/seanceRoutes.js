import express from "express";
import {
  createSeance,
  getSeances,
  getSeanceById,
  updateSeance,
  deleteSeance,
  validerSeance,
} from "../controllers/seanceController.js";
import verifyToken from "../middlewares/auth.js";

const router = express.Router();

router.post("/", verifyToken, createSeance);
router.get("/", verifyToken, getSeances);
router.get("/:id", verifyToken, getSeanceById);
router.put("/:id", verifyToken, updateSeance);
router.delete("/:id", verifyToken, deleteSeance);
router.put("/:id/valider", verifyToken, validerSeance);

export default router;
