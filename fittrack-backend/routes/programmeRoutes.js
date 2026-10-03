import express from "express";
import {
  createProgramme,
  getProgrammes,
  getProgrammeActif,
  getProgrammeById,
  updateProgramme,
  deleteProgramme,
} from "../controllers/programmeController.js";
import verifyToken from "../middlewares/auth.js";

const router = express.Router();

router.post("/", verifyToken, createProgramme);
router.get("/", verifyToken, getProgrammes);
router.get("/actif", verifyToken, getProgrammeActif);
router.get("/:id", verifyToken, getProgrammeById);
router.put("/:id", verifyToken, updateProgramme);
router.delete("/:id", verifyToken, deleteProgramme);

export default router;
