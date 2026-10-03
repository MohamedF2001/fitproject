import Objectif from "../models/Objectif.js";
import Succes from "../models/Succes.js";
import User from "../models/User.js";
import { checkGoals } from "../utils/goalsChecker.js";

const QUESTIONS_MOTIVATION_DEFAUT = [
  "Pourquoi cet objectif est important pour toi ?",
  "Combien de temps par semaine peux-tu y consacrer ?",
];

// ----- OBJECTIFS -----

export const createObjectif = async (req, res) => {
  try {
    const { type, valeurCible, dateCible, reponses } = req.body;

    if (!type) {
      return res.status(400).json({ message: "❌ Le type d'objectif est obligatoire" });
    }

    const questionsMotivation = QUESTIONS_MOTIVATION_DEFAUT.map((question, index) => ({
      question,
      reponse: Array.isArray(reponses) ? reponses[index] || "" : "",
    }));

    const objectif = await Objectif.create({
      utilisateur: req.userId,
      type,
      valeurCible: valeurCible ?? null,
      dateCible: dateCible ?? null,
      questionsMotivation,
    });

    console.log(`✅ Objectif créé pour l'utilisateur ${req.userId} : ${type}`);
    return res.status(201).json({ message: "✅ Objectif créé", objectif });
  } catch (error) {
    console.error("❌ Erreur lors de la création de l'objectif :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const getObjectifs = async (req, res) => {
  try {
    const objectifs = await Objectif.find({ utilisateur: req.userId }).populate("utilisateur");
    return res.status(200).json(objectifs);
  } catch (error) {
    console.error("❌ Erreur lors de la récupération des objectifs :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const getObjectifById = async (req, res) => {
  try {
    const objectif = await Objectif.findOne({ _id: req.params.id, utilisateur: req.userId }).populate("utilisateur");
    if (!objectif) {
      return res.status(404).json({ message: "❌ Objectif introuvable" });
    }
    return res.status(200).json(objectif);
  } catch (error) {
    console.error("❌ Erreur lors de la récupération de l'objectif :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const updateObjectif = async (req, res) => {
  try {
    const { type, valeurCible, statut, dateCible, reponses } = req.body;

    const objectif = await Objectif.findOne({ _id: req.params.id, utilisateur: req.userId });
    if (!objectif) {
      return res.status(404).json({ message: "❌ Objectif introuvable" });
    }

    if (type !== undefined) objectif.type = type;
    if (valeurCible !== undefined) objectif.valeurCible = valeurCible;
    if (statut !== undefined) objectif.statut = statut;
    if (dateCible !== undefined) objectif.dateCible = dateCible;
    if (Array.isArray(reponses) && reponses.length > 0) {
      if (objectif.questionsMotivation && objectif.questionsMotivation.length > 0) {
        objectif.questionsMotivation[0].reponse = reponses[0];
      } else {
        objectif.questionsMotivation = [{
          question: "Pourquoi cet objectif est important pour toi ?",
          reponse: reponses[0],
        }];
      }
    }

    await objectif.save();

    console.log(`✅ Objectif mis à jour : ${objectif._id}`);
    return res.status(200).json({ message: "✅ Objectif mis à jour", objectif });
  } catch (error) {
    console.error("❌ Erreur lors de la mise à jour de l'objectif :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const deleteObjectif = async (req, res) => {
  try {
    const objectif = await Objectif.findOneAndDelete({ _id: req.params.id, utilisateur: req.userId });
    if (!objectif) {
      return res.status(404).json({ message: "❌ Objectif introuvable" });
    }

    console.log(`✅ Objectif supprimé : ${req.params.id}`);
    return res.status(200).json({ message: "✅ Objectif supprimé" });
  } catch (error) {
    console.error("❌ Erreur lors de la suppression de l'objectif :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

// ----- SUCCÈS -----

export const getSucces = async (req, res) => {
  try {
    const succes = await Succes.find({ utilisateur: req.userId })
      .populate("utilisateur")
      .populate("objectif");
    return res.status(200).json(succes);
  } catch (error) {
    console.error("❌ Erreur lors de la récupération des succès :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const declencherVerificationObjectifs = async (userId) => {
  const user = await User.findById(userId);
  if (!user) return [];
  return checkGoals(user);
};
