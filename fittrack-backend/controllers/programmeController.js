import Programme from "../models/Programme.js";

export const createProgramme = async (req, res) => {
  try {
    const { nom, jours, actif } = req.body;

    if (!nom) {
      return res.status(400).json({ message: "❌ Le nom du programme est obligatoire" });
    }

    const programme = new Programme({
      utilisateur: req.userId,
      nom,
      jours: jours || [],
      actif: actif || false,
    });

    await programme.save();
    await programme.populate("utilisateur");

    console.log(`✅ Programme créé : ${programme.nom}`);
    return res.status(201).json({ message: "✅ Programme créé", programme });
  } catch (error) {
    console.error("❌ Erreur lors de la création du programme :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const getProgrammes = async (req, res) => {
  try {
    const programmes = await Programme.find({ utilisateur: req.userId }).populate("utilisateur");
    return res.status(200).json(programmes);
  } catch (error) {
    console.error("❌ Erreur lors de la récupération des programmes :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const getProgrammeActif = async (req, res) => {
  try {
    const programme = await Programme.findOne({ utilisateur: req.userId, actif: true }).populate("utilisateur");
    return res.status(200).json(programme || {});
  } catch (error) {
    console.error("❌ Erreur lors de la récupération du programme actif :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const getProgrammeById = async (req, res) => {
  try {
    const programme = await Programme.findOne({ _id: req.params.id, utilisateur: req.userId }).populate("utilisateur");
    if (!programme) {
      return res.status(404).json({ message: "❌ Programme introuvable" });
    }
    return res.status(200).json(programme);
  } catch (error) {
    console.error("❌ Erreur lors de la récupération du programme :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const updateProgramme = async (req, res) => {
  try {
    const { nom, jours, actif } = req.body;

    const programme = await Programme.findOne({ _id: req.params.id, utilisateur: req.userId });
    if (!programme) {
      return res.status(404).json({ message: "❌ Programme introuvable" });
    }

    if (nom !== undefined) programme.nom = nom;
    if (jours !== undefined) programme.jours = jours;
    if (actif !== undefined) programme.actif = actif;

    await programme.save();
    await programme.populate("utilisateur");

    console.log(`✅ Programme mis à jour : ${programme._id}`);
    return res.status(200).json({ message: "✅ Programme mis à jour", programme });
  } catch (error) {
    console.error("❌ Erreur lors de la mise à jour du programme :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const deleteProgramme = async (req, res) => {
  try {
    const programme = await Programme.findOneAndDelete({ _id: req.params.id, utilisateur: req.userId });
    if (!programme) {
      return res.status(404).json({ message: "❌ Programme introuvable" });
    }

    console.log(`✅ Programme supprimé : ${req.params.id}`);
    return res.status(200).json({ message: "✅ Programme supprimé" });
  } catch (error) {
    console.error("❌ Erreur lors de la suppression du programme :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};
