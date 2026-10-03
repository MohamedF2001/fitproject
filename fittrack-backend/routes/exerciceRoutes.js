import express from "express";
import { getExercices, getExerciceById } from "../controllers/exerciceController.js";

const router = express.Router();

router.get("/", getExercices);
router.get("/:id", getExerciceById);

export default router;
