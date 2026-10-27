import Objectif from "../models/Objectif.js";
import User from "../models/User.js";
import { getCatalogueExercices } from "./exerciceController.js";
import { memoryDb } from "../utils/memoryStore.js";
import mongoose from "mongoose";

const JOURS = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
const NIVEAUX = new Set(["debutant", "intermediaire", "avance"]);
const MAX_EXERCICES_PAR_JOUR = 8;

const responseError = (res, status, message) => res.status(status).json({ message });

const extractJson = (content) => {
  if (typeof content !== "string") throw new Error("Réponse IA vide");
  const parsed = JSON.parse(content);
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("Format de réponse IA invalide");
  }
  return parsed;
};

const normalizeProposal = (raw, exerciseIds, daysPerWeek) => {
  if (!Array.isArray(raw.jours) || raw.jours.length !== daysPerWeek) {
    throw new Error("Nombre de jours proposé invalide");
  }

  const seenDays = new Set();
  const jours = raw.jours.map((day) => {
    if (!day || !JOURS.includes(day.jour) || seenDays.has(day.jour)) {
      throw new Error("Jour proposé invalide");
    }
    seenDays.add(day.jour);

    const exercises = Array.isArray(day.exercices) ? day.exercices : [];
    const seenExercises = new Set();
    const validExercises = exercises
      .filter((item) => item && exerciseIds.has(item.exerciceId))
      .filter((item) => {
        if (seenExercises.has(item.exerciceId)) return false;
        seenExercises.add(item.exerciceId);
        return true;
      })
      .slice(0, MAX_EXERCICES_PAR_JOUR)
      .map((item, index) => ({ exerciceId: item.exerciceId, ordre: index + 1 }));

    if (validExercises.length < 3) {
      throw new Error("La proposition contient trop peu d’exercices valides");
    }

    const horaire = typeof day.horaire === "string" && /^([01]\d|2[0-3]):[0-5]\d$/.test(day.horaire)
      ? day.horaire
      : "07:00";
    return { jour: day.jour, horaire, exercices: validExercises };
  });

  const nom = typeof raw.nom === "string" ? raw.nom.trim().slice(0, 80) : "";
  const justification = typeof raw.justification === "string"
    ? raw.justification.trim().slice(0, 1000)
    : "Programme généré à partir de ton profil et du catalogue disponible.";
  if (!nom) throw new Error("Nom de programme absent");
  return { nom, justification, jours };
};

const generateLocalFallbackProposal = (exercises, dayCount, objectif) => {
  const selectedDays = JOURS.slice(0, dayCount);
  const jours = selectedDays.map((jour, dayIndex) => {
    const dayExercises = [];
    for (let i = 0; i < Math.min(4, exercises.length); i++) {
      const exIndex = (dayIndex * 4 + i) % exercises.length;
      dayExercises.push({
        exerciceId: exercises[exIndex].id,
        ordre: i + 1,
      });
    }
    return {
      jour,
      horaire: "08:00",
      exercices: dayExercises,
    };
  });

  return {
    nom: `Programme ${objectif && objectif !== "forme générale et progression régulière" ? objectif.slice(0, 40) : 'Sur Mesure'}`,
    justification: "Programme généré automatiquement et adapté à vos objectifs en cours et au catalogue d'exercices disponible.",
    jours,
  };
};

