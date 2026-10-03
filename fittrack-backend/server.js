import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import swaggerUi from "swagger-ui-express";

import connectDB from "./config/db.js";
import { setCatalogueExercices } from "./controllers/exerciceController.js";

import authRoutes from "./routes/authRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import exerciceRoutes from "./routes/exerciceRoutes.js";
import programmeRoutes from "./routes/programmeRoutes.js";
import seanceRoutes from "./routes/seanceRoutes.js";

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// 1. CORS
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
  })
);

app.use(express.json());

// 2. Connexion MongoDB au démarrage
connectDB();

// 3. Chargement du catalogue d'exercices en mémoire
try {
  const cataloguePath = path.join(__dirname, "data", "exercises_by_muscle_fr.json");
  const catalogueBrut = fs.readFileSync(cataloguePath, "utf-8");
  setCatalogueExercices(JSON.parse(catalogueBrut));
  console.log("✅ Catalogue d'exercices chargé en mémoire");
} catch (error) {
  console.error("❌ Erreur lors du chargement du catalogue d'exercices :", error.message);
}

// 4. Routes
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/exercices", exerciceRoutes);
app.use("/api/programmes", programmeRoutes);
app.use("/api/seances", seanceRoutes);

// 5. Swagger
try {
  const swaggerPath = path.join(__dirname, "swagger.json");
  const swaggerDocument = JSON.parse(fs.readFileSync(swaggerPath, "utf-8"));
  app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));
  console.log("✅ Documentation Swagger disponible sur /api-docs");
} catch (error) {
  console.error("❌ Erreur lors du chargement de swagger.json :", error.message);
}

app.get("/", (req, res) => {
  res.json({ message: "📤 API FitTrack opérationnelle" });
});

app.use((req, res) => {
  res.status(404).json({ message: "❌ Route introuvable" });
});

// 6. Export dual : Vercel (serverless) + local
const PORT = process.env.PORT || 3000;

if (process.env.NODE_ENV !== "production") {
  app.listen(PORT, () => {
    console.log(`✅ Serveur FitTrack démarré sur le port ${PORT}`);
  });
}

const handler = app;
export default handler;
