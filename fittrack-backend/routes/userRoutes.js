import express from "express";
import {
  createObjectif,
  getObjectifs,
  getObjectifById,
  updateObjectif,
  deleteObjectif,
  getSucces,
} from "../controllers/userController.js";
import verifyToken from "../middlewares/auth.js";

const router = express.Router();

router.post("/objectifs", verifyToken, createObjectif);
router.get("/objectifs", verifyToken, getObjectifs);
router.get("/objectifs/:id", verifyToken, getObjectifById);
router.put("/objectifs/:id", verifyToken, updateObjectif);
router.delete("/objectifs/:id", verifyToken, deleteObjectif);

router.get("/succes", verifyToken, getSucces);

export default router;
