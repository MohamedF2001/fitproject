import Seance from "../models/Seance.js";
import User from "../models/User.js";
import { checkGoals } from "../utils/goalsChecker.js";

export const createSeance = async (req, res) => {
  try {
    const { date, exercices } = req.body;

    const seance = await Seance.create({
      utilisateur: req.userId,
      date: date || Date.now(),
      exercices: exercices || [],
    });

    await seance.populate("utilisateur");

    console.log(`✅ Séance créée : ${seance._id}`);
    return res.status(201).json({ message: "✅ Séance créée", seance });
  } catch (error) {
    console.error("❌ Erreur lors de la création de la séance :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const getSeances = async (req, res) => {
  try {
    const seances = await Seance.find({ utilisateur: req.userId }).populate("utilisateur");
    return res.status(200).json(seances);
  } catch (error) {
    console.error("❌ Erreur lors de la récupération des séances :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const getSeanceById = async (req, res) => {
  try {
    const seance = await Seance.findOne({ _id: req.params.id, utilisateur: req.userId }).populate("utilisateur");
    if (!seance) {
      return res.status(404).json({ message: "❌ Séance introuvable" });
    }
    return res.status(200).json(seance);
  } catch (error) {
    console.error("❌ Erreur lors de la récupération de la séance :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const updateSeance = async (req, res) => {
  try {
    const { date, exercices } = req.body;

    const seance = await Seance.findOne({ _id: req.params.id, utilisateur: req.userId });
    if (!seance) {
      return res.status(404).json({ message: "❌ Séance introuvable" });
    }

    if (seance.statut === "validee") {
      return res.status(403).json({ message: "❌ Impossible de modifier une séance déjà validée" });
    }

    if (date !== undefined) seance.date = date;
    if (exercices !== undefined) seance.exercices = exercices;

    await seance.save();
    await seance.populate("utilisateur");

    console.log(`✅ Séance mise à jour : ${seance._id}`);
    return res.status(200).json({ message: "✅ Séance mise à jour", seance });
  } catch (error) {
    console.error("❌ Erreur lors de la mise à jour de la séance :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const deleteSeance = async (req, res) => {
  try {
    const seance = await Seance.findOneAndDelete({ _id: req.params.id, utilisateur: req.userId });
    if (!seance) {
      return res.status(404).json({ message: "❌ Séance introuvable" });
    }

    console.log(`✅ Séance supprimée : ${req.params.id}`);
    return res.status(200).json({ message: "✅ Séance supprimée" });
  } catch (error) {
    console.error("❌ Erreur lors de la suppression de la séance :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const validerSeance = async (req, res) => {
  try {
    const seance = await Seance.findOne({ _id: req.params.id, utilisateur: req.userId });
    if (!seance) {
      return res.status(404).json({ message: "❌ Séance introuvable" });
    }

    if (seance.statut === "validee") {
      return res.status(409).json({ message: "❌ Cette séance est déjà validée" });
    }

    seance.statut = "validee";
    seance.valideeLe = new Date();
    await seance.save();
    await seance.populate("utilisateur");

    console.log(`✅ Séance validée : ${seance._id}`);

    const user = await User.findById(req.userId);
    const succesObtenus = await checkGoals(user);

    return res.status(200).json({ message: "✅ Séance validée", seance, succesObtenus });
  } catch (error) {
    console.error("❌ Erreur lors de la validation de la séance :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};
