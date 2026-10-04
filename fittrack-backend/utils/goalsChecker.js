import Objectif from "../models/Objectif.js";
import Succes from "../models/Succes.js";
import Seance from "../models/Seance.js";

const PERIODE_REGULARITE_JOURS = 7;

const checkPoidsCible = async (objectif, user) => {
  if (user.poids === null || user.poids === undefined) return false;
  if (objectif.valeurCible === null || objectif.valeurCible === undefined) return false;
  return user.poids <= objectif.valeurCible;
};

const checkPerteDePoids = async (objectif, user) => {
  if (user.poids === null || user.poids === undefined) return false;
  if (objectif.valeurCible === null || objectif.valeurCible === undefined) return false;
  return user.poids <= objectif.valeurCible;
};

const checkPriseDeMuscle = async (objectif, user) => {
  if (user.poids === null || user.poids === undefined) return false;
  if (objectif.valeurCible === null || objectif.valeurCible === undefined) return false;
  return user.poids >= objectif.valeurCible;
};

const checkRegulariteSeances = async (objectif, user) => {
  if (objectif.valeurCible === null || objectif.valeurCible === undefined) return false;

  const dateDebut = new Date();
  dateDebut.setDate(dateDebut.getDate() - PERIODE_REGULARITE_JOURS);

  const nombreSeances = await Seance.countDocuments({
    utilisateur: user._id,
    statut: "validee",
    valideeLe: { $gte: dateDebut },
  });

  return nombreSeances >= objectif.valeurCible;
};

const getMaxChargeUtilisateur = async (userId) => {
  const seancesValidees = await Seance.find({ utilisateur: userId, statut: "validee" });
  let maxCharge = 0;
  for (const seance of seancesValidees) {
    for (const ex of seance.exercices || []) {
      for (const serie of ex.series || []) {
        if (serie.charge && serie.charge > maxCharge) {
          maxCharge = serie.charge;
        }
      }
    }
  }
  return maxCharge;
};

const checkChargeMaximale = async (objectif, user) => {
  if (objectif.valeurCible === null || objectif.valeurCible === undefined) return false;
  const maxCharge = await getMaxChargeUtilisateur(user._id);
  return maxCharge >= objectif.valeurCible;
};

export const checkGoals = async (user) => {
  try {
    const objectifsEnCours = await Objectif.find({
      utilisateur: user._id,
      statut: "en_cours",
    });

    const succesCrees = [];

    for (const objectif of objectifsEnCours) {
      let atteint = false;

      if (objectif.type === "poids_cible") {
        atteint = await checkPoidsCible(objectif, user);
      } else if (objectif.type === "perte_de_poids") {
        atteint = await checkPerteDePoids(objectif, user);
      } else if (objectif.type === "prise_de_muscle") {
        atteint = await checkPriseDeMuscle(objectif, user);
      } else if (objectif.type === "regularite_seances") {
        atteint = await checkRegulariteSeances(objectif, user);
      } else if (objectif.type === "charge_maximale") {
        atteint = await checkChargeMaximale(objectif, user);
      }

      if (atteint) {
        objectif.statut = "atteint";
        await objectif.save();

        let description = "Objectif atteint";
        if (objectif.type === "poids_cible" || objectif.type === "perte_de_poids") {
          description = `Objectif poids atteint : ${user.poids}kg`;
        } else if (objectif.type === "prise_de_muscle") {
          description = `Objectif prise de masse atteint : ${user.poids}kg`;
        } else if (objectif.type === "regularite_seances") {
          description = `Objectif de régularité atteint : ${objectif.valeurCible} séances/semaine`;
        } else if (objectif.type === "charge_maximale") {
          const maxCharge = await getMaxChargeUtilisateur(user._id);
          description = `Nouvel objectif de charge atteint : ${maxCharge}kg !`;
        }

        const succes = await Succes.create({
          utilisateur: user._id,
          objectif: objectif._id,
          description,
        });

        succesCrees.push(succes);
        console.log(`✅ Nouveau succès débloqué pour l'utilisateur ${user._id} : ${description}`);
      }
    }

    return succesCrees;
  } catch (error) {
    console.error("❌ Erreur lors de la vérification des objectifs :", error.message);
    return [];
  }
};

export default checkGoals;
