import jwt from "jsonwebtoken";
import User from "../models/User.js";

const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });
};

export const register = async (req, res) => {
  try {
    const { email, motDePasse } = req.body;

    if (!email || !motDePasse) {
      return res.status(400).json({ message: "❌ Email et mot de passe sont obligatoires" });
    }

    const userExistant = await User.findOne({ email: email.toLowerCase() });
    if (userExistant) {
      return res.status(409).json({ message: "❌ Un compte existe déjà avec cet email" });
    }

    const user = await User.create({ email, motDePasse });
    const token = generateToken(user._id);

    console.log(`✅ Nouvel utilisateur inscrit : ${user.email}`);
    return res.status(201).json({ message: "✅ Inscription réussie", token, user });
  } catch (error) {
    console.error("❌ Erreur lors de l'inscription :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur lors de l'inscription", error: error.message });
  }
};

export const login = async (req, res) => {
  try {
    const { email, motDePasse } = req.body;

    if (!email || !motDePasse) {
      return res.status(400).json({ message: "❌ Email et mot de passe sont obligatoires" });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({ message: "❌ Email ou mot de passe incorrect" });
    }

    const motDePasseValide = await user.comparePassword(motDePasse);
    if (!motDePasseValide) {
      return res.status(401).json({ message: "❌ Email ou mot de passe incorrect" });
    }

    const token = generateToken(user._id);

    console.log(`✅ Connexion réussie : ${user.email}`);
    return res.status(200).json({ message: "✅ Connexion réussie", token, user });
  } catch (error) {
    console.error("❌ Erreur lors de la connexion :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur lors de la connexion", error: error.message });
  }
};

export const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({ message: "❌ Utilisateur introuvable" });
    }
    return res.status(200).json(user);
  } catch (error) {
    console.error("❌ Erreur lors de la récupération du profil :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};

export const updateProfile = async (req, res) => {
  try {
    const { nom, prenom, poids, taille } = req.body;

    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({ message: "❌ Utilisateur introuvable" });
    }

    const nouveauPoidsFourni = poids !== undefined && poids !== null;
    const poidsAModifie = nouveauPoidsFourni && poids !== user.poids;

    if (nom !== undefined) user.nom = nom;
    if (prenom !== undefined) user.prenom = prenom;
    if (nouveauPoidsFourni) {
      user.poids = poids;
      if (!user.historiquePoids) {
        user.historiquePoids = [];
      }
      user.historiquePoids.push({ poids, date: new Date() });
    }
    if (taille !== undefined) user.taille = taille;

    await user.save();

    console.log(`✅ Profil mis à jour : ${user.email}`);

    if (poidsAModifie) {
      const { checkGoals } = await import("../utils/goalsChecker.js");
      await checkGoals(user);
    }

    return res.status(200).json({ message: "✅ Profil mis à jour", user });
  } catch (error) {
    console.error("❌ Erreur lors de la mise à jour du profil :", error.message);
    return res.status(500).json({ message: "❌ Erreur serveur", error: error.message });
  }
};