export const proposeProgramme = async (req, res) => {
  const { joursParSemaine, niveau, objectif, equipement } = req.body ?? {};
  const dayCount = Number(joursParSemaine);

  if (!Number.isInteger(dayCount) || dayCount < 1 || dayCount > 7) {
    return responseError(res, 400, "Le nombre de jours doit être compris entre 1 et 7.");
  }
  if (!NIVEAUX.has(niveau)) {
    return responseError(res, 400, "Le niveau doit être débutant, intermédiaire ou avancé.");
  }
  if (objectif !== undefined && (typeof objectif !== "string" || objectif.length > 500)) {
    return responseError(res, 400, "L’objectif doit contenir au maximum 500 caractères.");
  }
  if (equipement !== undefined && (typeof equipement !== "string" || equipement.length > 300)) {
    return responseError(res, 400, "L’équipement doit contenir au maximum 300 caractères.");
  }

  const apiKey = process.env.GEMINI_API_KEY;
  const preferredModel = process.env.GEMINI_MODEL || "gemini-3.5-flash-lite";

  try {
    let user, goals;
    if (mongoose.connection.readyState !== 1) {
      user = await memoryDb.users.findById(req.userId);
      goals = await memoryDb.objectifs.find({ utilisateur: req.userId, statut: "en_cours" });
    } else {
      [user, goals] = await Promise.all([
        User.findById(req.userId).select("nom prenom poids taille"),
        Objectif.find({ utilisateur: req.userId, statut: "en_cours" }).select("type valeurCible dateCible"),
      ]);
    }
    if (!user) return responseError(res, 404, "Profil utilisateur introuvable.");

    const catalogue = getCatalogueExercices();
    const exercises = catalogue.flatMap((group) =>
      (group.exercices || []).map((exercise) => ({
        id: exercise.id,
        nom: exercise.name_fr,
        muscle: group.muscle,
        equipement: exercise.equipment,
        categorie: exercise.category,
      })),
    );
    if (exercises.length < 3) {
      return responseError(res, 503, "Le catalogue d’exercices est indisponible.");
    }

    const resolvedObjective = (objectif || "forme générale et progression régulière").trim();

    if (!apiKey) {
      console.log("⚠️ GEMINI_API_KEY non configurée. Utilisation du générateur local de repli.");
      const proposition = generateLocalFallbackProposal(exercises, dayCount, resolvedObjective);
      return res.status(200).json({ proposition });
    }

    const promptData = {
      profil: { prenom: user.prenom, poidsKg: user.poids, tailleM: user.taille },
      objectifsEnCours: goals.map((goal) => ({
        type: goal.type,
        valeurCible: goal.valeurCible,
        dateCible: goal.dateCible,
      })),
      demande: {
        joursParSemaine: dayCount,
        niveau,
        objectif: resolvedObjective,
        equipement: (equipement || "aucune préférence précisée").trim(),
      },
      catalogueExercices: exercises,
    };

    const candidateModels = [
      preferredModel,
      "gemini-3.5-flash-lite",
      "gemini-3.1-flash-lite",
    ].filter((m, i, arr) => m && arr.indexOf(m) === i);

    let response = null;

    for (const targetModel of candidateModels) {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 25000);
      try {
        const res = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(targetModel)}:generateContent`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "x-goog-api-key": apiKey,
            },
            signal: controller.signal,
            body: JSON.stringify({
              systemInstruction: {
                parts: [{
                  text: `Tu es un assistant de planification sportive. Génère un programme général et prudent, avec échauffement implicite, répartition équilibrée et récupération. Utilise uniquement les identifiants du catalogue fourni. Retourne uniquement un objet JSON avec nom, justification et jours. jours doit contenir exactement ${dayCount} jours distincts, choisis parmi ${JOURS.join(", ")}. Chaque jour contient jour, horaire au format HH:mm et exercices (au moins 3) avec exerciceId. Ne crée aucun identifiant, ne fournis pas de diagnostic médical.`,
                }],
              },
              contents: [{
                role: "user",
                parts: [{ text: JSON.stringify(promptData) }],
              }],
              generationConfig: {
                responseMimeType: "application/json",
                temperature: 0.25,
                maxOutputTokens: 2200,
              },
            }),
          },
        );
        if (res.ok) {
          response = res;
          break;
        } else if (res.status === 503 || res.status === 429) {
          console.warn(`⚠️ Modèle ${targetModel} indisponible (${res.status}), bascule sur modèle de secours...`);
        } else {
          console.warn(`⚠️ Modèle ${targetModel} a retourné le statut HTTP ${res.status}.`);
        }
      } catch (callErr) {
        console.warn(`⚠️ Erreur d'appel ${targetModel} (${callErr?.message || callErr}), tentative suivante...`);
      } finally {
        clearTimeout(timeout);
      }
    }

    if (!response || !response.ok) {
      console.warn("⚠️ Impossible de joindre l'API Gemini. Bascule sur le générateur local de repli.");
      const proposition = generateLocalFallbackProposal(exercises, dayCount, resolvedObjective);
      return res.status(200).json({ proposition });
    }
    const payload = await response.json();
    const content = payload?.candidates?.[0]?.content?.parts
      ?.map((part) => part.text || "")
      .join("");
    const raw = extractJson(content);
    const exerciseIds = new Set(exercises.map((exercise) => exercise.id));
    const proposition = normalizeProposal(raw, exerciseIds, dayCount);
    return res.status(200).json({ proposition });
  } catch (error) {
    console.warn("⚠️ Erreur Gemini, bascule sur le générateur local :", error?.message || error);
    try {
      const catalogue = getCatalogueExercices();
      const exercises = catalogue.flatMap((group) =>
        (group.exercices || []).map((exercise) => ({
          id: exercise.id,
          nom: exercise.name_fr,
          muscle: group.muscle,
          equipement: exercise.equipment,
          categorie: exercise.category,
        })),
      );
      if (exercises.length >= 3) {
        const proposition = generateLocalFallbackProposal(exercises, dayCount, objectif);
        return res.status(200).json({ proposition });
      }
    } catch (_) {}

    return responseError(res, 502, "Le service de génération de programme n’a pas pu aboutir.");
  }
};
